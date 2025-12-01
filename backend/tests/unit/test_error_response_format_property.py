"""
Property-based tests for consistent error response format.

Tests universal properties that should hold across all valid inputs.
"""

import pytest
import json
from hypothesis import given, strategies as st, settings
from datetime import datetime
from src.shared.errors import (
    ValidationError,
    AuthenticationError,
    RateLimitError,
    ExternalAPIError,
    DatabaseError,
    CryptoWatchError,
    format_error_response
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
crypto_watch_error_strategy = st.sampled_from([
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
    RuntimeError,
    Exception
])

# Strategy for generating additional details
details_strategy = st.dictionaries(
    keys=st.sampled_from(['hint', 'field', 'value', 'reason', 'count']),
    values=st.one_of(
        st.text(alphabet='abcdefghijklmnopqrstuvwxyz', min_size=1, max_size=30),
        st.integers(min_value=0, max_value=1000),
        st.booleans()
    ),
    min_size=0,
    max_size=3
)


@pytest.mark.property
class TestErrorResponseFormatProperties:
    """Property-based tests for consistent error response format."""
    
    @settings(max_examples=100)
    @given(
        error_message=error_message_strategy,
        request_id=request_id_strategy
    )
    def test_property_15_consistent_error_response_format_validation_error(
        self, error_message, request_id
    ):
        """
        Feature: crypto-watch-backend, Property 15: Consistent error response format
        
        Property: For any error response from any endpoint, the response must follow 
        a consistent JSON structure with "error", "code", and optional additional fields.
        
        This test verifies that ValidationError responses have consistent format:
        1. Contains required fields: error, code, timestamp, requestId
        2. All fields have correct types
        3. Status code is appropriate for the error type
        4. Response is valid JSON
        5. Timestamp is in ISO 8601 format
        
        Validates: Requirements 6.5
        """
        # Create a ValidationError
        error = ValidationError(error_message)
        
        # Format the error response
        response = format_error_response(error, request_id)
        
        # Property 1: Response must have statusCode and body
        assert 'statusCode' in response, "Response must contain statusCode"
        assert 'body' in response, "Response must contain body"
        assert 'headers' in response, "Response must contain headers"
        
        # Property 2: Status code must be appropriate for ValidationError (400)
        assert response['statusCode'] == 400, \
            "ValidationError should have status code 400"
        
        # Property 3: Body must be a dictionary (not JSON string yet)
        body = response['body']
        assert isinstance(body, dict), "Response body should be a dictionary"
        
        # Property 4: Body must contain required fields
        required_fields = ['error', 'code', 'timestamp', 'requestId']
        for field in required_fields:
            assert field in body, f"Response body must contain '{field}' field"
        
        # Property 5: 'error' field must contain the error message
        assert body['error'] == error_message, \
            "Error field should contain the error message"
        
        # Property 6: 'code' field must be the error code constant
        assert body['code'] == 'VALIDATION_ERROR', \
            "Code field should be 'VALIDATION_ERROR' for ValidationError"
        
        # Property 7: 'timestamp' must be in ISO 8601 format with 'Z' suffix
        timestamp = body['timestamp']
        assert isinstance(timestamp, str), "Timestamp should be a string"
        assert timestamp.endswith('Z'), "Timestamp should end with 'Z' (UTC)"
        
        # Verify timestamp is parseable
        try:
            datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
        except ValueError:
            pytest.fail("Timestamp should be in valid ISO 8601 format")
        
        # Property 8: 'requestId' must match the provided request ID
        assert body['requestId'] == request_id, \
            "RequestId should match the provided request ID"
        
        # Property 9: Headers must include Content-Type
        assert 'Content-Type' in response['headers'], \
            "Response headers must include Content-Type"
        assert response['headers']['Content-Type'] == 'application/json', \
            "Content-Type should be application/json"
    
    @settings(max_examples=100)
    @given(
        request_id=request_id_strategy
    )
    def test_property_15_authentication_error_format(self, request_id):
        """
        Property: AuthenticationError responses must follow consistent format.
        
        Validates: Requirements 6.5
        """
        # Create an AuthenticationError
        error = AuthenticationError()
        
        # Format the error response
        response = format_error_response(error, request_id)
        
        # Property 1: Status code must be 401
        assert response['statusCode'] == 401, \
            "AuthenticationError should have status code 401"
        
        body = response['body']
        
        # Property 2: Must contain all required fields
        required_fields = ['error', 'code', 'timestamp', 'requestId']
        for field in required_fields:
            assert field in body, f"Response body must contain '{field}' field"
        
        # Property 3: Code must be UNAUTHORIZED
        assert body['code'] == 'UNAUTHORIZED', \
            "Code field should be 'UNAUTHORIZED' for AuthenticationError"
        
        # Property 4: Error message should be present
        assert isinstance(body['error'], str), "Error message should be a string"
        assert len(body['error']) > 0, "Error message should not be empty"
    
    @settings(max_examples=100)
    @given(
        request_id=request_id_strategy,
        retry_after=st.integers(min_value=1, max_value=300)
    )
    def test_property_15_rate_limit_error_format(self, request_id, retry_after):
        """
        Property: RateLimitError responses must include retryAfter field.
        
        Validates: Requirements 6.5
        """
        # Create a RateLimitError
        error = RateLimitError(retry_after=retry_after)
        
        # Format the error response
        response = format_error_response(error, request_id)
        
        # Property 1: Status code must be 429
        assert response['statusCode'] == 429, \
            "RateLimitError should have status code 429"
        
        body = response['body']
        
        # Property 2: Must contain all required fields
        required_fields = ['error', 'code', 'timestamp', 'requestId']
        for field in required_fields:
            assert field in body, f"Response body must contain '{field}' field"
        
        # Property 3: Code must be RATE_LIMIT_EXCEEDED
        assert body['code'] == 'RATE_LIMIT_EXCEEDED', \
            "Code field should be 'RATE_LIMIT_EXCEEDED' for RateLimitError"
        
        # Property 4: Must contain retryAfter field
        assert 'retryAfter' in body, \
            "RateLimitError response must contain 'retryAfter' field"
        assert body['retryAfter'] == retry_after, \
            "retryAfter should match the error's retry_after value"
    
    @settings(max_examples=100)
    @given(
        error_message=error_message_strategy,
        request_id=request_id_strategy
    )
    def test_property_15_external_api_error_format(self, error_message, request_id):
        """
        Property: ExternalAPIError responses must follow consistent format.
        
        Validates: Requirements 6.5
        """
        # Create an ExternalAPIError
        error = ExternalAPIError(error_message)
        
        # Format the error response
        response = format_error_response(error, request_id)
        
        # Property 1: Status code must be 502
        assert response['statusCode'] == 502, \
            "ExternalAPIError should have status code 502"
        
        body = response['body']
        
        # Property 2: Must contain all required fields
        required_fields = ['error', 'code', 'timestamp', 'requestId']
        for field in required_fields:
            assert field in body, f"Response body must contain '{field}' field"
        
        # Property 3: Code must be EXTERNAL_API_ERROR
        assert body['code'] == 'EXTERNAL_API_ERROR', \
            "Code field should be 'EXTERNAL_API_ERROR' for ExternalAPIError"
        
        # Property 4: Error message should match
        assert body['error'] == error_message, \
            "Error field should contain the error message"
    
    @settings(max_examples=100)
    @given(
        error_message=error_message_strategy,
        request_id=request_id_strategy
    )
    def test_property_15_database_error_format(self, error_message, request_id):
        """
        Property: DatabaseError responses must follow consistent format.
        
        Validates: Requirements 6.5
        """
        # Create a DatabaseError
        error = DatabaseError(error_message)
        
        # Format the error response
        response = format_error_response(error, request_id)
        
        # Property 1: Status code must be 500
        assert response['statusCode'] == 500, \
            "DatabaseError should have status code 500"
        
        body = response['body']
        
        # Property 2: Must contain all required fields
        required_fields = ['error', 'code', 'timestamp', 'requestId']
        for field in required_fields:
            assert field in body, f"Response body must contain '{field}' field"
        
        # Property 3: Code must be DATABASE_ERROR
        assert body['code'] == 'DATABASE_ERROR', \
            "Code field should be 'DATABASE_ERROR' for DatabaseError"
    
    @settings(max_examples=100)
    @given(
        error_message=error_message_strategy,
        request_id=request_id_strategy,
        exception_type=generic_exception_strategy
    )
    def test_property_15_generic_exception_format(
        self, error_message, request_id, exception_type
    ):
        """
        Property: Generic exceptions must be formatted with consistent structure
        and not expose internal details.
        
        Validates: Requirements 6.5
        """
        # Create a generic exception
        error = exception_type(error_message)
        
        # Format the error response
        response = format_error_response(error, request_id)
        
        # Property 1: Status code must be 500 for generic exceptions
        assert response['statusCode'] == 500, \
            "Generic exceptions should have status code 500"
        
        body = response['body']
        
        # Property 2: Must contain all required fields
        required_fields = ['error', 'code', 'timestamp', 'requestId']
        for field in required_fields:
            assert field in body, f"Response body must contain '{field}' field"
        
        # Property 3: Code must be INTERNAL_ERROR
        assert body['code'] == 'INTERNAL_ERROR', \
            "Code field should be 'INTERNAL_ERROR' for generic exceptions"
        
        # Property 4: Error message should NOT expose internal details
        assert body['error'] == 'Internal server error', \
            "Generic exceptions should not expose internal error messages"
        
        # Property 5: The response should use the generic message, not the original
        # (We check equality rather than substring to avoid false positives with short strings)
        assert body['error'] != error_message or error_message == 'Internal server error', \
            "Generic exceptions should use generic error message, not original message"
    
    @settings(max_examples=100)
    @given(
        error_message=error_message_strategy,
        request_id=request_id_strategy,
        details=details_strategy
    )
    def test_property_15_error_with_details(
        self, error_message, request_id, details
    ):
        """
        Property: Errors with additional details must include them in the response.
        
        Validates: Requirements 6.5
        """
        # Create an error with details
        error = ValidationError(error_message, details=details)
        
        # Format the error response
        response = format_error_response(error, request_id)
        
        body = response['body']
        
        # Property 1: If details were provided, they should be in the response
        if details:
            assert 'details' in body, \
                "Response should contain 'details' field when error has details"
            assert body['details'] == details, \
                "Details should match the error's details"
        
        # Property 2: All other required fields must still be present
        required_fields = ['error', 'code', 'timestamp', 'requestId']
        for field in required_fields:
            assert field in body, f"Response body must contain '{field}' field"
    
    @settings(max_examples=100)
    @given(
        error_message=error_message_strategy
    )
    def test_property_15_error_without_request_id(self, error_message):
        """
        Property: When no request ID is provided, a UUID should be generated.
        
        Validates: Requirements 6.5
        """
        # Create an error
        error = ValidationError(error_message)
        
        # Format the error response without request ID
        response = format_error_response(error, request_id=None)
        
        body = response['body']
        
        # Property 1: requestId should still be present
        assert 'requestId' in body, \
            "Response should contain requestId even when not provided"
        
        # Property 2: requestId should be a non-empty string (UUID)
        assert isinstance(body['requestId'], str), \
            "Generated requestId should be a string"
        assert len(body['requestId']) > 0, \
            "Generated requestId should not be empty"
        
        # Property 3: Should look like a UUID (contains hyphens)
        assert '-' in body['requestId'], \
            "Generated requestId should be a UUID format"
    
    @settings(max_examples=100)
    @given(
        error_type=crypto_watch_error_strategy,
        error_message=error_message_strategy,
        request_id=request_id_strategy
    )
    def test_property_15_all_error_types_have_consistent_structure(
        self, error_type, error_message, request_id
    ):
        """
        Property: All CryptoWatchError types must produce responses with 
        the same base structure.
        
        Validates: Requirements 6.5
        """
        # Create an error of the specified type
        if error_type == RateLimitError:
            error = error_type()
        else:
            error = error_type(error_message)
        
        # Format the error response
        response = format_error_response(error, request_id)
        
        # Property 1: All responses must have the same top-level structure
        assert 'statusCode' in response
        assert 'headers' in response
        assert 'body' in response
        
        # Property 2: All response bodies must have the same required fields
        body = response['body']
        required_fields = ['error', 'code', 'timestamp', 'requestId']
        for field in required_fields:
            assert field in body, \
                f"All error responses must contain '{field}' field"
        
        # Property 3: All field types must be consistent
        assert isinstance(body['error'], str), "error must be a string"
        assert isinstance(body['code'], str), "code must be a string"
        assert isinstance(body['timestamp'], str), "timestamp must be a string"
        assert isinstance(body['requestId'], str), "requestId must be a string"
        
        # Property 4: Timestamp format must be consistent
        assert body['timestamp'].endswith('Z'), \
            "All timestamps must end with 'Z'"
        assert 'T' in body['timestamp'], \
            "All timestamps must contain 'T' separator"
    
    @settings(max_examples=100)
    @given(
        error_message=error_message_strategy,
        request_id_1=request_id_strategy,
        request_id_2=request_id_strategy
    )
    def test_property_15_same_error_different_requests(
        self, error_message, request_id_1, request_id_2
    ):
        """
        Property: The same error in different requests should have different 
        request IDs but the same error structure.
        
        Validates: Requirements 6.5
        """
        # Skip if request IDs are identical
        if request_id_1 == request_id_2:
            return
        
        # Create the same error twice
        error1 = ValidationError(error_message)
        error2 = ValidationError(error_message)
        
        # Format with different request IDs
        response1 = format_error_response(error1, request_id_1)
        response2 = format_error_response(error2, request_id_2)
        
        body1 = response1['body']
        body2 = response2['body']
        
        # Property 1: Request IDs should be different
        assert body1['requestId'] == request_id_1
        assert body2['requestId'] == request_id_2
        assert body1['requestId'] != body2['requestId']
        
        # Property 2: Error messages should be the same
        assert body1['error'] == body2['error']
        
        # Property 3: Error codes should be the same
        assert body1['code'] == body2['code']
        
        # Property 4: Status codes should be the same
        assert response1['statusCode'] == response2['statusCode']
        
        # Property 5: Both should have the same structure
        assert set(body1.keys()) == set(body2.keys()), \
            "Same error type should produce same response structure"
    
    @settings(max_examples=100)
    @given(
        error_message=error_message_strategy,
        request_id=request_id_strategy
    )
    def test_property_15_response_is_json_serializable(
        self, error_message, request_id
    ):
        """
        Property: All error responses must be JSON serializable.
        
        Validates: Requirements 6.5
        """
        # Create an error
        error = ValidationError(error_message)
        
        # Format the error response
        response = format_error_response(error, request_id)
        
        body = response['body']
        
        # Property: Body should be JSON serializable
        try:
            json_str = json.dumps(body)
            assert isinstance(json_str, str), "JSON serialization should produce a string"
            
            # Verify it can be parsed back
            parsed = json.loads(json_str)
            assert parsed == body, "Parsed JSON should match original body"
            
        except (TypeError, ValueError) as e:
            pytest.fail(f"Error response body should be JSON serializable: {e}")
    
    @settings(max_examples=100)
    @given(
        error_message=error_message_strategy,
        request_id=request_id_strategy
    )
    def test_property_15_cors_headers_present(self, error_message, request_id):
        """
        Property: All error responses must include CORS headers.
        
        Validates: Requirements 6.5
        """
        # Create an error
        error = ValidationError(error_message)
        
        # Format the error response
        response = format_error_response(error, request_id)
        
        # Property: Headers must include CORS header
        assert 'Access-Control-Allow-Origin' in response['headers'], \
            "Error responses must include CORS header"
        assert response['headers']['Access-Control-Allow-Origin'] == '*', \
            "CORS header should allow all origins"
    
    @settings(max_examples=100)
    @given(
        error_type=crypto_watch_error_strategy,
        error_message=error_message_strategy,
        request_id=request_id_strategy
    )
    def test_property_15_status_code_matches_error_type(
        self, error_type, error_message, request_id
    ):
        """
        Property: Each error type must have its appropriate HTTP status code.
        
        Validates: Requirements 6.5
        """
        # Create an error of the specified type
        if error_type == RateLimitError:
            error = error_type()
        else:
            error = error_type(error_message)
        
        # Format the error response
        response = format_error_response(error, request_id)
        
        # Property: Status code must match the error type
        expected_status_codes = {
            ValidationError: 400,
            AuthenticationError: 401,
            RateLimitError: 429,
            ExternalAPIError: 502,
            DatabaseError: 500
        }
        
        expected_status = expected_status_codes[error_type]
        assert response['statusCode'] == expected_status, \
            f"{error_type.__name__} should have status code {expected_status}"
    
    @settings(max_examples=100)
    @given(
        error_message=error_message_strategy,
        request_id=request_id_strategy
    )
    def test_property_15_timestamp_is_recent(self, error_message, request_id):
        """
        Property: Error response timestamps should be recent (within a few seconds).
        
        Validates: Requirements 6.5
        """
        # Create an error
        error = ValidationError(error_message)
        
        # Get current time before formatting
        before = datetime.utcnow()
        
        # Format the error response
        response = format_error_response(error, request_id)
        
        # Get current time after formatting
        after = datetime.utcnow()
        
        body = response['body']
        timestamp_str = body['timestamp']
        
        # Parse the timestamp
        timestamp = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
        timestamp = timestamp.replace(tzinfo=None)  # Remove timezone for comparison
        
        # Property: Timestamp should be between before and after
        assert before <= timestamp <= after, \
            "Error response timestamp should be generated at the time of formatting"
