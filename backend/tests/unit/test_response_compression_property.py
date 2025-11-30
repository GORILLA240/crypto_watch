"""
Property-based tests for response compression.

Tests universal properties that should hold for response compression across all valid inputs.
"""

import pytest
from hypothesis import given, strategies as st, settings, assume
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


# Strategy for generating Accept-Encoding headers with gzip support
def accept_encoding_with_gzip_strategy():
    """Generate Accept-Encoding headers that include gzip."""
    gzip_variants = st.sampled_from([
        'gzip',
        'gzip, deflate',
        'gzip, deflate, br',
        'deflate, gzip',
        'GZIP',
        'GZip',
        'gzip;q=1.0',
        'gzip;q=0.8, deflate;q=0.5'
    ])
    
    header_key_variants = st.sampled_from([
        'Accept-Encoding',
        'accept-encoding',
        'ACCEPT-ENCODING',
        'Accept-encoding'
    ])
    
    return st.builds(
        lambda key, value: {key: value},
        header_key_variants,
        gzip_variants
    )


# Strategy for generating Accept-Encoding headers without gzip support
def accept_encoding_without_gzip_strategy():
    """Generate Accept-Encoding headers that do not include gzip."""
    non_gzip_values = st.sampled_from([
        'deflate',
        'br',
        'identity',
        'deflate, br',
        'compress',
        ''
    ])
    
    header_key_variants = st.sampled_from([
        'Accept-Encoding',
        'accept-encoding',
        'ACCEPT-ENCODING'
    ])
    
    return st.builds(
        lambda key, value: {key: value},
        header_key_variants,
        non_gzip_values
    )


# Strategy for generating CryptoPrice objects
def crypto_price_strategy():
    """Generate valid CryptoPrice objects."""
    return st.builds(
        CryptoPrice,
        symbol=st.text(
            alphabet=st.characters(whitelist_categories=('Lu',)),
            min_size=2,
            max_size=10
        ),
        name=st.text(min_size=3, max_size=50),
        price=st.floats(min_value=0.01, max_value=1000000.0, allow_nan=False, allow_infinity=False),
        change24h=st.floats(min_value=-100.0, max_value=1000.0, allow_nan=False, allow_infinity=False),
        market_cap=st.integers(min_value=0, max_value=int(1e15)),
        last_updated=st.just(datetime(2024, 1, 15, 10, 30, 0))
    )


# Strategy for generating lists of CryptoPrice objects
crypto_price_list_strategy = st.lists(
    crypto_price_strategy(),
    min_size=1,
    max_size=20
)


@pytest.mark.property
class TestResponseCompressionProperties:
    """Property-based tests for response compression."""
    
    @settings(max_examples=100)
    @given(
        price_data_list=crypto_price_list_strategy,
        headers=accept_encoding_with_gzip_strategy()
    )
    def test_property_5_response_compression(self, price_data_list, headers):
        """
        Feature: crypto-watch-backend, Property 5: Response compression
        
        Property: For any API request that includes an Accept-Encoding header
        indicating gzip support, the response should be properly compressed.
        
        Validates: Requirements 2.5
        """
        timestamp_iso = '2024-01-15T10:30:00Z'
        
        # Generate response with compression-supporting headers
        response = format_optimized_response(price_data_list, timestamp_iso, headers)
        
        # Property 1: Response should indicate compression
        assert 'Content-Encoding' in response['headers'], \
            "Response must include Content-Encoding header when client supports gzip"
        assert response['headers']['Content-Encoding'] == 'gzip', \
            "Content-Encoding header must be 'gzip'"
        
        # Property 2: Response should be marked as base64-encoded
        assert response.get('isBase64Encoded', False) is True, \
            "Response must be marked as base64-encoded when compressed"
        
        # Property 3: Body should be a valid base64-encoded string
        assert isinstance(response['body'], str), \
            "Compressed response body must be a string"
        
        try:
            compressed_bytes = base64.b64decode(response['body'])
        except Exception as e:
            pytest.fail(f"Response body must be valid base64: {e}")
        
        # Property 4: Compressed data should be valid gzip
        try:
            decompressed = gzip.decompress(compressed_bytes).decode('utf-8')
        except Exception as e:
            pytest.fail(f"Response body must be valid gzip-compressed data: {e}")
        
        # Property 5: Decompressed data should be valid JSON
        try:
            decompressed_data = json.loads(decompressed)
        except Exception as e:
            pytest.fail(f"Decompressed response must be valid JSON: {e}")
        
        # Property 6: Decompressed data should contain all required fields
        assert 'data' in decompressed_data, \
            "Decompressed response must include 'data' field"
        assert 'timestamp' in decompressed_data, \
            "Decompressed response must include 'timestamp' field"
        
        # Property 7: Data integrity - all crypto prices should be present
        assert len(decompressed_data['data']) == len(price_data_list), \
            "Decompressed response must contain all cryptocurrency data"
        
        # Property 8: Each crypto data should have all required fields
        for crypto_data in decompressed_data['data']:
            assert 'symbol' in crypto_data, "Each crypto must have 'symbol'"
            assert 'name' in crypto_data, "Each crypto must have 'name'"
            assert 'price' in crypto_data, "Each crypto must have 'price'"
            assert 'change24h' in crypto_data, "Each crypto must have 'change24h'"
            assert 'marketCap' in crypto_data, "Each crypto must have 'marketCap'"
            assert 'lastUpdated' in crypto_data, "Each crypto must have 'lastUpdated'"
    
    @settings(max_examples=100)
    @given(
        price_data_list=crypto_price_list_strategy,
        headers=accept_encoding_without_gzip_strategy()
    )
    def test_no_compression_without_gzip_support(self, price_data_list, headers):
        """
        Property: For any API request that does not include gzip in Accept-Encoding,
        the response should NOT be compressed.
        
        This is the inverse property - ensuring compression only happens when requested.
        """
        timestamp_iso = '2024-01-15T10:30:00Z'
        
        # Generate response without compression support
        response = format_optimized_response(price_data_list, timestamp_iso, headers)
        
        # Property 1: Response should NOT have Content-Encoding header
        assert 'Content-Encoding' not in response['headers'], \
            "Response must not include Content-Encoding header when client doesn't support gzip"
        
        # Property 2: Response should NOT be marked as base64-encoded
        assert response.get('isBase64Encoded', False) is False, \
            "Response must not be marked as base64-encoded when not compressed"
        
        # Property 3: Body should be a plain JSON string
        assert isinstance(response['body'], str), \
            "Uncompressed response body must be a string"
        
        # Property 4: Body should be valid JSON (not compressed)
        try:
            body_data = json.loads(response['body'])
        except Exception as e:
            pytest.fail(f"Uncompressed response body must be valid JSON: {e}")
        
        # Property 5: Data should contain all required fields
        assert 'data' in body_data, "Response must include 'data' field"
        assert 'timestamp' in body_data, "Response must include 'timestamp' field"
        assert len(body_data['data']) == len(price_data_list), \
            "Response must contain all cryptocurrency data"
    
    @settings(max_examples=100)
    @given(
        price_data_list=crypto_price_list_strategy
    )
    def test_no_compression_with_empty_headers(self, price_data_list):
        """
        Property: For any API request with empty or None headers,
        the response should NOT be compressed.
        """
        timestamp_iso = '2024-01-15T10:30:00Z'
        
        # Test with empty headers
        response_empty = format_optimized_response(price_data_list, timestamp_iso, {})
        assert 'Content-Encoding' not in response_empty['headers'], \
            "Response must not be compressed with empty headers"
        
        # Test with None headers
        response_none = format_optimized_response(price_data_list, timestamp_iso, None)
        assert 'Content-Encoding' not in response_none['headers'], \
            "Response must not be compressed with None headers"
    
    @settings(max_examples=100)
    @given(
        price_data_list=crypto_price_list_strategy,
        headers=accept_encoding_with_gzip_strategy()
    )
    def test_compression_preserves_data_integrity(self, price_data_list, headers):
        """
        Property: Compression should preserve complete data integrity.
        The decompressed response should be identical to an uncompressed response.
        """
        timestamp_iso = '2024-01-15T10:30:00Z'
        
        # Generate compressed response
        compressed_response = format_optimized_response(price_data_list, timestamp_iso, headers)
        
        # Generate uncompressed response
        uncompressed_response = format_optimized_response(price_data_list, timestamp_iso, {})
        
        # Decompress the compressed response
        compressed_bytes = base64.b64decode(compressed_response['body'])
        decompressed = gzip.decompress(compressed_bytes).decode('utf-8')
        
        # Parse both responses
        compressed_data = json.loads(decompressed)
        uncompressed_data = json.loads(uncompressed_response['body'])
        
        # Property: Data should be identical
        assert compressed_data == uncompressed_data, \
            "Compressed and uncompressed responses must contain identical data"
    
    @settings(max_examples=100)
    @given(
        price_data_list=crypto_price_list_strategy,
        headers=accept_encoding_with_gzip_strategy()
    )
    def test_compression_reduces_size(self, price_data_list, headers):
        """
        Property: For sufficiently large responses, compression should reduce
        the payload size.
        
        Note: Very small payloads might not compress well due to gzip overhead,
        so we only test this property when we have enough data.
        """
        # Only test when we have enough data for compression to be effective
        assume(len(price_data_list) >= 5)
        
        timestamp_iso = '2024-01-15T10:30:00Z'
        
        # Generate compressed response
        compressed_response = format_optimized_response(price_data_list, timestamp_iso, headers)
        
        # Generate uncompressed response
        uncompressed_response = format_optimized_response(price_data_list, timestamp_iso, {})
        
        # Calculate sizes
        compressed_size = len(base64.b64decode(compressed_response['body']))
        uncompressed_size = len(uncompressed_response['body'].encode('utf-8'))
        
        # Property: Compressed should be smaller (or at least not significantly larger)
        # For JSON data with repetitive structure, compression should help
        # We allow up to 10% overhead for very small payloads
        assert compressed_size <= uncompressed_size * 1.1, \
            f"Compressed size ({compressed_size}) should not be significantly larger than uncompressed ({uncompressed_size})"
    
    @settings(max_examples=100)
    @given(headers=accept_encoding_with_gzip_strategy())
    def test_should_compress_response_detects_gzip(self, headers):
        """
        Property: should_compress_response should correctly detect gzip support
        in Accept-Encoding headers regardless of case or additional encodings.
        """
        result = should_compress_response(headers)
        
        # Property: Should return True for any header containing 'gzip'
        assert result is True, \
            f"should_compress_response must return True for headers with gzip: {headers}"
    
    @settings(max_examples=100)
    @given(headers=accept_encoding_without_gzip_strategy())
    def test_should_compress_response_rejects_non_gzip(self, headers):
        """
        Property: should_compress_response should correctly reject headers
        that do not include gzip support.
        """
        result = should_compress_response(headers)
        
        # Property: Should return False for headers without 'gzip'
        assert result is False, \
            f"should_compress_response must return False for headers without gzip: {headers}"
    
    @settings(max_examples=100)
    @given(
        body=st.text(min_size=10, max_size=10000)
    )
    def test_compress_response_round_trip(self, body):
        """
        Property: Compressing and then decompressing should return the original data.
        This is a round-trip property.
        """
        # Compress the body
        compressed = compress_response(body)
        
        # Property 1: Result should be bytes
        assert isinstance(compressed, bytes), \
            "compress_response must return bytes"
        
        # Property 2: Should be decompressible
        try:
            decompressed = gzip.decompress(compressed).decode('utf-8')
        except Exception as e:
            pytest.fail(f"Compressed data must be valid gzip: {e}")
        
        # Property 3: Round-trip should preserve data
        assert decompressed == body, \
            "Decompressing compressed data must return original data"
