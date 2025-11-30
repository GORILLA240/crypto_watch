"""
Property-based tests for request logging.

Tests universal properties that should hold across all valid inputs.
"""

import pytest
import json
import logging
from hypothesis import given, strategies as st, settings
from unittest.mock import Mock, MagicMock, patch
from datetime import datetime, timezone
from src.shared.utils import log_request, mask_api_key


# Strategy for generating valid API key strings
valid_api_key_strategy = st.text(
    alphabet=st.characters(whitelist_categories=('Lu', 'Ll', 'Nd')),
    min_size=16,
    max_size=64
)

# Strategy for generating HTTP methods
http_method_strategy = st.sampled_from(['GET', 'POST', 'PUT', 'DELETE', 'PATCH'])

# Strategy for generating API paths
api_path_strategy = st.sampled_from([
    '/prices',
    '/prices/BTC',
    '/prices/ETH',
    '/health',
    '/prices?symbols=BTC,ETH'
])

# Strategy for generating request IDs
request_id_strategy = st.text(
    alphabet=st.characters(whitelist_categories=('Lu', 'Ll', 'Nd', 'Pd')),
    min_size=10,
    max_size=50
)

# Strategy for generating timestamps
timestamp_strategy = st.datetimes(
    min_value=datetime(2020, 1, 1),
    max_value=datetime(2030, 12, 31)
).map(lambda dt: dt.replace(tzinfo=timezone.utc))


@pytest.mark.property
class TestRequestLoggingProperties:
    """Property-based tests for request logging."""
    
    @settings(max_examples=100)
    @given(
        api_key=valid_api_key_strategy,
        http_method=http_method_strategy,
        path=api_path_strategy,
        request_id=request_id_strategy
    )
    def test_property_11_request_logging(
        self, api_key, http_method, path, request_id
    ):
        """
        Feature: crypto-watch-backend, Property 11: Request logging
        
        Property: For any received API request, the system must create a log entry 
        containing request details, timestamp, and API key identifier.
        
        This test verifies that:
        1. Every API request generates a log entry
        2. The log entry contains request details (method, path, requestId)
        3. The log entry contains a timestamp
        4. The log entry contains the API key identifier (masked)
        
        Validates: Requirements 4.5
        """
        # Create a mock logger
        mock_logger = Mock(spec=logging.Logger)
        
        # Create an API Gateway event
        event = {
            'httpMethod': http_method,
            'path': path,
            'requestContext': {
                'requestId': request_id
            },
            'headers': {
                'X-API-Key': api_key
            }
        }
        
        # Call log_request
        returned_request_id = log_request(mock_logger, event, api_key)
        
        # Property 1: log_request should call logger.info exactly once
        assert mock_logger.info.call_count == 1, \
            "log_request should call logger.info exactly once"
        
        # Property 2: The returned request ID should match the input
        assert returned_request_id == request_id, \
            "log_request should return the request ID from the event"
        
        # Get the logged message
        logged_message = mock_logger.info.call_args[0][0]
        
        # Property 3: The logged message should be valid JSON
        try:
            log_data = json.loads(logged_message)
        except json.JSONDecodeError:
            pytest.fail("Logged message should be valid JSON")
        
        # Property 4: The log entry must contain requestId
        assert 'requestId' in log_data, \
            "Log entry must contain 'requestId'"
        assert log_data['requestId'] == request_id, \
            "Log entry requestId should match the event requestId"
        
        # Property 5: The log entry must contain method
        assert 'method' in log_data, \
            "Log entry must contain 'method'"
        assert log_data['method'] == http_method, \
            "Log entry method should match the event httpMethod"
        
        # Property 6: The log entry must contain path
        assert 'path' in log_data, \
            "Log entry must contain 'path'"
        assert log_data['path'] == path, \
            "Log entry path should match the event path"
        
        # Property 7: The log entry must contain timestamp
        assert 'timestamp' in log_data, \
            "Log entry must contain 'timestamp'"
        
        # Verify timestamp is in ISO format
        try:
            datetime.fromisoformat(log_data['timestamp'].replace('Z', '+00:00'))
        except ValueError:
            pytest.fail("Timestamp should be in ISO format")
        
        # Property 8: The log entry must contain masked API key
        assert 'apiKey' in log_data, \
            "Log entry must contain 'apiKey'"
        
        # Verify the API key is masked
        masked_key = log_data['apiKey']
        assert '***' in masked_key, \
            "API key should be masked with '***'"
        assert masked_key != api_key, \
            "API key should not be logged in plain text"
        
        # Verify the masked key matches the expected format
        expected_masked = mask_api_key(api_key)
        assert masked_key == expected_masked, \
            f"Masked API key should match expected format: {expected_masked}"
    
    @settings(max_examples=100)
    @given(
        http_method=http_method_strategy,
        path=api_path_strategy,
        request_id=request_id_strategy
    )
    def test_request_logging_without_api_key(
        self, http_method, path, request_id
    ):
        """
        Property: Request logging should work even when no API key is provided.
        
        This handles cases like health check endpoints that don't require authentication.
        
        Validates: Requirements 4.5
        """
        # Create a mock logger
        mock_logger = Mock(spec=logging.Logger)
        
        # Create an API Gateway event without API key
        event = {
            'httpMethod': http_method,
            'path': path,
            'requestContext': {
                'requestId': request_id
            },
            'headers': {}
        }
        
        # Call log_request without API key
        returned_request_id = log_request(mock_logger, event, api_key=None)
        
        # Property 1: Should still log the request
        assert mock_logger.info.call_count == 1, \
            "log_request should call logger.info even without API key"
        
        # Property 2: The returned request ID should match
        assert returned_request_id == request_id, \
            "log_request should return the request ID"
        
        # Get the logged message
        logged_message = mock_logger.info.call_args[0][0]
        log_data = json.loads(logged_message)
        
        # Property 3: Should contain request details
        assert log_data['requestId'] == request_id
        assert log_data['method'] == http_method
        assert log_data['path'] == path
        assert 'timestamp' in log_data
        
        # Property 4: Should not contain apiKey field when no key provided
        # (or it should be None/absent)
        if 'apiKey' in log_data:
            assert log_data['apiKey'] is None or log_data['apiKey'] == '', \
                "apiKey should be None or empty when not provided"
    
    @settings(max_examples=100)
    @given(
        api_key=valid_api_key_strategy,
        http_method=http_method_strategy,
        path=api_path_strategy,
        request_id=request_id_strategy
    )
    def test_api_key_masking_consistency(
        self, api_key, http_method, path, request_id
    ):
        """
        Property: The same API key should always be masked in the same way.
        
        Validates: Requirements 4.5
        """
        # Create a mock logger
        mock_logger = Mock(spec=logging.Logger)
        
        # Create an API Gateway event
        event = {
            'httpMethod': http_method,
            'path': path,
            'requestContext': {
                'requestId': request_id
            }
        }
        
        # Call log_request multiple times with the same API key
        log_request(mock_logger, event, api_key)
        first_call_message = mock_logger.info.call_args[0][0]
        first_log_data = json.loads(first_call_message)
        first_masked_key = first_log_data['apiKey']
        
        # Reset mock
        mock_logger.reset_mock()
        
        # Call again with the same API key
        log_request(mock_logger, event, api_key)
        second_call_message = mock_logger.info.call_args[0][0]
        second_log_data = json.loads(second_call_message)
        second_masked_key = second_log_data['apiKey']
        
        # Property: The masked key should be identical
        assert first_masked_key == second_masked_key, \
            "The same API key should always be masked in the same way"
    
    @settings(max_examples=100)
    @given(
        api_key=valid_api_key_strategy
    )
    def test_api_key_masking_preserves_prefix(self, api_key):
        """
        Property: API key masking should preserve a prefix for identification
        while hiding the rest.
        
        Validates: Requirements 4.5
        """
        masked = mask_api_key(api_key)
        
        # Property 1: Masked key should contain '***'
        assert '***' in masked, \
            "Masked API key should contain '***'"
        
        # Property 2: Masked key should not be the full original key
        assert masked != api_key, \
            "Masked key should not be the full original key"
        
        # Property 3: For keys longer than 7 characters, should preserve first 7 chars
        if len(api_key) > 7:
            assert masked.startswith(api_key[:7]), \
                "Masked key should preserve first 7 characters for keys longer than 7"
            assert masked == f"{api_key[:7]}***", \
                "Masked key should be in format 'prefix***'"
        else:
            # For short keys, should use generic masking
            assert masked == 'key_***', \
                "Short keys should be masked as 'key_***'"
    
    @settings(max_examples=100)
    @given(
        api_key=valid_api_key_strategy,
        http_method=http_method_strategy,
        path=api_path_strategy
    )
    def test_request_logging_handles_missing_request_id(
        self, api_key, http_method, path
    ):
        """
        Property: Request logging should handle events without a requestId gracefully.
        
        Validates: Requirements 4.5
        """
        # Create a mock logger
        mock_logger = Mock(spec=logging.Logger)
        
        # Create an API Gateway event without requestId
        event = {
            'httpMethod': http_method,
            'path': path,
            'requestContext': {},  # No requestId
            'headers': {
                'X-API-Key': api_key
            }
        }
        
        # Call log_request
        returned_request_id = log_request(mock_logger, event, api_key)
        
        # Property 1: Should still log the request
        assert mock_logger.info.call_count == 1, \
            "log_request should call logger.info even without requestId"
        
        # Property 2: Should return a default value (e.g., 'unknown')
        assert returned_request_id == 'unknown', \
            "log_request should return 'unknown' when requestId is missing"
        
        # Get the logged message
        logged_message = mock_logger.info.call_args[0][0]
        log_data = json.loads(logged_message)
        
        # Property 3: Log entry should contain 'unknown' as requestId
        assert log_data['requestId'] == 'unknown', \
            "Log entry should contain 'unknown' as requestId when missing"
    
    @settings(max_examples=100)
    @given(
        api_key=valid_api_key_strategy,
        request_id=request_id_strategy
    )
    def test_request_logging_handles_missing_method_and_path(
        self, api_key, request_id
    ):
        """
        Property: Request logging should handle events with missing method or path.
        
        Validates: Requirements 4.5
        """
        # Create a mock logger
        mock_logger = Mock(spec=logging.Logger)
        
        # Create an API Gateway event with minimal data
        event = {
            'requestContext': {
                'requestId': request_id
            }
        }
        
        # Call log_request
        returned_request_id = log_request(mock_logger, event, api_key)
        
        # Property 1: Should still log the request
        assert mock_logger.info.call_count == 1, \
            "log_request should call logger.info even with missing fields"
        
        # Property 2: Should return the request ID
        assert returned_request_id == request_id, \
            "log_request should return the request ID"
        
        # Get the logged message
        logged_message = mock_logger.info.call_args[0][0]
        log_data = json.loads(logged_message)
        
        # Property 3: Log entry should contain requestId
        assert log_data['requestId'] == request_id
        
        # Property 4: Log entry should handle missing fields gracefully
        # (either None or not present)
        assert 'method' in log_data  # Should be present but may be None
        assert 'path' in log_data  # Should be present but may be None
    
    @settings(max_examples=100)
    @given(
        api_key_1=valid_api_key_strategy,
        api_key_2=valid_api_key_strategy,
        http_method=http_method_strategy,
        path=api_path_strategy,
        request_id=request_id_strategy
    )
    def test_different_api_keys_produce_different_masked_values(
        self, api_key_1, api_key_2, http_method, path, request_id
    ):
        """
        Property: Different API keys should produce different masked values
        (unless they happen to have the same prefix).
        
        Validates: Requirements 4.5
        """
        # Skip if keys are identical
        if api_key_1 == api_key_2:
            return
        
        # Create a mock logger
        mock_logger = Mock(spec=logging.Logger)
        
        # Create an API Gateway event
        event = {
            'httpMethod': http_method,
            'path': path,
            'requestContext': {
                'requestId': request_id
            }
        }
        
        # Log with first API key
        log_request(mock_logger, event, api_key_1)
        first_message = mock_logger.info.call_args[0][0]
        first_log_data = json.loads(first_message)
        first_masked = first_log_data['apiKey']
        
        # Reset mock
        mock_logger.reset_mock()
        
        # Log with second API key
        log_request(mock_logger, event, api_key_2)
        second_message = mock_logger.info.call_args[0][0]
        second_log_data = json.loads(second_message)
        second_masked = second_log_data['apiKey']
        
        # Property: If the keys have different prefixes, masked values should differ
        if len(api_key_1) > 7 and len(api_key_2) > 7:
            if api_key_1[:7] != api_key_2[:7]:
                assert first_masked != second_masked, \
                    "Different API keys with different prefixes should produce different masked values"
    
    @settings(max_examples=100)
    @given(
        api_key=valid_api_key_strategy,
        http_method=http_method_strategy,
        path=api_path_strategy,
        request_id=request_id_strategy
    )
    def test_log_entry_is_structured_json(
        self, api_key, http_method, path, request_id
    ):
        """
        Property: All log entries should be structured JSON that can be parsed
        and queried by log aggregation systems.
        
        Validates: Requirements 4.5
        """
        # Create a mock logger
        mock_logger = Mock(spec=logging.Logger)
        
        # Create an API Gateway event
        event = {
            'httpMethod': http_method,
            'path': path,
            'requestContext': {
                'requestId': request_id
            }
        }
        
        # Call log_request
        log_request(mock_logger, event, api_key)
        
        # Get the logged message
        logged_message = mock_logger.info.call_args[0][0]
        
        # Property 1: Should be valid JSON
        try:
            log_data = json.loads(logged_message)
        except json.JSONDecodeError as e:
            pytest.fail(f"Logged message should be valid JSON: {e}")
        
        # Property 2: Should be a dictionary (JSON object)
        assert isinstance(log_data, dict), \
            "Log entry should be a JSON object (dictionary)"
        
        # Property 3: All required fields should be present
        required_fields = ['requestId', 'method', 'path', 'timestamp']
        for field in required_fields:
            assert field in log_data, \
                f"Log entry should contain required field: {field}"
        
        # Property 4: All values should be JSON-serializable types
        for key, value in log_data.items():
            assert isinstance(value, (str, int, float, bool, type(None), list, dict)), \
                f"Log entry field '{key}' should be a JSON-serializable type"
