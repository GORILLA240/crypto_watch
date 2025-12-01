"""
Property-based tests for error logging.

Tests universal properties that should hold across all valid inputs.
"""

import pytest
import json
import logging
import traceback
from hypothesis import given, strategies as st, settings
from unittest.mock import Mock, MagicMock, patch
from datetime import datetime, timezone
from src.shared.utils import log_error
from src.shared.errors import (
    ValidationError,
    AuthenticationError,
    RateLimitError,
    ExternalAPIError,
    DatabaseError,
    CryptoWatchError
)


# Strategy for generating error messages
error_message_strategy = st.text(
    alphabet=st.characters(whitelist_categories=('Lu', 'Ll', 'Nd', 'P', 'Z')),
    min_size=1,
    max_size=200
)

# Strategy for generating request IDs
request_id_strategy = st.text(
    alphabet=st.characters(whitelist_categories=('Lu', 'Ll', 'Nd', 'Pd')),
    min_size=10,
    max_size=50
)

# Strategy for generating error types
error_type_strategy = st.sampled_from([
    ValidationError,
    AuthenticationError,
    RateLimitError,
    ExternalAPIError,
    DatabaseError
])

# Strategy for generating generic exceptions
generic_exception_strategy = st.sampled_from([
    ValueError,
    TypeError,
    KeyError,
    AttributeError,
    RuntimeError
])

# Strategy for generating additional context (simplified for performance)
context_strategy = st.dictionaries(
    keys=st.sampled_from(['userId', 'endpoint', 'statusCode', 'duration', 'retryCount']),
    values=st.one_of(
        st.text(alphabet='abcdefghijklmnopqrstuvwxyz', min_size=1, max_size=20),
        st.integers(min_value=0, max_value=1000),
        st.booleans()
    ),
    min_size=0,
    max_size=3
)


@pytest.mark.property
class TestErrorLoggingProperties:
    """Property-based tests for error logging."""
    
    @settings(max_examples=100)
    @given(
        error_message=error_message_strategy,
        request_id=request_id_strategy
    )
    def test_property_12_error_logging_with_details(
        self, error_message, request_id
    ):
        """
        Feature: crypto-watch-backend, Property 12: Error logging with details
        
        Property: For any error that occurs during request processing, the system 
        must log detailed error information including error type, message, and 
        stack trace.
        
        This test verifies that:
        1. Every error generates a log entry
        2. The log entry contains the error message
        3. The log entry contains the error type
        4. The log entry contains a stack trace
        5. The log entry contains a timestamp
        6. The log entry contains the request ID (if provided)
        
        Validates: Requirements 5.2
        """
        # Create a mock logger
        mock_logger = Mock(spec=logging.Logger)
        
        # Create an exception
        try:
            raise ValidationError(error_message)
        except ValidationError as e:
            error = e
        
        # Call log_error
        log_error(mock_logger, error, request_id)
        
        # Property 1: log_error should call logger.error exactly once
        assert mock_logger.error.call_count == 1, \
            "log_error should call logger.error exactly once"
        
        # Get the logged message
        logged_message = mock_logger.error.call_args[0][0]
        
        # Property 2: The logged message should be valid JSON
        try:
            log_data = json.loads(logged_message)
        except json.JSONDecodeError:
            pytest.fail("Logged error message should be valid JSON")
        
        # Property 3: The log entry must contain 'error' field with the error message
        assert 'error' in log_data, \
            "Log entry must contain 'error' field"
        assert error_message in log_data['error'], \
            "Log entry error field should contain the error message"
        
        # Property 4: The log entry must contain 'errorType' field
        assert 'errorType' in log_data, \
            "Log entry must contain 'errorType' field"
        assert log_data['errorType'] == 'ValidationError', \
            "Log entry errorType should match the exception type"
        
        # Property 5: The log entry must contain 'stackTrace' field
        assert 'stackTrace' in log_data, \
            "Log entry must contain 'stackTrace' field"
        assert isinstance(log_data['stackTrace'], str), \
            "Stack trace should be a string"
        assert len(log_data['stackTrace']) > 0, \
            "Stack trace should not be empty"
        
        # Property 6: The log entry must contain 'timestamp' field
        assert 'timestamp' in log_data, \
            "Log entry must contain 'timestamp' field"
        
        # Verify timestamp is in ISO format
        try:
            datetime.fromisoformat(log_data['timestamp'].replace('Z', '+00:00'))
        except ValueError:
            pytest.fail("Timestamp should be in ISO format")
        
        # Property 7: The log entry must contain 'level' field
        assert 'level' in log_data, \
            "Log entry must contain 'level' field"
        assert log_data['level'] == 'ERROR', \
            "Log entry level should be 'ERROR'"
        
        # Property 8: The log entry must contain 'requestId' when provided
        assert 'requestId' in log_data, \
            "Log entry must contain 'requestId' when provided"
        assert log_data['requestId'] == request_id, \
            "Log entry requestId should match the provided request ID"
    
    @settings(max_examples=100)
    @given(
        error_message=error_message_strategy,
        request_id=request_id_strategy,
        additional_context=context_strategy
    )
    def test_error_logging_with_additional_context(
        self, error_message, request_id, additional_context
    ):
        """
        Property: Error logging should include any additional context provided.
        
        Validates: Requirements 5.2
        """
        # Create a mock logger
        mock_logger = Mock(spec=logging.Logger)
        
        # Create an exception
        try:
            raise DatabaseError(error_message)
        except DatabaseError as e:
            error = e
        
        # Call log_error with additional context
        log_error(mock_logger, error, request_id, **additional_context)
        
        # Get the logged message
        logged_message = mock_logger.error.call_args[0][0]
        log_data = json.loads(logged_message)
        
        # Property: All additional context should be included in the log entry
        for key, value in additional_context.items():
            assert key in log_data, \
                f"Log entry should contain additional context key: {key}"
            assert log_data[key] == value, \
                f"Log entry should contain correct value for context key: {key}"
    
    @settings(max_examples=100)
    @given(
        error_message=error_message_strategy
    )
    def test_error_logging_without_request_id(self, error_message):
        """
        Property: Error logging should work even when no request ID is provided.
        
        Validates: Requirements 5.2
        """
        # Create a mock logger
        mock_logger = Mock(spec=logging.Logger)
        
        # Create an exception
        try:
            raise ExternalAPIError(error_message)
        except ExternalAPIError as e:
            error = e
        
        # Call log_error without request ID
        log_error(mock_logger, error, request_id=None)
        
        # Property 1: Should still log the error
        assert mock_logger.error.call_count == 1, \
            "log_error should call logger.error even without request ID"
        
        # Get the logged message
        logged_message = mock_logger.error.call_args[0][0]
        log_data = json.loads(logged_message)
        
        # Property 2: Should contain all required fields except requestId
        assert 'error' in log_data
        assert 'errorType' in log_data
        assert 'stackTrace' in log_data
        assert 'timestamp' in log_data
        assert 'level' in log_data
        
        # Property 3: requestId should not be present or should be None
        if 'requestId' in log_data:
            assert log_data['requestId'] is None, \
                "requestId should be None when not provided"
    
    @settings(max_examples=100)
    @given(
        error_message=error_message_strategy,
        request_id=request_id_strategy,
        error_type=error_type_strategy
    )
    def test_different_error_types_logged_correctly(
        self, error_message, request_id, error_type
    ):
        """
        Property: Different error types should be logged with their correct type name.
        
        Validates: Requirements 5.2
        """
        # Create a mock logger
        mock_logger = Mock(spec=logging.Logger)
        
        # Create an exception of the specified type
        try:
            if error_type == ValidationError:
                raise ValidationError(error_message)
            elif error_type == AuthenticationError:
                raise AuthenticationError(error_message)
            elif error_type == RateLimitError:
                raise RateLimitError()
            elif error_type == ExternalAPIError:
                raise ExternalAPIError(error_message)
            elif error_type == DatabaseError:
                raise DatabaseError(error_message)
        except Exception as e:
            error = e
        
        # Call log_error
        log_error(mock_logger, error, request_id)
        
        # Get the logged message
        logged_message = mock_logger.error.call_args[0][0]
        log_data = json.loads(logged_message)
        
        # Property: The errorType should match the actual exception type
        expected_type_name = error_type.__name__
        assert log_data['errorType'] == expected_type_name, \
            f"Log entry errorType should be '{expected_type_name}'"
    
    @settings(max_examples=100)
    @given(
        error_message=error_message_strategy,
        request_id=request_id_strategy,
        exception_type=generic_exception_strategy
    )
    def test_generic_exceptions_logged_correctly(
        self, error_message, request_id, exception_type
    ):
        """
        Property: Generic Python exceptions should also be logged with full details.
        
        Validates: Requirements 5.2
        """
        # Create a mock logger
        mock_logger = Mock(spec=logging.Logger)
        
        # Create a generic exception
        try:
            raise exception_type(error_message)
        except Exception as e:
            error = e
        
        # Call log_error
        log_error(mock_logger, error, request_id)
        
        # Get the logged message
        logged_message = mock_logger.error.call_args[0][0]
        log_data = json.loads(logged_message)
        
        # Property 1: Should contain all required fields
        assert 'error' in log_data
        assert 'errorType' in log_data
        assert 'stackTrace' in log_data
        assert 'timestamp' in log_data
        assert 'requestId' in log_data
        
        # Property 2: errorType should match the exception type
        assert log_data['errorType'] == exception_type.__name__, \
            f"Log entry errorType should be '{exception_type.__name__}'"
    
    @settings(max_examples=100)
    @given(
        error_message=error_message_strategy,
        request_id=request_id_strategy
    )
    def test_stack_trace_contains_traceback_info(
        self, error_message, request_id
    ):
        """
        Property: Stack trace should contain meaningful traceback information.
        
        Validates: Requirements 5.2
        """
        # Create a mock logger
        mock_logger = Mock(spec=logging.Logger)
        
        # Create an exception and call log_error within the exception context
        # This ensures traceback.format_exc() captures the actual stack trace
        try:
            # Create a nested call to generate a more interesting stack trace
            def inner_function():
                raise ValidationError(error_message)
            
            def outer_function():
                inner_function()
            
            outer_function()
        except ValidationError as e:
            # Call log_error while still in the exception context
            log_error(mock_logger, e, request_id)
        
        # Get the logged message
        logged_message = mock_logger.error.call_args[0][0]
        log_data = json.loads(logged_message)
        
        stack_trace = log_data['stackTrace']
        
        # Property 1: Stack trace should not be empty
        assert len(stack_trace) > 0, \
            "Stack trace should not be empty"
        
        # Property 2: Stack trace should be a string
        assert isinstance(stack_trace, str), \
            "Stack trace should be a string"
        
        # Property 3: Stack trace should contain traceback information
        # When called in exception context, it should contain "Traceback" or the error type
        assert 'Traceback' in stack_trace or 'ValidationError' in stack_trace or 'Error' in stack_trace, \
            "Stack trace should contain traceback information"
    
    @settings(max_examples=100)
    @given(
        error_message=error_message_strategy,
        request_id=request_id_strategy
    )
    def test_log_entry_is_structured_json(
        self, error_message, request_id
    ):
        """
        Property: All error log entries should be structured JSON that can be 
        parsed and queried by log aggregation systems.
        
        Validates: Requirements 5.2
        """
        # Create a mock logger
        mock_logger = Mock(spec=logging.Logger)
        
        # Create an exception
        try:
            raise DatabaseError(error_message)
        except DatabaseError as e:
            error = e
        
        # Call log_error
        log_error(mock_logger, error, request_id)
        
        # Get the logged message
        logged_message = mock_logger.error.call_args[0][0]
        
        # Property 1: Should be valid JSON
        try:
            log_data = json.loads(logged_message)
        except json.JSONDecodeError as e:
            pytest.fail(f"Logged error message should be valid JSON: {e}")
        
        # Property 2: Should be a dictionary (JSON object)
        assert isinstance(log_data, dict), \
            "Log entry should be a JSON object (dictionary)"
        
        # Property 3: All required fields should be present
        required_fields = ['level', 'error', 'errorType', 'timestamp', 'stackTrace']
        for field in required_fields:
            assert field in log_data, \
                f"Log entry should contain required field: {field}"
        
        # Property 4: All values should be JSON-serializable types
        for key, value in log_data.items():
            assert isinstance(value, (str, int, float, bool, type(None), list, dict)), \
                f"Log entry field '{key}' should be a JSON-serializable type"
    
    @settings(max_examples=100, deadline=None)
    @given(
        error_message=error_message_strategy,
        request_id_1=request_id_strategy,
        request_id_2=request_id_strategy
    )
    def test_same_error_different_requests_logged_separately(
        self, error_message, request_id_1, request_id_2
    ):
        """
        Property: The same error occurring in different requests should be 
        logged with different request IDs.
        
        Validates: Requirements 5.2
        """
        # Skip if request IDs are identical
        if request_id_1 == request_id_2:
            return
        
        # Create a mock logger
        mock_logger = Mock(spec=logging.Logger)
        
        # Create an exception and log it within exception context
        try:
            raise ExternalAPIError(error_message)
        except ExternalAPIError as e:
            # Log with first request ID
            log_error(mock_logger, e, request_id_1)
        
        first_message = mock_logger.error.call_args[0][0]
        first_log_data = json.loads(first_message)
        
        # Reset mock
        mock_logger.reset_mock()
        
        # Create another exception and log it
        try:
            raise ExternalAPIError(error_message)
        except ExternalAPIError as e:
            # Log with second request ID
            log_error(mock_logger, e, request_id_2)
        
        second_message = mock_logger.error.call_args[0][0]
        second_log_data = json.loads(second_message)
        
        # Property: The request IDs should be different
        assert first_log_data['requestId'] == request_id_1, \
            "First log entry should have first request ID"
        assert second_log_data['requestId'] == request_id_2, \
            "Second log entry should have second request ID"
        assert first_log_data['requestId'] != second_log_data['requestId'], \
            "Different requests should have different request IDs in logs"
    
    @settings(max_examples=100)
    @given(
        error_message=error_message_strategy,
        request_id=request_id_strategy
    )
    def test_logger_error_called_with_exc_info(
        self, error_message, request_id
    ):
        """
        Property: log_error should call logger.error with exc_info=True to 
        capture full exception information.
        
        Validates: Requirements 5.2
        """
        # Create a mock logger
        mock_logger = Mock(spec=logging.Logger)
        
        # Create an exception
        try:
            raise ValidationError(error_message)
        except ValidationError as e:
            error = e
        
        # Call log_error
        log_error(mock_logger, error, request_id)
        
        # Property: logger.error should be called with exc_info=True
        call_kwargs = mock_logger.error.call_args[1]
        assert 'exc_info' in call_kwargs, \
            "logger.error should be called with exc_info parameter"
        assert call_kwargs['exc_info'] is True, \
            "logger.error should be called with exc_info=True"
    
    @settings(max_examples=100)
    @given(
        error_message=error_message_strategy,
        request_id=request_id_strategy
    )
    def test_timestamp_format_consistency(
        self, error_message, request_id
    ):
        """
        Property: All error log timestamps should use consistent ISO format.
        
        Validates: Requirements 5.2
        """
        # Create a mock logger
        mock_logger = Mock(spec=logging.Logger)
        
        # Create an exception
        try:
            raise DatabaseError(error_message)
        except DatabaseError as e:
            error = e
        
        # Call log_error
        log_error(mock_logger, error, request_id)
        
        # Get the logged message
        logged_message = mock_logger.error.call_args[0][0]
        log_data = json.loads(logged_message)
        
        timestamp = log_data['timestamp']
        
        # Property 1: Timestamp should end with 'Z' (UTC indicator)
        assert timestamp.endswith('Z'), \
            "Timestamp should end with 'Z' to indicate UTC"
        
        # Property 2: Timestamp should be parseable as ISO format
        try:
            parsed = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
            assert isinstance(parsed, datetime), \
                "Timestamp should be parseable as datetime"
        except ValueError as e:
            pytest.fail(f"Timestamp should be in valid ISO format: {e}")
        
        # Property 3: Timestamp should contain 'T' separator
        assert 'T' in timestamp, \
            "Timestamp should contain 'T' separator between date and time"
