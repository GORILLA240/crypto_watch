"""
Unit tests and property-based tests for Price Update Lambda function.
"""

import pytest
from hypothesis import given, strategies as st, settings
from datetime import datetime, timezone
import time

from src.shared.models import CryptoPrice


# Strategy for generating valid cryptocurrency symbols
symbol_strategy = st.text(
    min_size=2, 
    max_size=10, 
    alphabet=st.characters(whitelist_categories=('Lu',))
)

# Strategy for generating lists of symbols
symbols_list_strategy = st.lists(
    symbol_strategy,
    min_size=1,
    max_size=20,
    unique=True
)


@pytest.mark.property
class TestUpdateHandlerProperties:
    """Property-based tests for Price Update Lambda handler."""
    
    @settings(max_examples=100)
    @given(
        symbols=symbols_list_strategy,
        price=st.floats(min_value=0.01, max_value=1000000.0, allow_nan=False, allow_infinity=False),
        change24h=st.floats(min_value=-100.0, max_value=1000.0, allow_nan=False, allow_infinity=False),
        market_cap=st.integers(min_value=1, max_value=10**15)
    )
    def test_property_8_update_timestamp_tracking(self, symbols, price, change24h, market_cap):
        """
        Feature: crypto-watch-backend, Property 8: Update timestamp tracking
        
        Property: For any successful price update operation, the system should record 
        the timestamp of the successful update for monitoring purposes.
        
        This property ensures that when price data is updated, it includes a timestamp 
        that can be used for monitoring and tracking the last successful update.
        The timestamp should be:
        1. Present in the saved data
        2. In valid ISO format
        3. Within the execution window
        4. Consistent across all saved items in a batch
        
        Validates: Requirements 3.5
        """
        # Create price data for the symbols
        before_time = datetime.now(timezone.utc)
        
        prices = []
        for symbol in symbols:
            price_obj = CryptoPrice(
                symbol=symbol,
                name=f"{symbol} Coin",
                price=price,
                change24h=change24h,
                market_cap=market_cap,
                last_updated=datetime.now(timezone.utc)
            )
            prices.append(price_obj)
        
        after_time = datetime.now(timezone.utc)
        
        # Property 1: All price objects must have a last_updated timestamp
        for price_obj in prices:
            assert hasattr(price_obj, 'last_updated'), "Price object must have last_updated attribute"
            assert price_obj.last_updated is not None, "last_updated must not be None"
            assert isinstance(price_obj.last_updated, datetime), "last_updated must be datetime object"
        
        # Property 2: Timestamps should be within the execution window
        for price_obj in prices:
            assert before_time <= price_obj.last_updated <= after_time, \
                f"Timestamp {price_obj.last_updated} should be between {before_time} and {after_time}"
        
        # Property 3: When converted to DynamoDB format, timestamp must be preserved
        for price_obj in prices:
            dynamodb_item = price_obj.to_dynamodb_item()
            
            # Must include lastUpdated field
            assert 'lastUpdated' in dynamodb_item, "DynamoDB item must include lastUpdated field"
            assert dynamodb_item['lastUpdated'] is not None, "lastUpdated must not be None"
            assert isinstance(dynamodb_item['lastUpdated'], str), "lastUpdated must be string (ISO format)"
            
            # Must be valid ISO format
            try:
                parsed_timestamp = datetime.fromisoformat(dynamodb_item['lastUpdated'].rstrip('Z'))
                assert parsed_timestamp is not None, "Timestamp should be parseable"
            except (ValueError, AttributeError) as e:
                pytest.fail(f"Timestamp is not valid ISO format: {e}")
            
            # Timestamp should match the original (within 1 second tolerance)
            # Make both timestamps timezone-aware for comparison
            original_ts = price_obj.last_updated if price_obj.last_updated.tzinfo else price_obj.last_updated.replace(tzinfo=timezone.utc)
            parsed_ts = parsed_timestamp if parsed_timestamp.tzinfo else parsed_timestamp.replace(tzinfo=timezone.utc)
            time_diff = abs((parsed_ts - original_ts).total_seconds())
            assert time_diff < 1.0, f"Timestamp should be preserved in conversion (diff: {time_diff}s)"
        
        # Property 4: All items in a batch should have similar timestamps
        # (they should all be created within a short time window)
        if len(prices) > 1:
            timestamps = [p.last_updated for p in prices]
            min_timestamp = min(timestamps)
            max_timestamp = max(timestamps)
            time_spread = (max_timestamp - min_timestamp).total_seconds()
            
            # All timestamps in a batch should be within 1 second of each other
            assert time_spread < 1.0, \
                f"Timestamps in a batch should be consistent (spread: {time_spread}s)"
        
        # Property 5: Timestamp should be monotonically increasing across multiple updates
        # Simulate multiple update operations
        update_timestamps = []
        for _ in range(3):
            update_time = datetime.now(timezone.utc)
            update_timestamps.append(update_time)
            time.sleep(0.01)  # Small delay to ensure timestamps are different
        
        # Verify timestamps are non-decreasing
        for i in range(1, len(update_timestamps)):
            assert update_timestamps[i] >= update_timestamps[i-1], \
                f"Update timestamp {i} should be >= timestamp {i-1}"
    
    @settings(max_examples=100)
    @given(
        symbol=symbol_strategy,
        ttl_seconds=st.integers(min_value=60, max_value=7200)
    )
    def test_timestamp_persistence_in_dynamodb_format(self, symbol, ttl_seconds):
        """
        Property: Timestamps must persist correctly when converting to/from DynamoDB format.
        
        This ensures that the timestamp tracking mechanism works correctly through
        the full data lifecycle: creation -> DynamoDB storage -> retrieval.
        """
        # Create a price object with a specific timestamp
        original_timestamp = datetime.now(timezone.utc)
        price = CryptoPrice(
            symbol=symbol,
            name=f"{symbol} Coin",
            price=100.0,
            change24h=2.5,
            market_cap=1000000000,
            last_updated=original_timestamp
        )
        
        # Convert to DynamoDB format
        dynamodb_item = price.to_dynamodb_item(ttl_seconds)
        
        # Property 1: DynamoDB item must include timestamp
        assert 'lastUpdated' in dynamodb_item, "DynamoDB item must include lastUpdated"
        
        # Property 2: Timestamp must be in ISO format with 'Z' suffix
        assert dynamodb_item['lastUpdated'].endswith('Z'), "Timestamp must end with 'Z'"
        
        # Property 3: Convert back from DynamoDB format
        recovered_price = CryptoPrice.from_dynamodb_item(dynamodb_item)
        
        # Property 4: Timestamp should be preserved in round-trip (within 1 second tolerance)
        # Make both timestamps timezone-aware for comparison
        original_ts = original_timestamp if original_timestamp.tzinfo else original_timestamp.replace(tzinfo=timezone.utc)
        recovered_ts = recovered_price.last_updated if recovered_price.last_updated.tzinfo else recovered_price.last_updated.replace(tzinfo=timezone.utc)
        time_diff = abs((recovered_ts - original_ts).total_seconds())
        assert time_diff < 1.0, \
            f"Timestamp should be preserved in round-trip (diff: {time_diff}s)"
        
        # Property 5: TTL should be present and in the future
        assert 'ttl' in dynamodb_item, "DynamoDB item must include TTL"
        current_time = int(time.time())
        assert dynamodb_item['ttl'] > current_time, "TTL should be in the future"
        
        # Property 6: TTL should be approximately current_time + ttl_seconds
        expected_ttl_min = current_time + ttl_seconds - 2  # Allow 2 second tolerance
        expected_ttl_max = current_time + ttl_seconds + 2
        assert expected_ttl_min <= dynamodb_item['ttl'] <= expected_ttl_max, \
            f"TTL {dynamodb_item['ttl']} should be between {expected_ttl_min} and {expected_ttl_max}"
    
    @settings(max_examples=100)
    @given(symbols=symbols_list_strategy)
    def test_batch_update_timestamp_consistency(self, symbols):
        """
        Property: All items in a batch update should have consistent timestamps.
        
        This ensures that when multiple price items are updated together,
        they all receive timestamps from the same time window, which is
        important for monitoring and cache coherence.
        """
        # Simulate a batch update operation
        batch_timestamp = datetime.now(timezone.utc)
        
        prices = []
        for symbol in symbols:
            price = CryptoPrice(
                symbol=symbol,
                name=f"{symbol} Coin",
                price=100.0,
                change24h=2.5,
                market_cap=1000000000,
                last_updated=batch_timestamp
            )
            prices.append(price)
        
        # Property 1: All prices should have the same timestamp
        timestamps = [p.last_updated for p in prices]
        assert len(set(timestamps)) == 1, "All prices in a batch should have the same timestamp"
        
        # Property 2: When converted to DynamoDB format, timestamps should remain consistent
        dynamodb_items = [p.to_dynamodb_item() for p in prices]
        dynamodb_timestamps = [item['lastUpdated'] for item in dynamodb_items]
        assert len(set(dynamodb_timestamps)) == 1, \
            "All DynamoDB items in a batch should have the same timestamp"
        
        # Property 3: All items should have similar TTL values (within 1 second)
        ttls = [item['ttl'] for item in dynamodb_items]
        min_ttl = min(ttls)
        max_ttl = max(ttls)
        assert max_ttl - min_ttl <= 1, \
            f"TTL values in a batch should be consistent (spread: {max_ttl - min_ttl}s)"


class TestUpdateHandler:
    """Unit tests for Price Update Lambda handler."""
    
    def test_handler_with_mock_eventbridge_event_success(self, monkeypatch, aws_credentials, environment_variables):
        """
        Test handler with mock EventBridge event - successful update flow.
        
        Requirements: 3.2, 3.4
        """
        from src.update.handler import lambda_handler
        from src.shared.models import CryptoPrice
        from datetime import datetime, timezone
        
        # Mock EventBridge scheduled event
        event = {
            'version': '0',
            'id': 'test-event-id',
            'detail-type': 'Scheduled Event',
            'source': 'aws.events',
            'account': '123456789012',
            'time': '2024-01-15T10:30:00Z',
            'region': 'us-east-1',
            'resources': ['arn:aws:events:us-east-1:123456789012:rule/price-update-rule'],
            'detail': {}
        }
        
        # Mock successful API response
        mock_prices = [
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
                price=2500.75,
                change24h=1.8,
                market_cap=300000000000,
                last_updated=datetime.now(timezone.utc)
            )
        ]
        
        # Mock ExternalAPIClient.fetch_prices
        def mock_fetch_prices(self, symbols):
            return mock_prices
        
        # Mock DynamoDBClient.save_multiple_price_data
        def mock_save_multiple_price_data(self, prices, ttl_seconds=3600):
            return True
        
        # Apply mocks
        from src.shared import external_api, db
        monkeypatch.setattr(external_api.ExternalAPIClient, 'fetch_prices', mock_fetch_prices)
        monkeypatch.setattr(db.DynamoDBClient, 'save_multiple_price_data', mock_save_multiple_price_data)
        
        # Execute handler
        response = lambda_handler(event, None)
        
        # Verify response
        assert response['statusCode'] == 200
        
        import json
        body = json.loads(response['body'])
        assert body['message'] == 'Price update completed successfully'
        assert body['priceCount'] == 2
        assert 'lastUpdated' in body
        assert 'timestamp' in body
    
    def test_handler_external_api_failure_after_retries(self, monkeypatch, aws_credentials, environment_variables):
        """
        Test handler when external API fails after all retries.
        
        This tests the error handling when the external API client exhausts
        all retry attempts and raises ExternalAPIError.
        
        Requirements: 3.4
        """
        from src.update.handler import lambda_handler
        from src.shared.errors import ExternalAPIError
        
        # Mock EventBridge event
        event = {
            'version': '0',
            'id': 'test-event-id',
            'detail-type': 'Scheduled Event',
            'source': 'aws.events',
            'time': '2024-01-15T10:30:00Z',
            'detail': {}
        }
        
        # Mock ExternalAPIClient.fetch_prices to raise error
        def mock_fetch_prices_error(self, symbols):
            raise ExternalAPIError(
                'Failed to fetch prices after 4 attempts',
                details={'attempts': 4, 'lastError': 'Connection timeout'}
            )
        
        # Apply mock
        from src.shared import external_api
        monkeypatch.setattr(external_api.ExternalAPIClient, 'fetch_prices', mock_fetch_prices_error)
        
        # Execute handler
        response = lambda_handler(event, None)
        
        # Verify error response
        assert response['statusCode'] == 502
        
        import json
        body = json.loads(response['body'])
        assert 'Failed to fetch prices from external API' in body['message']
        assert 'error' in body
        assert 'timestamp' in body
    
    def test_handler_dynamodb_save_failure(self, monkeypatch, aws_credentials, environment_variables):
        """
        Test handler when DynamoDB save operation fails.
        
        This tests the error handling when price data is fetched successfully
        but cannot be saved to DynamoDB.
        
        Requirements: 3.2
        """
        from src.update.handler import lambda_handler
        from src.shared.models import CryptoPrice
        from datetime import datetime, timezone
        
        # Mock EventBridge event
        event = {
            'version': '0',
            'id': 'test-event-id',
            'detail-type': 'Scheduled Event',
            'source': 'aws.events',
            'time': '2024-01-15T10:30:00Z',
            'detail': {}
        }
        
        # Mock successful API response
        mock_prices = [
            CryptoPrice(
                symbol='BTC',
                name='Bitcoin',
                price=45000.50,
                change24h=2.5,
                market_cap=850000000000,
                last_updated=datetime.now(timezone.utc)
            )
        ]
        
        # Mock ExternalAPIClient.fetch_prices
        def mock_fetch_prices(self, symbols):
            return mock_prices
        
        # Mock DynamoDBClient.save_multiple_price_data to fail
        def mock_save_multiple_price_data_fail(self, prices, ttl_seconds=3600):
            return False
        
        # Apply mocks
        from src.shared import external_api, db
        monkeypatch.setattr(external_api.ExternalAPIClient, 'fetch_prices', mock_fetch_prices)
        monkeypatch.setattr(db.DynamoDBClient, 'save_multiple_price_data', mock_save_multiple_price_data_fail)
        
        # Execute handler
        response = lambda_handler(event, None)
        
        # Verify error response
        assert response['statusCode'] == 500
        
        import json
        body = json.loads(response['body'])
        assert 'Failed to save prices to DynamoDB' in body['message']
        assert 'timestamp' in body
    
    def test_handler_unexpected_exception(self, monkeypatch, aws_credentials, environment_variables):
        """
        Test handler when an unexpected exception occurs.
        
        This tests the catch-all error handling for unexpected errors.
        
        Requirements: 3.4
        """
        from src.update.handler import lambda_handler
        
        # Mock EventBridge event
        event = {
            'version': '0',
            'id': 'test-event-id',
            'detail-type': 'Scheduled Event',
            'source': 'aws.events',
            'time': '2024-01-15T10:30:00Z',
            'detail': {}
        }
        
        # Mock ExternalAPIClient.fetch_prices to raise unexpected error
        def mock_fetch_prices_unexpected(self, symbols):
            raise RuntimeError('Unexpected error occurred')
        
        # Apply mock
        from src.shared import external_api
        monkeypatch.setattr(external_api.ExternalAPIClient, 'fetch_prices', mock_fetch_prices_unexpected)
        
        # Execute handler
        response = lambda_handler(event, None)
        
        # Verify error response
        assert response['statusCode'] == 500
        
        import json
        body = json.loads(response['body'])
        assert 'Unexpected error during price update' in body['message']
        assert 'error' in body
        assert 'timestamp' in body
    
    def test_get_supported_symbols_from_environment(self, monkeypatch):
        """
        Test that supported symbols are correctly parsed from environment variable.
        """
        from src.update.handler import get_supported_symbols
        
        # Test with custom symbols
        monkeypatch.setenv('SUPPORTED_SYMBOLS', 'BTC,ETH,ADA')
        symbols = get_supported_symbols()
        assert symbols == ['BTC', 'ETH', 'ADA']
        
        # Test with whitespace
        monkeypatch.setenv('SUPPORTED_SYMBOLS', 'BTC, ETH , ADA ')
        symbols = get_supported_symbols()
        assert symbols == ['BTC', 'ETH', 'ADA']
        
        # Test with default value (when not set)
        monkeypatch.delenv('SUPPORTED_SYMBOLS', raising=False)
        symbols = get_supported_symbols()
        assert 'BTC' in symbols
        assert 'ETH' in symbols
        assert len(symbols) >= 20  # Should have at least 20 symbols
    
    def test_handler_logs_success_metrics(self, monkeypatch, aws_credentials, environment_variables, caplog):
        """
        Test that handler logs success metrics correctly.
        
        Requirements: 3.2, 3.5
        """
        from src.update.handler import lambda_handler
        from src.shared.models import CryptoPrice
        from datetime import datetime, timezone
        import logging
        
        # Set log level to capture INFO logs
        caplog.set_level(logging.INFO)
        
        # Mock EventBridge event
        event = {
            'version': '0',
            'id': 'test-event-id',
            'detail-type': 'Scheduled Event',
            'source': 'aws.events',
            'time': '2024-01-15T10:30:00Z',
            'detail': {}
        }
        
        # Mock successful API response
        mock_prices = [
            CryptoPrice(
                symbol='BTC',
                name='Bitcoin',
                price=45000.50,
                change24h=2.5,
                market_cap=850000000000,
                last_updated=datetime.now(timezone.utc)
            )
        ]
        
        # Mock methods
        def mock_fetch_prices(self, symbols):
            return mock_prices
        
        def mock_save_multiple_price_data(self, prices, ttl_seconds=3600):
            return True
        
        # Apply mocks
        from src.shared import external_api, db
        monkeypatch.setattr(external_api.ExternalAPIClient, 'fetch_prices', mock_fetch_prices)
        monkeypatch.setattr(db.DynamoDBClient, 'save_multiple_price_data', mock_save_multiple_price_data)
        
        # Execute handler
        response = lambda_handler(event, None)
        
        # Verify success
        assert response['statusCode'] == 200
        
        # Verify logs contain expected messages
        log_messages = [record.message for record in caplog.records]
        
        # Check for key log messages
        assert any('Price update started' in msg for msg in log_messages)
        assert any('Fetching prices' in msg for msg in log_messages)
        assert any('Successfully fetched prices from external API' in msg for msg in log_messages)
        assert any('Price update completed successfully' in msg for msg in log_messages)
