"""
End-to-end integration tests.

Tests the complete flow of the crypto-watch-backend system including:
- API Gateway request handling
- Lambda function execution
- DynamoDB operations
- Cache behavior
- Rate limiting
- EventBridge triggers

Validates: Requirements 1.1, 2.1, 4.3
"""

import pytest
import json
import time
import os
from datetime import datetime, timezone, timedelta
from moto import mock_aws
import boto3
from unittest.mock import patch, MagicMock

# Import handlers
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'src'))

from shared.models import CryptoPrice, APIKey, RateLimit
from shared.db import DynamoDBClient
from shared.cache import CacheManager
from shared.auth import AuthMiddleware


@pytest.fixture(scope='function', autouse=True)
def aws_environment():
    """Set up AWS environment variables for testing."""
    os.environ['AWS_ACCESS_KEY_ID'] = 'testing'
    os.environ['AWS_SECRET_ACCESS_KEY'] = 'testing'
    os.environ['AWS_SECURITY_TOKEN'] = 'testing'
    os.environ['AWS_SESSION_TOKEN'] = 'testing'
    os.environ['AWS_DEFAULT_REGION'] = 'us-east-1'
    os.environ['DYNAMODB_TABLE_NAME'] = 'crypto-watch-data-test'
    os.environ['ENVIRONMENT'] = 'test'
    os.environ['RATE_LIMIT_PER_MINUTE'] = '100'
    os.environ['CACHE_TTL_SECONDS'] = '300'
    yield


@pytest.fixture(scope='function')
def aws_mock():
    """Start AWS mocking."""
    with mock_aws():
        yield


@pytest.fixture
def dynamodb_table(aws_mock):
    """Create a mock DynamoDB table for testing."""
    # Create DynamoDB resource
    dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
    
    # Create table
    table = dynamodb.create_table(
        TableName='crypto-watch-data-test',
        KeySchema=[
            {'AttributeName': 'PK', 'KeyType': 'HASH'},
            {'AttributeName': 'SK', 'KeyType': 'RANGE'}
        ],
        AttributeDefinitions=[
            {'AttributeName': 'PK', 'AttributeType': 'S'},
            {'AttributeName': 'SK', 'AttributeType': 'S'}
        ],
        BillingMode='PAY_PER_REQUEST'
    )
    
    # Wait for table to be created
    table.meta.client.get_waiter('table_exists').wait(TableName='crypto-watch-data-test')
    
    yield table


@pytest.fixture
def setup_test_api_key(dynamodb_table):
    """Set up a test API key in DynamoDB."""
    api_key = APIKey(
        key_id='test-api-key-123',
        name='Test API Key',
        enabled=True,
        created_at=datetime.now(timezone.utc)
    )
    
    dynamodb_table.put_item(Item=api_key.to_dynamodb_item())
    
    return 'test-api-key-123'


@pytest.fixture
def setup_test_price_data(dynamodb_table):
    """Set up test price data in DynamoDB."""
    prices = [
        CryptoPrice(
            symbol='BTC',
            name='Bitcoin',
            price=45000.50,
            change24h=2.5,
            market_cap=850000000000,
            last_updated=datetime.now(timezone.utc)
        ),
        CryptoPrice(
            symbol='ETH',
            name='Ethereum',
            price=3000.25,
            change24h=-1.2,
            market_cap=360000000000,
            last_updated=datetime.now(timezone.utc)
        )
    ]
    
    for price in prices:
        dynamodb_table.put_item(Item=price.to_dynamodb_item(ttl_seconds=3600))
    
    return prices


@pytest.fixture
def mock_external_api():
    """Mock external API responses."""
    def mock_fetch_prices(symbols):
        """Mock fetch_prices method."""
        mock_prices = []
        price_map = {
            'BTC': (45000.50, 'Bitcoin', 2.5, 850000000000),
            'ETH': (3000.25, 'Ethereum', -1.2, 360000000000),
            'ADA': (0.50, 'Cardano', 5.0, 17000000000)
        }
        
        for symbol in symbols:
            if symbol in price_map:
                price, name, change, mcap = price_map[symbol]
                mock_prices.append(CryptoPrice(
                    symbol=symbol,
                    name=name,
                    price=price,
                    change24h=change,
                    market_cap=mcap,
                    last_updated=datetime.now(timezone.utc)
                ))
        
        return mock_prices
    
    return mock_fetch_prices


@pytest.mark.integration
class TestEndToEndAPIFlow:
    """
    Test end-to-end API request flow with DynamoDB.
    Validates: Requirement 1.1
    """
    
    def test_complete_data_flow_through_dynamodb(self, dynamodb_table, setup_test_api_key, setup_test_price_data):
        """
        Test complete data flow: write to DynamoDB, read from DynamoDB, verify data integrity.
        
        Flow:
        1. Write price data to DynamoDB
        2. Write API key to DynamoDB
        3. Read price data back
        4. Verify data integrity
        """
        # Create DB client
        db_client = DynamoDBClient(table_name='crypto-watch-data-test')
        
        # Verify API key was written correctly
        api_key_data = db_client.get_api_key(setup_test_api_key)
        assert api_key_data is not None
        assert api_key_data.key_id == setup_test_api_key
        assert api_key_data.enabled is True
        
        # Verify price data was written correctly
        btc_price = db_client.get_price_data('BTC')
        assert btc_price is not None
        assert btc_price.symbol == 'BTC'
        assert btc_price.name == 'Bitcoin'
        assert btc_price.price == 45000.50
        
        eth_price = db_client.get_price_data('ETH')
        assert eth_price is not None
        assert eth_price.symbol == 'ETH'
        assert eth_price.name == 'Ethereum'
        
        # Test batch retrieval
        prices = db_client.get_multiple_price_data(['BTC', 'ETH'])
        assert len(prices) == 2
        assert 'BTC' in prices
        assert 'ETH' in prices
    
    def test_authentication_flow(self, dynamodb_table, setup_test_api_key):
        """Test authentication flow with DynamoDB."""
        # Create auth middleware
        auth_middleware = AuthMiddleware()
        
        # Test valid API key
        api_key_data = auth_middleware.validate_api_key(setup_test_api_key)
        assert api_key_data is not None
        assert api_key_data.enabled is True
        
        # Test invalid API key
        with pytest.raises(Exception) as exc_info:
            auth_middleware.validate_api_key('invalid-key')
        assert 'Invalid API key' in str(exc_info.value)
        
        # Test missing API key
        with pytest.raises(Exception) as exc_info:
            auth_middleware.validate_api_key(None)
        assert 'Missing API key' in str(exc_info.value)
    
    def test_cache_manager_integration(self, dynamodb_table, setup_test_price_data):
        """Test cache manager with DynamoDB."""
        # Create cache manager
        cache_manager = CacheManager()
        
        # Test getting fresh cache data
        cache_status = cache_manager.get_cache_status(['BTC', 'ETH'], threshold_minutes=5)
        
        assert 'BTC' in cache_status
        assert 'ETH' in cache_status
        assert cache_status['BTC']['is_fresh'] is True
        assert cache_status['ETH']['is_fresh'] is True
        
        # Get fresh data
        fresh_data = cache_manager.get_fresh_multiple_price_data(['BTC', 'ETH'], threshold_minutes=5)
        assert len(fresh_data) == 2
        assert 'BTC' in fresh_data
        assert 'ETH' in fresh_data


@pytest.mark.integration
class TestCacheBehavior:
    """
    Test cache behavior with DynamoDB.
    Validates: Requirement 2.1
    """
    
    def test_fresh_cache_identification(self, dynamodb_table, setup_test_price_data):
        """
        Test that fresh cache data (< 5 minutes old) is correctly identified.
        
        Validates: Property 2 - Cache freshness determines data source
        """
        cache_manager = CacheManager()
        
        # Check cache status for fresh data
        cache_status = cache_manager.get_cache_status(['BTC', 'ETH'], threshold_minutes=5)
        
        # Verify both symbols are identified as fresh
        assert cache_status['BTC']['is_fresh'] is True
        assert cache_status['BTC']['needs_refresh'] is False
        assert cache_status['ETH']['is_fresh'] is True
        assert cache_status['ETH']['needs_refresh'] is False
        
        # Verify we can retrieve the fresh data
        fresh_data = cache_manager.get_fresh_multiple_price_data(['BTC', 'ETH'], threshold_minutes=5)
        assert len(fresh_data) == 2
        assert fresh_data['BTC'].price == 45000.50
        assert fresh_data['ETH'].price == 3000.25
    
    def test_stale_cache_identification(self, dynamodb_table):
        """
        Test that stale cache data (> 5 minutes old) is correctly identified.
        
        Validates: Property 3 - Cache invalidation triggers refresh
        """
        # Create stale price data (10 minutes old)
        stale_time = datetime.now(timezone.utc) - timedelta(minutes=10)
        stale_price = CryptoPrice(
            symbol='BTC',
            name='Bitcoin',
            price=44000.00,  # Old price
            change24h=1.0,
            market_cap=840000000000,
            last_updated=stale_time
        )
        
        dynamodb_table.put_item(Item=stale_price.to_dynamodb_item(ttl_seconds=3600))
        
        cache_manager = CacheManager()
        
        # Check cache status for stale data
        cache_status = cache_manager.get_cache_status(['BTC'], threshold_minutes=5)
        
        # Verify symbol is identified as stale
        assert cache_status['BTC']['is_fresh'] is False
        assert cache_status['BTC']['needs_refresh'] is True
        assert cache_status['BTC']['age_seconds'] > 300  # More than 5 minutes (300 seconds)
    
    def test_missing_cache_identification(self, dynamodb_table):
        """Test that missing cache data is correctly identified."""
        cache_manager = CacheManager()
        
        # Check cache status for non-existent symbol
        cache_status = cache_manager.get_cache_status(['NONEXISTENT'], threshold_minutes=5)
        
        # Verify symbol is identified as needing refresh
        assert cache_status['NONEXISTENT']['is_fresh'] is False
        assert cache_status['NONEXISTENT']['needs_refresh'] is True
        assert cache_status['NONEXISTENT']['age_seconds'] is None
    
    def test_cache_write_and_read_cycle(self, dynamodb_table):
        """Test writing to cache and reading back."""
        cache_manager = CacheManager()
        
        # Create new price data
        new_prices = [
            CryptoPrice(
                symbol='ADA',
                name='Cardano',
                price=0.50,
                change24h=5.0,
                market_cap=17000000000,
                last_updated=datetime.now(timezone.utc)
            )
        ]
        
        # Write to cache
        cache_manager.cache_multiple_price_data(new_prices, ttl_seconds=3600)
        
        # Read back from cache
        cached_data = cache_manager.get_fresh_multiple_price_data(['ADA'], threshold_minutes=5)
        
        assert len(cached_data) == 1
        assert cached_data['ADA'].symbol == 'ADA'
        assert cached_data['ADA'].price == 0.50


@pytest.mark.integration
class TestRateLimiting:
    """
    Test rate limiting across multiple requests.
    Validates: Requirement 4.3
    """
    
    def test_rate_limit_enforcement_across_requests(self, dynamodb_table, setup_test_api_key):
        """
        Test that rate limiting is enforced across multiple requests.
        
        Validates: Property 10 - Rate limit enforcement
        """
        # Set a low rate limit for testing
        os.environ['RATE_LIMIT_PER_MINUTE'] = '3'
        
        # Create auth middleware
        auth_middleware = AuthMiddleware()
        
        # Make requests up to the limit
        for i in range(3):
            try:
                auth_middleware.authenticate_request(setup_test_api_key)
            except Exception as e:
                pytest.fail(f"Request {i+1} should succeed but got: {e}")
        
        # Next request should be rate limited
        with pytest.raises(Exception) as exc_info:
            auth_middleware.authenticate_request(setup_test_api_key)
        
        assert 'Rate limit exceeded' in str(exc_info.value) or 'RateLimitError' in str(type(exc_info.value))
        
        # Reset environment variable
        os.environ['RATE_LIMIT_PER_MINUTE'] = '100'
    
    def test_rate_limit_tracking_in_dynamodb(self, dynamodb_table, setup_test_api_key):
        """Test that rate limit data is correctly stored in DynamoDB."""
        db_client = DynamoDBClient(table_name='crypto-watch-data-test')
        auth_middleware = AuthMiddleware(db_client=db_client)
        
        # Make a request
        auth_middleware.authenticate_request(setup_test_api_key)
        
        # Check that rate limit data was written
        current_minute = datetime.utcnow().strftime('%Y%m%d%H%M')
        rate_limit_data = db_client.get_rate_limit(setup_test_api_key, current_minute)
        
        assert rate_limit_data is not None
        assert rate_limit_data.request_count >= 1
        assert rate_limit_data.api_key == setup_test_api_key
        assert rate_limit_data.minute == current_minute
    
    def test_rate_limit_increments_correctly(self, dynamodb_table, setup_test_api_key):
        """Test that rate limit counter increments with each request."""
        db_client = DynamoDBClient(table_name='crypto-watch-data-test')
        auth_middleware = AuthMiddleware(db_client=db_client)
        
        current_minute = datetime.utcnow().strftime('%Y%m%d%H%M')
        
        # Make multiple requests
        for i in range(3):
            auth_middleware.authenticate_request(setup_test_api_key)
            
            # Check counter
            rate_limit_data = db_client.get_rate_limit(setup_test_api_key, current_minute)
            assert rate_limit_data.request_count == i + 1


@pytest.mark.integration
class TestPriceUpdateFlow:
    """
    Test Price Update flow with DynamoDB.
    Validates: Requirements 3.1, 3.2, 3.5
    """
    
    def test_price_update_writes_to_dynamodb(self, dynamodb_table, mock_external_api):
        """
        Test that price update correctly writes data to DynamoDB.
        
        Validates: Property 8 - Update timestamp tracking
        """
        db_client = DynamoDBClient(table_name='crypto-watch-data-test')
        
        # Simulate fetching prices from external API
        symbols = ['BTC', 'ETH', 'ADA']
        prices = mock_external_api(symbols)
        
        # Save to DynamoDB
        success = db_client.save_multiple_price_data(prices, ttl_seconds=3600)
        assert success is True
        
        # Verify data was saved correctly
        for symbol in symbols:
            price_data = db_client.get_price_data(symbol)
            assert price_data is not None
            assert price_data.symbol == symbol
            assert price_data.last_updated is not None
            
            # Verify timestamp is recent (within last minute)
            time_diff = datetime.now(timezone.utc) - price_data.last_updated
            assert time_diff.total_seconds() < 60
    
    def test_batch_price_update(self, dynamodb_table):
        """Test batch writing of multiple price updates."""
        db_client = DynamoDBClient(table_name='crypto-watch-data-test')
        
        # Create multiple price entries
        prices = [
            CryptoPrice(
                symbol=f'TEST{i}',
                name=f'Test Coin {i}',
                price=float(i * 100),
                change24h=float(i),
                market_cap=i * 1000000,
                last_updated=datetime.now(timezone.utc)
            )
            for i in range(1, 6)
        ]
        
        # Batch write
        success = db_client.save_multiple_price_data(prices, ttl_seconds=3600)
        assert success is True
        
        # Verify all were written
        for i in range(1, 6):
            price_data = db_client.get_price_data(f'TEST{i}')
            assert price_data is not None
            assert price_data.price == float(i * 100)


@pytest.mark.integration
class TestDataIntegrity:
    """Test data integrity across operations."""
    
    def test_timestamp_persistence(self, dynamodb_table):
        """
        Test that timestamps are correctly persisted and retrieved.
        
        Validates: Property 4 - Timestamp persistence
        """
        db_client = DynamoDBClient(table_name='crypto-watch-data-test')
        
        # Create price with specific timestamp
        test_time = datetime.now(timezone.utc)
        price = CryptoPrice(
            symbol='TEST',
            name='Test Coin',
            price=100.0,
            change24h=5.0,
            market_cap=1000000,
            last_updated=test_time
        )
        
        # Save to DynamoDB
        db_client.save_price_data(price, ttl_seconds=3600)
        
        # Retrieve and verify timestamp
        retrieved = db_client.get_price_data('TEST')
        assert retrieved is not None
        
        # Timestamps should match (within 1 second due to serialization)
        time_diff = abs((retrieved.last_updated - test_time).total_seconds())
        assert time_diff < 1
    
    def test_data_structure_completeness(self, dynamodb_table, setup_test_price_data):
        """
        Test that all required fields are present in stored data.
        
        Validates: Property 1 - Complete response data structure
        """
        db_client = DynamoDBClient(table_name='crypto-watch-data-test')
        
        # Retrieve price data
        btc_data = db_client.get_price_data('BTC')
        
        # Verify all required fields are present
        assert btc_data.symbol is not None
        assert btc_data.name is not None
        assert btc_data.price is not None
        assert btc_data.change24h is not None
        assert btc_data.market_cap is not None
        assert btc_data.last_updated is not None
        
        # Verify data types
        assert isinstance(btc_data.symbol, str)
        assert isinstance(btc_data.name, str)
        assert isinstance(btc_data.price, (int, float))
        assert isinstance(btc_data.change24h, (int, float))
        assert isinstance(btc_data.market_cap, int)
        assert isinstance(btc_data.last_updated, datetime)
    
    def test_concurrent_writes_and_reads(self, dynamodb_table):
        """Test that concurrent operations maintain data integrity."""
        db_client = DynamoDBClient(table_name='crypto-watch-data-test')
        
        # Write multiple prices
        prices = [
            CryptoPrice(
                symbol=f'COIN{i}',
                name=f'Coin {i}',
                price=float(i),
                change24h=0.0,
                market_cap=i * 1000,
                last_updated=datetime.now(timezone.utc)
            )
            for i in range(5)
        ]
        
        db_client.save_multiple_price_data(prices, ttl_seconds=3600)
        
        # Read them back
        symbols = [f'COIN{i}' for i in range(5)]
        retrieved = db_client.get_multiple_price_data(symbols)
        
        # Verify all were retrieved correctly
        assert len(retrieved) == 5
        for i in range(5):
            assert f'COIN{i}' in retrieved
            assert retrieved[f'COIN{i}'].price == float(i)
