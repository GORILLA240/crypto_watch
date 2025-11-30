"""
Integration tests for API response optimization.

Tests the complete flow from API handler to optimized response.
"""

import unittest
import json
import gzip
import base64
from unittest.mock import Mock, patch
from datetime import datetime

from src.shared.models import CryptoPrice
from src.shared.response_optimizer import format_optimized_response


class TestAPIResponseOptimization(unittest.TestCase):
    """Test API response optimization in realistic scenarios."""
    
    def setUp(self):
        """Set up test data."""
        self.timestamp = datetime(2024, 1, 15, 10, 30, 0)
        self.price_data = [
            CryptoPrice(
                symbol='BTC',
                name='Bitcoin',
                price=45000.50,
                change24h=2.5,
                market_cap=850000000000,
                last_updated=self.timestamp
            ),
            CryptoPrice(
                symbol='ETH',
                name='Ethereum',
                price=3000.25,
                change24h=-1.2,
                market_cap=360000000000,
                last_updated=self.timestamp
            )
        ]
    
    def test_api_response_without_compression(self):
        """Test API response format without compression (Requirements 2.3)."""
        timestamp_iso = '2024-01-15T10:30:00Z'
        headers = {}
        
        response = format_optimized_response(self.price_data, timestamp_iso, headers)
        
        # Verify response structure
        self.assertEqual(response['statusCode'], 200)
        self.assertEqual(response['headers']['Content-Type'], 'application/json')
        
        # Parse response body
        body_data = json.loads(response['body'])
        
        # Verify only essential fields are present (Requirements 2.3)
        for crypto in body_data['data']:
            # Should have exactly 6 fields
            self.assertEqual(len(crypto), 6)
            
            # Verify field names are readable (not shortened)
            self.assertIn('symbol', crypto)
            self.assertIn('name', crypto)
            self.assertIn('price', crypto)
            self.assertIn('change24h', crypto)
            self.assertIn('marketCap', crypto)
            self.assertIn('lastUpdated', crypto)
        
        # Verify numeric precision (Requirements 2.3)
        btc = body_data['data'][0]
        # Price should have 2 decimal places
        self.assertEqual(btc['price'], 45000.50)
        # Change24h should have 1 decimal place
        self.assertEqual(btc['change24h'], 2.5)
    
    def test_api_response_with_compression(self):
        """Test API response with gzip compression (Requirements 2.5)."""
        timestamp_iso = '2024-01-15T10:30:00Z'
        headers = {'Accept-Encoding': 'gzip, deflate'}
        
        response = format_optimized_response(self.price_data, timestamp_iso, headers)
        
        # Verify compression headers (Requirements 2.5)
        self.assertEqual(response['statusCode'], 200)
        self.assertEqual(response['headers']['Content-Encoding'], 'gzip')
        self.assertTrue(response['isBase64Encoded'])
        
        # Verify body is compressed and base64-encoded
        compressed_bytes = base64.b64decode(response['body'])
        decompressed = gzip.decompress(compressed_bytes).decode('utf-8')
        body_data = json.loads(decompressed)
        
        # Verify data integrity after decompression
        self.assertEqual(len(body_data['data']), 2)
        self.assertEqual(body_data['data'][0]['symbol'], 'BTC')
    
    def test_numeric_precision_edge_cases(self):
        """Test numeric precision with edge cases."""
        # Create price data with various precision scenarios
        price_data = [
            CryptoPrice(
                symbol='TEST1',
                name='Test 1',
                price=0.123456789,  # Small number with many decimals
                change24h=99.999,  # Large change with many decimals
                market_cap=1,
                last_updated=self.timestamp
            ),
            CryptoPrice(
                symbol='TEST2',
                name='Test 2',
                price=123456.789,  # Large number with decimals
                change24h=-0.001,  # Very small negative change
                market_cap=999999999999,
                last_updated=self.timestamp
            )
        ]
        
        timestamp_iso = '2024-01-15T10:30:00Z'
        response = format_optimized_response(price_data, timestamp_iso, {})
        body_data = json.loads(response['body'])
        
        # Verify precision limits
        test1 = body_data['data'][0]
        self.assertEqual(test1['price'], 0.12)  # 2 decimal places
        self.assertEqual(test1['change24h'], 100.0)  # 1 decimal place
        
        test2 = body_data['data'][1]
        self.assertEqual(test2['price'], 123456.79)  # 2 decimal places
        self.assertEqual(test2['change24h'], 0.0)  # 1 decimal place
    
    def test_compression_with_case_insensitive_header(self):
        """Test that Accept-Encoding header is case-insensitive."""
        timestamp_iso = '2024-01-15T10:30:00Z'
        
        # Test with lowercase
        headers_lower = {'accept-encoding': 'gzip'}
        response_lower = format_optimized_response(self.price_data, timestamp_iso, headers_lower)
        self.assertEqual(response_lower['headers']['Content-Encoding'], 'gzip')
        
        # Test with uppercase
        headers_upper = {'ACCEPT-ENCODING': 'GZIP'}
        response_upper = format_optimized_response(self.price_data, timestamp_iso, headers_upper)
        self.assertEqual(response_upper['headers']['Content-Encoding'], 'gzip')
        
        # Test with mixed case
        headers_mixed = {'Accept-Encoding': 'GZip'}
        response_mixed = format_optimized_response(self.price_data, timestamp_iso, headers_mixed)
        self.assertEqual(response_mixed['headers']['Content-Encoding'], 'gzip')
    
    def test_payload_size_comparison(self):
        """Test that optimized response is smaller than verbose format."""
        # Create multiple cryptocurrencies
        price_data = []
        for i in range(10):
            price_data.append(
                CryptoPrice(
                    symbol=f'CRYPTO{i}',
                    name=f'Cryptocurrency {i}',
                    price=1000.0 + i,
                    change24h=float(i % 10),
                    market_cap=1000000000 * (i + 1),
                    last_updated=self.timestamp
                )
            )
        
        timestamp_iso = '2024-01-15T10:30:00Z'
        
        # Get optimized response (uncompressed)
        response = format_optimized_response(price_data, timestamp_iso, {})
        optimized_size = len(response['body'].encode('utf-8'))
        
        # Create a verbose response with extra fields (simulating non-optimized)
        verbose_data = {
            'data': [
                {
                    **price.to_dict(),
                    'extraField1': 'unnecessary data',
                    'extraField2': 'more unnecessary data',
                    'extraField3': 'even more unnecessary data'
                }
                for price in price_data
            ],
            'timestamp': timestamp_iso,
            'metadata': {
                'version': '1.0',
                'source': 'external-api',
                'cached': False
            }
        }
        verbose_size = len(json.dumps(verbose_data).encode('utf-8'))
        
        # Optimized should be smaller
        self.assertLess(optimized_size, verbose_size)
        
        # Calculate savings
        savings_percent = ((verbose_size - optimized_size) / verbose_size) * 100
        print(f"\nPayload optimization savings: {savings_percent:.1f}%")
        print(f"Verbose: {verbose_size} bytes")
        print(f"Optimized: {optimized_size} bytes")


if __name__ == '__main__':
    unittest.main()
