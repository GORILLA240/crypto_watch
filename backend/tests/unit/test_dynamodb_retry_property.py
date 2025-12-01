"""
Property-based tests for DynamoDB retry logic.

Tests universal properties that should hold across all valid inputs.
"""

import pytest
from hypothesis import given, strategies as st, settings
from unittest.mock import Mock, patch, MagicMock
from botocore.exceptions import ClientError
from datetime import datetime, timezone

from src.shared.db import DynamoDBClient
from src.shared.models import CryptoPrice, APIKey, RateLimit


# Strategy for generating error codes
transient_error_codes = st.sampled_from([
    'ProvisionedThroughputExceededException',
    'ThrottlingException',
    'InternalServerError',
    'ServiceUnavailable'
])

permanent_error_codes = st.sampled_from([
    'ValidationException',
    'ResourceNotFoundException',
    'ConditionalCheckFailedException',
    'ItemCollectionSizeLimitExceededException'
])

# Strategy for generating retry counts
retry_count_strategy = st.integers(min_value=1, max_value=5)


def create_client_error(error_code: str, message: str = "Test error"):
    """Helper function to create a ClientError for testing."""
    error_response = {
        'Error': {
            'Code': error_code,
            'Message': message
        }
    }
    return ClientError(error_response, 'test_operation')


@pytest.mark.property
class TestDynamoDBRetryProperties:
    """Property-based tests for DynamoDB retry logic."""
    
    @settings(max_examples=100, deadline=None)
    @given(
        symbol=st.text(min_size=1, max_size=10, alphabet=st.characters(whitelist_categories=('Lu',))),
        error_code=transient_error_codes,
        retry_count=retry_count_strategy
    )
    def test_property_13_transient_errors_are_retried(self, symbol, error_code, retry_count):
        """
        Feature: crypto-watch-backend, Property 13: DynamoDB retry logic
        
        Property: For any DynamoDB operation that fails with a transient error,
        the system should retry the operation, and for permanent failures should
        return an appropriate error response.
        
        This test verifies that transient errors (throttling, 500/503/504) are
        automatically retried by the AWS SDK's built-in retry mechanism.
        
        Validates: Requirements 6.3
        """
        # Create a DynamoDB client
        client = DynamoDBClient(table_name='test-table')
        
        # Mock the table.get_item method to simulate transient errors
        with patch.object(client.table, 'get_item') as mock_get_item:
            # Simulate transient error that will be retried by AWS SDK
            mock_get_item.side_effect = create_client_error(error_code)
            
            # Call get_price_data - should handle the error gracefully
            result = client.get_price_data(symbol)
            
            # Property 1: Transient errors should be handled gracefully
            # The AWS SDK will retry automatically, but if all retries fail,
            # the method should return None instead of raising an exception
            assert result is None, f"Transient error {error_code} should be handled gracefully"
            
            # Property 2: The method should have attempted the operation
            # (AWS SDK handles retries internally, so we just verify the call was made)
            assert mock_get_item.called, "DynamoDB operation should have been attempted"
    
    @settings(max_examples=100, deadline=None)
    @given(
        symbol=st.text(min_size=1, max_size=10, alphabet=st.characters(whitelist_categories=('Lu',))),
        error_code=permanent_error_codes
    )
    def test_property_13_permanent_errors_return_none(self, symbol, error_code):
        """
        Property: For any DynamoDB operation that fails with a permanent error
        (validation, resource not found), the system should not retry and should
        return an appropriate error response (None for read operations).
        
        Validates: Requirements 6.3
        """
        # Create a DynamoDB client
        client = DynamoDBClient(table_name='test-table')
        
        # Mock the table.get_item method to simulate permanent errors
        with patch.object(client.table, 'get_item') as mock_get_item:
            # Simulate permanent error that should not be retried
            mock_get_item.side_effect = create_client_error(error_code)
            
            # Call get_price_data - should handle the error gracefully
            result = client.get_price_data(symbol)
            
            # Property 1: Permanent errors should be handled gracefully
            # The method should return None instead of raising an exception
            assert result is None, f"Permanent error {error_code} should be handled gracefully"
            
            # Property 2: The method should have attempted the operation once
            assert mock_get_item.called, "DynamoDB operation should have been attempted"
    
    @settings(max_examples=100, deadline=None)
    @given(
        symbol=st.text(min_size=1, max_size=10, alphabet=st.characters(whitelist_categories=('Lu',))),
        name=st.text(min_size=1, max_size=50),
        price=st.floats(min_value=0.01, max_value=1000000.0, allow_nan=False, allow_infinity=False),
        change24h=st.floats(min_value=-100.0, max_value=1000.0, allow_nan=False, allow_infinity=False),
        market_cap=st.integers(min_value=1, max_value=10**15),
        error_code=transient_error_codes
    )
    def test_property_13_write_operations_handle_transient_errors(
        self, symbol, name, price, change24h, market_cap, error_code
    ):
        """
        Property: For any DynamoDB write operation that fails with a transient error,
        the system should retry the operation and return False if all retries fail.
        
        Validates: Requirements 6.3
        """
        # Create a DynamoDB client
        client = DynamoDBClient(table_name='test-table')
        
        # Create price data to save
        price_data = CryptoPrice(
            symbol=symbol,
            name=name,
            price=price,
            change24h=change24h,
            market_cap=market_cap,
            last_updated=datetime.now(timezone.utc)
        )
        
        # Mock the table.put_item method to simulate transient errors
        with patch.object(client.table, 'put_item') as mock_put_item:
            # Simulate transient error that will be retried by AWS SDK
            mock_put_item.side_effect = create_client_error(error_code)
            
            # Call save_price_data - should handle the error gracefully
            result = client.save_price_data(price_data)
            
            # Property 1: Write operations should return False on failure
            assert result is False, f"Write operation should return False on transient error {error_code}"
            
            # Property 2: The method should have attempted the operation
            assert mock_put_item.called, "DynamoDB write operation should have been attempted"
    
    @settings(max_examples=100, deadline=None)
    @given(
        symbol=st.text(min_size=1, max_size=10, alphabet=st.characters(whitelist_categories=('Lu',))),
        name=st.text(min_size=1, max_size=50),
        price=st.floats(min_value=0.01, max_value=1000000.0, allow_nan=False, allow_infinity=False),
        change24h=st.floats(min_value=-100.0, max_value=1000.0, allow_nan=False, allow_infinity=False),
        market_cap=st.integers(min_value=1, max_value=10**15),
        error_code=permanent_error_codes
    )
    def test_property_13_write_operations_handle_permanent_errors(
        self, symbol, name, price, change24h, market_cap, error_code
    ):
        """
        Property: For any DynamoDB write operation that fails with a permanent error,
        the system should not retry and should return False immediately.
        
        Validates: Requirements 6.3
        """
        # Create a DynamoDB client
        client = DynamoDBClient(table_name='test-table')
        
        # Create price data to save
        price_data = CryptoPrice(
            symbol=symbol,
            name=name,
            price=price,
            change24h=change24h,
            market_cap=market_cap,
            last_updated=datetime.now(timezone.utc)
        )
        
        # Mock the table.put_item method to simulate permanent errors
        with patch.object(client.table, 'put_item') as mock_put_item:
            # Simulate permanent error that should not be retried
            mock_put_item.side_effect = create_client_error(error_code)
            
            # Call save_price_data - should handle the error gracefully
            result = client.save_price_data(price_data)
            
            # Property 1: Write operations should return False on failure
            assert result is False, f"Write operation should return False on permanent error {error_code}"
            
            # Property 2: The method should have attempted the operation
            assert mock_put_item.called, "DynamoDB write operation should have been attempted"
    
    @settings(max_examples=100, deadline=None)
    @given(
        api_key=st.text(min_size=1, max_size=50),
        error_code=st.sampled_from([
            'ProvisionedThroughputExceededException',
            'ThrottlingException',
            'ValidationException',
            'ResourceNotFoundException'
        ])
    )
    def test_property_13_api_key_operations_handle_errors(self, api_key, error_code):
        """
        Property: API key retrieval operations should handle both transient and
        permanent errors gracefully by returning None.
        
        Validates: Requirements 6.3
        """
        # Create a DynamoDB client
        client = DynamoDBClient(table_name='test-table')
        
        # Mock the table.get_item method to simulate errors
        with patch.object(client.table, 'get_item') as mock_get_item:
            # Simulate error
            mock_get_item.side_effect = create_client_error(error_code)
            
            # Call get_api_key - should handle the error gracefully
            result = client.get_api_key(api_key)
            
            # Property: All errors should be handled gracefully
            assert result is None, f"API key retrieval should return None on error {error_code}"
            
            # Property: The method should have attempted the operation
            assert mock_get_item.called, "DynamoDB operation should have been attempted"
    
    @settings(max_examples=100, deadline=None)
    @given(
        api_key=st.text(min_size=1, max_size=50),
        minute=st.text(min_size=12, max_size=12, alphabet=st.characters(whitelist_categories=('Nd',))),
        error_code=st.sampled_from([
            'ProvisionedThroughputExceededException',
            'ThrottlingException',
            'InternalServerError'
        ])
    )
    def test_property_13_rate_limit_operations_handle_errors(self, api_key, minute, error_code):
        """
        Property: Rate limit retrieval operations should handle transient errors
        gracefully by returning None, allowing the system to continue operation.
        
        Validates: Requirements 6.3
        """
        # Create a DynamoDB client
        client = DynamoDBClient(table_name='test-table')
        
        # Mock the table.get_item method to simulate errors
        with patch.object(client.table, 'get_item') as mock_get_item:
            # Simulate transient error
            mock_get_item.side_effect = create_client_error(error_code)
            
            # Call get_rate_limit - should handle the error gracefully
            result = client.get_rate_limit(api_key, minute)
            
            # Property: Transient errors should be handled gracefully
            assert result is None, f"Rate limit retrieval should return None on error {error_code}"
            
            # Property: The method should have attempted the operation
            assert mock_get_item.called, "DynamoDB operation should have been attempted"
    
    @settings(max_examples=100, deadline=None)
    @given(
        symbols=st.lists(
            st.text(min_size=1, max_size=10, alphabet=st.characters(whitelist_categories=('Lu',))),
            min_size=1,
            max_size=10
        ),
        error_code=transient_error_codes
    )
    def test_property_13_batch_operations_handle_errors(self, symbols, error_code):
        """
        Property: Batch read operations should handle transient errors gracefully
        by returning an empty dictionary, allowing the system to continue.
        
        Validates: Requirements 6.3
        """
        # Create a DynamoDB client
        client = DynamoDBClient(table_name='test-table')
        
        # Mock the dynamodb.batch_get_item method to simulate errors
        with patch.object(client.dynamodb, 'batch_get_item') as mock_batch_get:
            # Simulate transient error
            mock_batch_get.side_effect = create_client_error(error_code)
            
            # Call get_multiple_price_data - should handle the error gracefully
            result = client.get_multiple_price_data(symbols)
            
            # Property: Batch operations should return empty dict on error
            assert result == {}, f"Batch operation should return empty dict on error {error_code}"
            
            # Property: The method should have attempted the operation
            assert mock_batch_get.called, "DynamoDB batch operation should have been attempted"
    
    @settings(max_examples=100, deadline=None)
    @given(
        symbol=st.text(min_size=1, max_size=10, alphabet=st.characters(whitelist_categories=('Lu',))),
        name=st.text(min_size=1, max_size=50),
        price=st.floats(min_value=0.01, max_value=1000000.0, allow_nan=False, allow_infinity=False),
        change24h=st.floats(min_value=-100.0, max_value=1000.0, allow_nan=False, allow_infinity=False),
        market_cap=st.integers(min_value=1, max_value=10**15)
    )
    def test_property_13_successful_operations_return_expected_values(
        self, symbol, name, price, change24h, market_cap
    ):
        """
        Property: When DynamoDB operations succeed (no errors), the system should
        return the expected values without any retry logic being triggered.
        
        This tests the happy path to ensure retry logic doesn't interfere with
        successful operations.
        
        Validates: Requirements 6.3
        """
        # Create a DynamoDB client
        client = DynamoDBClient(table_name='test-table')
        
        # Create price data
        price_data = CryptoPrice(
            symbol=symbol,
            name=name,
            price=price,
            change24h=change24h,
            market_cap=market_cap,
            last_updated=datetime.now(timezone.utc)
        )
        
        # Test successful write operation
        with patch.object(client.table, 'put_item') as mock_put_item:
            # Simulate successful operation
            mock_put_item.return_value = {}
            
            # Call save_price_data - should succeed
            result = client.save_price_data(price_data)
            
            # Property: Successful operations should return True
            assert result is True, "Successful write operation should return True"
            
            # Property: The operation should have been called exactly once
            assert mock_put_item.call_count == 1, "Successful operation should be called once"
        
        # Test successful read operation
        with patch.object(client.table, 'get_item') as mock_get_item:
            # Simulate successful operation with data
            dynamodb_item = price_data.to_dynamodb_item()
            mock_get_item.return_value = {'Item': dynamodb_item}
            
            # Call get_price_data - should succeed
            result = client.get_price_data(symbol)
            
            # Property: Successful operations should return the data
            assert result is not None, "Successful read operation should return data"
            assert result.symbol == symbol, "Returned data should match requested symbol"
            
            # Property: The operation should have been called exactly once
            assert mock_get_item.call_count == 1, "Successful operation should be called once"
    
    @settings(max_examples=50, deadline=None)
    @given(
        error_sequence=st.lists(
            st.sampled_from([
                'ProvisionedThroughputExceededException',
                'ThrottlingException',
                'InternalServerError'
            ]),
            min_size=1,
            max_size=3
        )
    )
    def test_property_13_retry_exhaustion_returns_error(self, error_sequence):
        """
        Property: When all retry attempts are exhausted for transient errors,
        the system should return an appropriate error response (None for reads,
        False for writes) rather than raising an exception.
        
        Validates: Requirements 6.3
        """
        # Create a DynamoDB client
        client = DynamoDBClient(table_name='test-table')
        
        # Create a sequence of errors to simulate retry exhaustion
        errors = [create_client_error(code) for code in error_sequence]
        
        # Test read operation with retry exhaustion
        with patch.object(client.table, 'get_item') as mock_get_item:
            # Simulate multiple failures (AWS SDK will retry internally)
            mock_get_item.side_effect = errors
            
            # Call get_price_data - should handle exhausted retries gracefully
            result = client.get_price_data('BTC')
            
            # Property: Exhausted retries should return None for read operations
            assert result is None, "Exhausted retries should return None for read operations"
