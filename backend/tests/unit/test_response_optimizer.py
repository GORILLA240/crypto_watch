"""
Unit tests for response optimization utilities.

Tests response formatting, compression, and payload reduction.
"""

import unittest
import json
import gzip
import base64
from datetime import datetime

from src.shared.response_optimizer import (
    should_compress_response,
    compress_response,
    format_optimized_response
)
from src.shared.models import CryptoPrice


class TestCompressionDetection(unittest.TestCase):
    """Test Accept-Encoding header detection."""
    
    def test_should_compress_with_gzip_header(self):
        """Test that gzip compression is detected from Accept-Encoding header."""
        headers = {'Accept-Encoding': 'gzip, deflate'}
        self.assertTrue(should_compress_response(headers))
    
    def test_should_compress_with_gzip_only(self):
        """Test that gzip-only Accept-Encoding is detected."""
        headers = {'Accept-Encoding': 'gzip'}
        self.assertTrue(should_compress_response(headers))
    
    def test_should_compress_case_insensitive(self):
        """Test that header detection is case-insensitive."""
        headers = {'accept-encoding': 'gzip'}
        self.assertTrue(should_compress_response(headers))
        
        headers = {'ACCEPT-ENCODING': 'GZIP'}
        self.assertTrue(should_compress_response(headers))
    
    def test_should_not_compress_without_gzip(self):
        """Test that compression is not used without gzip in Accept-Encoding."""
        headers = {'Accept-Encoding': 'deflate'}
        self.assertFalse(should_compress_response(headers))
    
    def test_should_not_compress_without_header(self):
        """Test that compression is not used without Accept-Encoding header."""
        headers = {'Content-Type': 'application/json'}
        self.assertFalse(should_compress_response(headers))
    
    def test_should_not_compress_with_empty_headers(self):
        """Test that compression is not used with empty headers."""
        self.assertFalse(should_compress_response({}))
    
    def test_should_not_compress_with_none_headers(self):
        """Test that compression is not used with None headers."""
        self.assertFalse(should_compress_response(None))


class TestCompression(unittest.TestCase):
    """Test gzip compression functionality."""
    
    def test_compress_response_basic(self):
        """Test that response is compressed correctly."""
        body = '{"data": "test"}'
        compressed = compress_response(body)
        
        # Verify it's bytes
        self.assertIsInstance(compressed, bytes)
        
        # Verify it can be decompressed
        decompressed = gzip.decompress(compressed).decode('utf-8')
        self.assertEqual(decompressed, body)
    
    def test_compress_response_reduces_size(self):
        """Test that compression reduces payload size for large data."""
        # Create a large JSON payload with repetitive data
        large_body = json.dumps({
            'data': [
                {
                    'symbol': 'BTC',
                    'name': 'Bitcoin',
                    'price': 45000.50,
                    'change24h': 2.5,
                    'marketCap': 850000000000,
                    'lastUpdated': '2024-01-15T10:30:00Z'
                }
            ] * 100  # Repeat 100 times
        })
        
        compressed = compress_response(large_body)
        
        # Compressed size should be significantly smaller
        self.assertLess(len(compressed), len(large_body.encode('utf-8')))


class TestResponseFormatting(unittest.TestCase):
    """Test response formatting and optimization."""
    
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
    
    def test_format_response_without_compression(self):
        """Test response formatting without compression."""
        timestamp_iso = '2024-01-15T10:30:00Z'
        headers = {}  # No Accept-Encoding header
        
        response = format_optimized_response(self.price_data, timestamp_iso, headers)
        
        # Verify response structure
        self.assertEqual(response['statusCode'], 200)
        self.assertIn('Content-Type', response['headers'])
        self.assertEqual(response['headers']['Content-Type'], 'application/json')
        self.assertNotIn('Content-Encoding', response['headers'])
        self.assertNotIn('isBase64Encoded', response)
        
        # Verify body is JSON string
        self.assertIsInstance(response['body'], str)
        body_data = json.loads(response['body'])
        
        # Verify data structure
        self.assertIn('data', body_data)
        self.assertIn('timestamp', body_data)
        self.assertEqual(len(body_data['data']), 2)
        
        # Verify first crypto data
        btc_data = body_data['data'][0]
        self.assertEqual(btc_data['symbol'], 'BTC')
        self.assertEqual(btc_data['name'], 'Bitcoin')
        self.assertEqual(btc_data['price'], 45000.50)
        self.assertEqual(btc_data['change24h'], 2.5)
        self.assertEqual(btc_data['marketCap'], 850000000000)
    
    def test_format_response_with_compression(self):
        """Test response formatting with gzip compression."""
        timestamp_iso = '2024-01-15T10:30:00Z'
        headers = {'Accept-Encoding': 'gzip'}
        
        response = format_optimized_response(self.price_data, timestamp_iso, headers)
        
        # Verify response structure
        self.assertEqual(response['statusCode'], 200)
        self.assertIn('Content-Type', response['headers'])
        self.assertEqual(response['headers']['Content-Type'], 'application/json')
        self.assertIn('Content-Encoding', response['headers'])
        self.assertEqual(response['headers']['Content-Encoding'], 'gzip')
        self.assertTrue(response.get('isBase64Encoded', False))
        
        # Verify body is base64-encoded string
        self.assertIsInstance(response['body'], str)
        
        # Decode and decompress
        compressed_bytes = base64.b64decode(response['body'])
        decompressed = gzip.decompress(compressed_bytes).decode('utf-8')
        body_data = json.loads(decompressed)
        
        # Verify data structure
        self.assertIn('data', body_data)
        self.assertIn('timestamp', body_data)
        self.assertEqual(len(body_data['data']), 2)
    
    def test_numeric_precision_limits(self):
        """Test that numeric precision is limited correctly."""
        # Create price data with high precision
        price_data = [
            CryptoPrice(
                symbol='BTC',
                name='Bitcoin',
                price=45000.123456789,  # Many decimal places
                change24h=2.56789,  # Many decimal places
                market_cap=850000000000,
                last_updated=self.timestamp
            )
        ]
        
        timestamp_iso = '2024-01-15T10:30:00Z'
        headers = {}
        
        response = format_optimized_response(price_data, timestamp_iso, headers)
        body_data = json.loads(response['body'])
        
        # Verify precision limits
        btc_data = body_data['data'][0]
        self.assertEqual(btc_data['price'], 45000.12)  # 2 decimal places
        self.assertEqual(btc_data['change24h'], 2.6)  # 1 decimal place
    
    def test_response_contains_only_essential_fields(self):
        """Test that response contains only the 6 essential fields."""
        timestamp_iso = '2024-01-15T10:30:00Z'
        headers = {}
        
        response = format_optimized_response(self.price_data, timestamp_iso, headers)
        body_data = json.loads(response['body'])
        
        # Verify each crypto data has exactly 6 fields
        for crypto in body_data['data']:
            self.assertEqual(len(crypto), 6)
            self.assertIn('symbol', crypto)
            self.assertIn('name', crypto)
            self.assertIn('price', crypto)
            self.assertIn('change24h', crypto)
            self.assertIn('marketCap', crypto)
            self.assertIn('lastUpdated', crypto)
    
    def test_json_keys_are_readable(self):
        """Test that JSON keys are human-readable (not shortened)."""
        timestamp_iso = '2024-01-15T10:30:00Z'
        headers = {}
        
        response = format_optimized_response(self.price_data, timestamp_iso, headers)
        body_data = json.loads(response['body'])
        
        # Verify readable key names (not shortened like 's', 'p', 'c')
        crypto = body_data['data'][0]
        self.assertIn('symbol', crypto)  # Not 's'
        self.assertIn('price', crypto)  # Not 'p'
        self.assertIn('change24h', crypto)  # Not 'c'
        self.assertIn('marketCap', crypto)  # Not 'm'


class TestCompressionEfficiency(unittest.TestCase):
    """Test compression efficiency for different payload sizes."""
    
    def test_compression_benefit_for_multiple_cryptos(self):
        """Test that compression provides benefit for multiple cryptocurrencies."""
        timestamp = datetime(2024, 1, 15, 10, 30, 0)
        
        # Create data for 20 cryptocurrencies
        price_data = []
        for i in range(20):
            price_data.append(
                CryptoPrice(
                    symbol=f'CRYPTO{i}',
                    name=f'Cryptocurrency {i}',
                    price=1000.0 + i,
                    change24h=float(i % 10),
                    market_cap=1000000000 * (i + 1),
                    last_updated=timestamp
                )
            )
        
        timestamp_iso = '2024-01-15T10:30:00Z'
        
        # Get uncompressed response
        response_uncompressed = format_optimized_response(price_data, timestamp_iso, {})
        uncompressed_size = len(response_uncompressed['body'].encode('utf-8'))
        
        # Get compressed response
        headers = {'Accept-Encoding': 'gzip'}
        response_compressed = format_optimized_response(price_data, timestamp_iso, headers)
        compressed_size = len(base64.b64decode(response_compressed['body']))
        
        # Compressed should be smaller
        self.assertLess(compressed_size, uncompressed_size)
        
        # Calculate compression ratio
        compression_ratio = compressed_size / uncompressed_size
        print(f"\nCompression ratio: {compression_ratio:.2%}")
        print(f"Uncompressed: {uncompressed_size} bytes")
        print(f"Compressed: {compressed_size} bytes")
        print(f"Savings: {uncompressed_size - compressed_size} bytes")


if __name__ == '__main__':
    unittest.main()
