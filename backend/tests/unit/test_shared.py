"""
Unit tests for shared utilities.
"""

import pytest
from datetime import datetime
import time
from src.shared.models import CryptoPrice, APIKey, RateLimit
from src.shared.transformers import (
    transform_coingecko_response,
    get_coingecko_ids,
    get_symbol_name,
    is_supported_symbol,
    transform_external_api_response
)
from src.shared.errors import ValidationError, AuthenticationError, format_error_response
from src.shared.utils import mask_api_key, get_current_timestamp_iso
from src.shared.cache import calculate_ttl


class TestCryptoPriceModel:
    """Tests for CryptoPrice data model."""
    
    def test_crypto_price_initialization(self):
        """Test CryptoPrice initialization with valid data."""
        timestamp = datetime(2024, 1, 15, 10, 30, 0)
        price = CryptoPrice(
            symbol='BTC',
            name='Bitcoin',
            price=45000.50,
            change24h=2.5,
            market_cap=850000000000,
            last_updated=timestamp
        )
        
        assert price.symbol == 'BTC'
        assert price.name == 'Bitcoin'
        assert price.price == 45000.50
        assert price.change24h == 2.5
        assert price.market_cap == 850000000000
        assert price.last_updated == timestamp
    
    def test_crypto_price_to_dict(self):
        """Test CryptoPrice conversion to dictionary."""
        price = CryptoPrice(
            symbol='BTC',
            name='Bitcoin',
            price=45000.567,
            change24h=2.567,
            market_cap=850000000000,
            last_updated=datetime(2024, 1, 15, 10, 30, 0)
        )
        
        result = price.to_dict()
        
        assert result['symbol'] == 'BTC'
        assert result['name'] == 'Bitcoin'
        assert result['price'] == 45000.57  # Rounded to 2 decimals
        assert result['change24h'] == 2.6  # Rounded to 1 decimal
        assert result['marketCap'] == 850000000000
        assert 'lastUpdated' in result
        assert result['lastUpdated'].endswith('Z')
    
    def test_crypto_price_to_dynamodb_item(self):
        """Test CryptoPrice conversion to DynamoDB item."""
        timestamp = datetime(2024, 1, 15, 10, 30, 0)
        price = CryptoPrice(
            symbol='ETH',
            name='Ethereum',
            price=3000.25,
            change24h=-1.2,
            market_cap=360000000000,
            last_updated=timestamp
        )
        
        before_time = int(time.time())
        result = price.to_dynamodb_item(ttl_seconds=3600)
        after_time = int(time.time())
        
        from decimal import Decimal
        
        assert result['PK'] == 'PRICE#ETH'
        assert result['SK'] == 'METADATA'
        assert result['symbol'] == 'ETH'
        assert result['name'] == 'Ethereum'
        assert result['price'] == Decimal('3000.25')
        assert result['change24h'] == Decimal('-1.2')
        assert result['marketCap'] == 360000000000
        assert result['lastUpdated'] == '2024-01-15T10:30:00Z'
        assert 'ttl' in result
        # TTL should be approximately current time + 3600
        assert before_time + 3600 <= result['ttl'] <= after_time + 3600
    
    def test_crypto_price_from_dynamodb_item(self):
        """Test CryptoPrice creation from DynamoDB item."""
        item = {
            'PK': 'PRICE#BTC',
            'SK': 'METADATA',
            'symbol': 'BTC',
            'name': 'Bitcoin',
            'price': 45000.50,
            'change24h': 2.5,
            'marketCap': 850000000000,
            'lastUpdated': '2024-01-15T10:30:00Z',
            'ttl': 1705318200
        }
        
        price = CryptoPrice.from_dynamodb_item(item)
        
        assert price.symbol == 'BTC'
        assert price.name == 'Bitcoin'
        assert price.price == 45000.50
        assert price.change24h == 2.5
        assert price.market_cap == 850000000000
        assert price.last_updated == datetime(2024, 1, 15, 10, 30, 0)
    
    def test_crypto_price_round_trip(self):
        """Test round-trip conversion: model -> DynamoDB -> model."""
        original = CryptoPrice(
            symbol='ADA',
            name='Cardano',
            price=0.567,
            change24h=3.4,
            market_cap=20000000000,
            last_updated=datetime(2024, 1, 15, 12, 0, 0)
        )
        
        # Convert to DynamoDB and back
        dynamodb_item = original.to_dynamodb_item()
        restored = CryptoPrice.from_dynamodb_item(dynamodb_item)
        
        assert restored.symbol == original.symbol
        assert restored.name == original.name
        assert restored.price == original.price
        assert restored.change24h == original.change24h
        assert restored.market_cap == original.market_cap
        assert restored.last_updated == original.last_updated


class TestAPIKeyModel:
    """Tests for APIKey data model."""
    
    def test_api_key_initialization(self):
        """Test APIKey initialization with valid data."""
        created_at = datetime(2024, 1, 1, 0, 0, 0)
        api_key = APIKey(
            key_id='abc123',
            name='Production App',
            created_at=created_at,
            enabled=True
        )
        
        assert api_key.key_id == 'abc123'
        assert api_key.name == 'Production App'
        assert api_key.created_at == created_at
        assert api_key.enabled is True
        assert api_key.last_used_at is None
    
    def test_api_key_with_last_used(self):
        """Test APIKey initialization with last_used_at."""
        created_at = datetime(2024, 1, 1, 0, 0, 0)
        last_used = datetime(2024, 1, 15, 10, 30, 0)
        api_key = APIKey(
            key_id='xyz789',
            name='Test App',
            created_at=created_at,
            enabled=False,
            last_used_at=last_used
        )
        
        assert api_key.last_used_at == last_used
        assert api_key.enabled is False
    
    def test_api_key_to_dynamodb_item(self):
        """Test APIKey conversion to DynamoDB item."""
        api_key = APIKey(
            key_id='test123',
            name='Test Key',
            created_at=datetime(2024, 1, 1, 0, 0, 0),
            enabled=True
        )
        
        result = api_key.to_dynamodb_item()
        
        assert result['PK'] == 'APIKEY#test123'
        assert result['SK'] == 'METADATA'
        assert result['keyId'] == 'test123'
        assert result['name'] == 'Test Key'
        assert result['createdAt'] == '2024-01-01T00:00:00Z'
        assert result['enabled'] is True
        assert 'lastUsedAt' not in result
    
    def test_api_key_to_dynamodb_item_with_last_used(self):
        """Test APIKey conversion to DynamoDB item with last_used_at."""
        api_key = APIKey(
            key_id='test456',
            name='Test Key 2',
            created_at=datetime(2024, 1, 1, 0, 0, 0),
            enabled=True,
            last_used_at=datetime(2024, 1, 15, 10, 30, 0)
        )
        
        result = api_key.to_dynamodb_item()
        
        assert result['lastUsedAt'] == '2024-01-15T10:30:00Z'
    
    def test_api_key_from_dynamodb_item(self):
        """Test APIKey creation from DynamoDB item."""
        item = {
            'PK': 'APIKEY#abc123',
            'SK': 'METADATA',
            'keyId': 'abc123',
            'name': 'Production App',
            'createdAt': '2024-01-01T00:00:00Z',
            'enabled': True
        }
        
        api_key = APIKey.from_dynamodb_item(item)
        
        assert api_key.key_id == 'abc123'
        assert api_key.name == 'Production App'
        assert api_key.created_at == datetime(2024, 1, 1, 0, 0, 0)
        assert api_key.enabled is True
        assert api_key.last_used_at is None
    
    def test_api_key_from_dynamodb_item_with_last_used(self):
        """Test APIKey creation from DynamoDB item with lastUsedAt."""
        item = {
            'PK': 'APIKEY#xyz789',
            'SK': 'METADATA',
            'keyId': 'xyz789',
            'name': 'Test App',
            'createdAt': '2024-01-01T00:00:00Z',
            'enabled': False,
            'lastUsedAt': '2024-01-15T10:30:00Z'
        }
        
        api_key = APIKey.from_dynamodb_item(item)
        
        assert api_key.last_used_at == datetime(2024, 1, 15, 10, 30, 0)
        assert api_key.enabled is False


class TestRateLimitModel:
    """Tests for RateLimit data model."""
    
    def test_rate_limit_initialization(self):
        """Test RateLimit initialization with valid data."""
        rate_limit = RateLimit(
            api_key='abc123',
            minute='202401151030',
            request_count=45,
            ttl=1705318260
        )
        
        assert rate_limit.api_key == 'abc123'
        assert rate_limit.minute == '202401151030'
        assert rate_limit.request_count == 45
        assert rate_limit.ttl == 1705318260
    
    def test_rate_limit_to_dynamodb_item(self):
        """Test RateLimit conversion to DynamoDB item."""
        rate_limit = RateLimit(
            api_key='test123',
            minute='202401151045',
            request_count=30,
            ttl=1705319160
        )
        
        result = rate_limit.to_dynamodb_item()
        
        assert result['PK'] == 'APIKEY#test123'
        assert result['SK'] == 'RATELIMIT#202401151045'
        assert result['requestCount'] == 30
        assert result['ttl'] == 1705319160
    
    def test_rate_limit_from_dynamodb_item(self):
        """Test RateLimit creation from DynamoDB item."""
        item = {
            'PK': 'APIKEY#abc123',
            'SK': 'RATELIMIT#202401151030',
            'requestCount': 45,
            'ttl': 1705318260
        }
        
        rate_limit = RateLimit.from_dynamodb_item(item)
        
        assert rate_limit.api_key == 'abc123'
        assert rate_limit.minute == '202401151030'
        assert rate_limit.request_count == 45
        assert rate_limit.ttl == 1705318260
    
    def test_rate_limit_round_trip(self):
        """Test round-trip conversion: model -> DynamoDB -> model."""
        original = RateLimit(
            api_key='xyz789',
            minute='202401151100',
            request_count=75,
            ttl=1705320000
        )
        
        # Convert to DynamoDB and back
        dynamodb_item = original.to_dynamodb_item()
        restored = RateLimit.from_dynamodb_item(dynamodb_item)
        
        assert restored.api_key == original.api_key
        assert restored.minute == original.minute
        assert restored.request_count == original.request_count
        assert restored.ttl == original.ttl


class TestTransformers:
    """Tests for data transformation functions."""
    
    def test_get_coingecko_ids_single_symbol(self):
        """Test conversion of single symbol to CoinGecko ID."""
        result = get_coingecko_ids(['BTC'])
        assert result == 'bitcoin'
    
    def test_get_coingecko_ids_multiple_symbols(self):
        """Test conversion of multiple symbols to CoinGecko IDs."""
        result = get_coingecko_ids(['BTC', 'ETH', 'ADA'])
        assert result == 'bitcoin,ethereum,cardano'
    
    def test_get_coingecko_ids_unsupported_symbol(self):
        """Test that unsupported symbols are skipped."""
        result = get_coingecko_ids(['BTC', 'INVALID', 'ETH'])
        assert result == 'bitcoin,ethereum'
    
    def test_transform_coingecko_response_single_crypto(self):
        """Test transformation of single cryptocurrency from CoinGecko response."""
        response_data = {
            'bitcoin': {
                'usd': 45000.50,
                'usd_market_cap': 850000000000,
                'usd_24h_change': 2.5
            }
        }
        timestamp = datetime(2024, 1, 15, 10, 30, 0)
        
        result = transform_coingecko_response(response_data, timestamp)
        
        assert len(result) == 1
        assert result[0].symbol == 'BTC'
        assert result[0].name == 'Bitcoin'
        assert result[0].price == 45000.50
        assert result[0].change24h == 2.5
        assert result[0].market_cap == 850000000000
        assert result[0].last_updated == timestamp
    
    def test_transform_coingecko_response_multiple_cryptos(self):
        """Test transformation of multiple cryptocurrencies from CoinGecko response."""
        response_data = {
            'bitcoin': {
                'usd': 45000.50,
                'usd_market_cap': 850000000000,
                'usd_24h_change': 2.5
            },
            'ethereum': {
                'usd': 3000.25,
                'usd_market_cap': 360000000000,
                'usd_24h_change': -1.2
            }
        }
        
        result = transform_coingecko_response(response_data)
        
        assert len(result) == 2
        symbols = [p.symbol for p in result]
        assert 'BTC' in symbols
        assert 'ETH' in symbols
    
    def test_transform_coingecko_response_missing_fields(self):
        """Test transformation handles missing fields with defaults."""
        response_data = {
            'bitcoin': {
                # Missing usd_market_cap and usd_24h_change
                'usd': 45000.50
            }
        }
        
        result = transform_coingecko_response(response_data)
        
        assert len(result) == 1
        assert result[0].symbol == 'BTC'
        assert result[0].price == 45000.50
        assert result[0].market_cap == 0  # Default value
        assert result[0].change24h == 0.0  # Default value
    
    def test_transform_coingecko_response_unknown_id(self):
        """Test that unknown CoinGecko IDs are skipped."""
        response_data = {
            'bitcoin': {
                'usd': 45000.50,
                'usd_market_cap': 850000000000,
                'usd_24h_change': 2.5
            },
            'unknown-coin': {
                'usd': 100.0,
                'usd_market_cap': 1000000,
                'usd_24h_change': 5.0
            }
        }
        
        result = transform_coingecko_response(response_data)
        
        assert len(result) == 1
        assert result[0].symbol == 'BTC'
    
    def test_transform_external_api_response_coingecko(self):
        """Test generic external API transformation with CoinGecko."""
        response_data = {
            'ethereum': {
                'usd': 3000.25,
                'usd_market_cap': 360000000000,
                'usd_24h_change': -1.2
            }
        }
        
        result = transform_external_api_response(response_data, api_type='coingecko')
        
        assert len(result) == 1
        assert result[0].symbol == 'ETH'
    
    def test_transform_external_api_response_unsupported_type(self):
        """Test that unsupported API types raise ValueError."""
        with pytest.raises(ValueError, match='Unsupported API type'):
            transform_external_api_response({}, api_type='unsupported')
    
    def test_get_symbol_name_valid(self):
        """Test getting full name for valid symbol."""
        assert get_symbol_name('BTC') == 'Bitcoin'
        assert get_symbol_name('ETH') == 'Ethereum'
        assert get_symbol_name('ADA') == 'Cardano'
    
    def test_get_symbol_name_invalid(self):
        """Test that invalid symbol raises ValueError."""
        with pytest.raises(ValueError, match='Unsupported symbol'):
            get_symbol_name('INVALID')
    
    def test_is_supported_symbol_valid(self):
        """Test checking if symbol is supported."""
        assert is_supported_symbol('BTC') is True
        assert is_supported_symbol('ETH') is True
        assert is_supported_symbol('DOGE') is True
    
    def test_is_supported_symbol_invalid(self):
        """Test checking if unsupported symbol returns False."""
        assert is_supported_symbol('INVALID') is False
        assert is_supported_symbol('XYZ') is False


class TestErrors:
    """Tests for error handling."""
    
    def test_validation_error(self):
        """Test ValidationError creation."""
        error = ValidationError('Invalid input')
        assert error.status_code == 400
        assert error.code == 'VALIDATION_ERROR'
    
    def test_authentication_error(self):
        """Test AuthenticationError creation."""
        error = AuthenticationError()
        assert error.status_code == 401
        assert error.code == 'UNAUTHORIZED'
    
    def test_format_error_response(self):
        """Test error response formatting."""
        error = ValidationError('Invalid symbol')
        response = format_error_response(error, 'test-request-id')
        
        assert response['statusCode'] == 400
        assert 'error' in response['body']
        assert response['body']['code'] == 'VALIDATION_ERROR'
        assert response['body']['requestId'] == 'test-request-id'


class TestUtils:
    """Tests for utility functions."""
    
    def test_mask_api_key(self):
        """Test API key masking."""
        key = 'abc123def456'
        masked = mask_api_key(key)
        assert masked == 'abc123d***'
        assert len(masked) < len(key)
    
    def test_mask_short_api_key(self):
        """Test masking of short API key."""
        key = 'short'
        masked = mask_api_key(key)
        assert masked == 'key_***'
    
    def test_get_current_timestamp_iso(self):
        """Test ISO timestamp generation."""
        timestamp = get_current_timestamp_iso()
        assert isinstance(timestamp, str)
        assert timestamp.endswith('Z')
        assert 'T' in timestamp


class TestCacheUtilities:
    """Tests for cache management utilities."""
    
    def test_calculate_ttl(self):
        """Test TTL calculation."""
        before_time = int(time.time())
        ttl = calculate_ttl(3600)
        after_time = int(time.time())
        
        # TTL should be approximately current time + 3600
        assert before_time + 3600 <= ttl <= after_time + 3600
    
    def test_calculate_ttl_custom_duration(self):
        """Test TTL calculation with custom duration."""
        before_time = int(time.time())
        ttl = calculate_ttl(1800)  # 30 minutes
        after_time = int(time.time())
        
        assert before_time + 1800 <= ttl <= after_time + 1800
    
    def test_is_cache_fresh_within_threshold(self):
        """Test cache freshness check for data within threshold."""
        from datetime import timezone
        from src.shared.cache import is_cache_fresh
        
        # Data updated 2 minutes ago
        last_updated = datetime.now(timezone.utc).replace(microsecond=0)
        last_updated = last_updated.replace(minute=last_updated.minute - 2)
        
        assert is_cache_fresh(last_updated, threshold_minutes=5) is True
    
    def test_is_cache_fresh_beyond_threshold(self):
        """Test cache freshness check for data beyond threshold."""
        from datetime import timezone
        from src.shared.cache import is_cache_fresh
        
        # Data updated 7 minutes ago
        last_updated = datetime.now(timezone.utc).replace(microsecond=0)
        last_updated = last_updated.replace(minute=last_updated.minute - 7)
        
        assert is_cache_fresh(last_updated, threshold_minutes=5) is False
    
    def test_is_cache_fresh_no_timezone(self):
        """Test cache freshness check for datetime without timezone (assumes UTC)."""
        from src.shared.cache import is_cache_fresh
        
        # Data updated 3 minutes ago (no timezone info)
        last_updated = datetime.utcnow().replace(microsecond=0)
        last_updated = last_updated.replace(minute=last_updated.minute - 3)
        
        assert is_cache_fresh(last_updated, threshold_minutes=5) is True
    
    def test_get_cache_age_seconds(self):
        """Test cache age calculation."""
        from datetime import timezone
        from src.shared.cache import get_cache_age_seconds
        
        # Data updated 2 minutes ago
        last_updated = datetime.now(timezone.utc).replace(microsecond=0)
        last_updated = last_updated.replace(minute=last_updated.minute - 2)
        
        age = get_cache_age_seconds(last_updated)
        
        # Should be approximately 120 seconds (2 minutes)
        assert 115 <= age <= 125  # Allow some tolerance for test execution time
    
    def test_should_refresh_cache_no_data(self):
        """Test refresh decision when no cache exists."""
        from src.shared.cache import should_refresh_cache
        
        assert should_refresh_cache(None) is True
    
    def test_should_refresh_cache_fresh_data(self):
        """Test refresh decision for fresh data."""
        from datetime import timezone
        from src.shared.cache import should_refresh_cache
        
        # Data updated 2 minutes ago
        last_updated = datetime.now(timezone.utc).replace(microsecond=0)
        last_updated = last_updated.replace(minute=last_updated.minute - 2)
        
        assert should_refresh_cache(last_updated, threshold_minutes=5) is False
    
    def test_should_refresh_cache_stale_data(self):
        """Test refresh decision for stale data."""
        from datetime import timezone
        from src.shared.cache import should_refresh_cache
        
        # Data updated 7 minutes ago
        last_updated = datetime.now(timezone.utc).replace(microsecond=0)
        last_updated = last_updated.replace(minute=last_updated.minute - 7)
        
        assert should_refresh_cache(last_updated, threshold_minutes=5) is True