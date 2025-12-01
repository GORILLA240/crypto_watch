"""
Unit tests for error handling.

Tests validation errors, internal errors, and error response format consistency.

Requirements: 6.1, 6.2, 6.5
"""

import pytest
import json
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime
import sys
import os

from src.shared.errors import (
    ValidationError,
    AuthenticationError,
    RateLimitError,
    ExternalAPIError,
    DatabaseError,
    CryptoWatchError,
    format_error_response
)


class TestValidationErrorResponses:
    """
    Unit tests for validation error responses.
    
    Requirements: 6.1
    """
    
    def test_validation_error_creates_400_response(self):
        """
        Test that ValidationError creates a 400 Bad Request response.
        
        Requirements: 6.1
        """
        # Create a validation error
        error = ValidationError('Missing required parameter: symbols')
        
        # Format error response
        response = format_error_response(error, 'test-request-id-001')
        
        # Verify response
        assert response['statusCode'] == 400, "Should return 400 for validation error"
        
        body = response['body']
        assert 'error' in body, "Response should contain error field"
        assert 'code' in body, "Response should contain code field"
        assert body['code'] == 'VALIDATION_ERROR', "Error code should be VALIDATION_ERROR"
        assert 'missing' in body['error'].lower(), "Error message should mention 'missing'"
    
    def test_validation_error_with_empty_parameter(self):
        """
        Test validation error for empty parameter.
        
        Requirements: 6.1
        """
        # Create a validation error for empty parameter
        error = ValidationError('symbols parameter cannot be empty')
        
        # Format error response
        response = format_error_response(error, 'test-request-id-002')
        
        # Verify response
        assert response['statusCode'] == 400, "Should return 400 for empty parameter"
        
        body = response['body']
        assert body['code'] == 'VALIDATION_ERROR', "Error code should be VALIDATION_ERROR"
        assert 'empty' in body['error'].lower(), "Error message should mention 'empty'"
    
    def test_validation_error_with_unsupported_symbols(self):
        """
        Test validation error for unsupported cryptocurrency symbols.
        
        Requirements: 6.1
        """
        # Create a validation error with details about unsupported symbols
        error = ValidationError(
            'Unsupported cryptocurrency symbols: INVALID, FAKE',
            details={
                'unsupportedSymbols': ['INVALID', 'FAKE'],
                'supportedSymbols': ['BTC', 'ETH', 'ADA']
            }
        )
        
        # Format error response
        response = format_error_response(error, 'test-request-id-003')
        
        # Verify response
        assert response['statusCode'] == 400, "Should return 400 for unsupported symbols"
        
        body = response['body']
        assert body['code'] == 'VALIDATION_ERROR', "Error code should be VALIDATION_ERROR"
        assert 'unsupported' in body['error'].lower(), "Error message should mention 'unsupported'"
        assert 'details' in body, "Response should contain details field"
        assert 'unsupportedSymbols' in body['details'], "Details should list unsupported symbols"
        assert body['details']['unsupportedSymbols'] == ['INVALID', 'FAKE']
    
    def test_validation_error_includes_error_details(self):
        """
        Test that validation errors include detailed error information.
        
        Requirements: 6.1
        """
        # Create a validation error with details
        error = ValidationError(
            'Invalid request parameters',
            details={
                'field': 'symbols',
                'reason': 'must not be empty'
            }
        )
        
        # Format error response
        response = format_error_response(error, 'test-request-id')
        
        # Verify response structure
        assert response['statusCode'] == 400, "Validation error should return 400"
        assert 'body' in response, "Response should have body"
        
        body = response['body']
        assert 'error' in body, "Body should contain error message"
        assert 'code' in body, "Body should contain error code"
        assert body['code'] == 'VALIDATION_ERROR', "Code should be VALIDATION_ERROR"
        assert 'details' in body, "Body should contain details"
        assert body['details']['field'] == 'symbols', "Details should include field"
        assert body['details']['reason'] == 'must not be empty', "Details should include reason"


class TestInternalErrorResponses:
    """
    Unit tests for internal error responses.
    
    Requirements: 6.2
    """
    
    def test_unexpected_exception_returns_500(self):
        """
        Test that unexpected exceptions return 500 Internal Server Error.
        
        Requirements: 6.2
        """
        # Create a generic unexpected exception
        error = RuntimeError('Unexpected error in processing')
        
        # Format error response
        response = format_error_response(error, 'test-request-id-004')
        
        # Verify response
        assert response['statusCode'] == 500, "Should return 500 for unexpected errors"
        
        body = response['body']
        assert 'error' in body, "Response should contain error field"
        assert 'code' in body, "Response should contain code field"
        assert body['code'] == 'INTERNAL_ERROR', "Error code should be INTERNAL_ERROR"
        assert body['error'] == 'Internal server error', "Should use generic error message"
    
    def test_internal_error_does_not_expose_sensitive_details(self):
        """
        Test that internal errors don't expose sensitive information.
        
        Requirements: 6.2
        """
        # Create a generic exception with sensitive information
        try:
            raise RuntimeError('Database connection failed: password=secret123')
        except RuntimeError as e:
            # Format error response
            response = format_error_response(e, 'test-request-id')
            
            # Verify response
            assert response['statusCode'] == 500, "Should return 500 for internal errors"
            
            body = response['body']
            assert 'error' in body, "Body should contain error message"
            assert body['error'] == 'Internal server error', "Should use generic error message"
            assert 'password' not in str(body), "Should not expose sensitive information"
            assert 'secret123' not in str(body), "Should not expose sensitive information"
    
    def test_database_error_returns_500(self):
        """
        Test that database errors return 500 Internal Server Error.
        
        Requirements: 6.2
        """
        # Create a database error
        error = DatabaseError(
            'Failed to query DynamoDB',
            details={'table': 'crypto-watch-data'}
        )
        
        # Format error response
        response = format_error_response(error, 'test-request-id')
        
        # Verify response
        assert response['statusCode'] == 500, "Database error should return 500"
        
        body = response['body']
        assert body['code'] == 'DATABASE_ERROR', "Code should be DATABASE_ERROR"
        assert 'error' in body, "Body should contain error message"
    
    def test_internal_error_includes_request_id(self):
        """
        Test that internal errors include request ID for tracking.
        
        Requirements: 6.2
        """
        # Create a generic exception
        error = RuntimeError('Something went wrong')
        request_id = 'test-request-id-12345'
        
        # Format error response
        response = format_error_response(error, request_id)
        
        # Verify response
        body = response['body']
        assert 'requestId' in body, "Body should contain requestId"
        assert body['requestId'] == request_id, "RequestId should match input"
    
    def test_internal_error_includes_timestamp(self):
        """
        Test that internal errors include timestamp.
        
        Requirements: 6.2
        """
        # Create a generic exception
        error = RuntimeError('Something went wrong')
        
        # Format error response
        response = format_error_response(error, 'test-request-id')
        
        # Verify response
        body = response['body']
        assert 'timestamp' in body, "Body should contain timestamp"
        assert body['timestamp'].endswith('Z'), "Timestamp should be in ISO 8601 format with Z"
        
        # Verify timestamp is valid ISO 8601
        try:
            datetime.fromisoformat(body['timestamp'].replace('Z', '+00:00'))
        except ValueError:
            pytest.fail("Timestamp should be valid ISO 8601 format")


class TestErrorResponseFormatConsistency:
    """
    Unit tests for error response format consistency.
    
    Requirements: 6.5
    """
    
    def test_validation_error_format_consistency(self):
        """
        Test that validation errors follow consistent format.
        
        Requirements: 6.5
        """
        error = ValidationError('Invalid input')
        response = format_error_response(error, 'test-request-id')
        
        # Verify consistent structure
        assert 'statusCode' in response, "Response should have statusCode"
        assert 'headers' in response, "Response should have headers"
        assert 'body' in response, "Response should have body"
        
        body = response['body']
        assert 'error' in body, "Body should have error field"
        assert 'code' in body, "Body should have code field"
        assert 'timestamp' in body, "Body should have timestamp field"
        assert 'requestId' in body, "Body should have requestId field"
        
        # Verify headers
        headers = response['headers']
        assert headers['Content-Type'] == 'application/json', "Content-Type should be application/json"
        assert 'Access-Control-Allow-Origin' in headers, "Should have CORS header"
    
    def test_authentication_error_format_consistency(self):
        """
        Test that authentication errors follow consistent format.
        
        Requirements: 6.5
        """
        error = AuthenticationError('Invalid API key')
        response = format_error_response(error, 'test-request-id')
        
        # Verify consistent structure
        body = response['body']
        assert 'error' in body, "Body should have error field"
        assert 'code' in body, "Body should have code field"
        assert 'timestamp' in body, "Body should have timestamp field"
        assert 'requestId' in body, "Body should have requestId field"
        assert body['code'] == 'UNAUTHORIZED', "Code should be UNAUTHORIZED"
        assert response['statusCode'] == 401, "Status code should be 401"
    
    def test_rate_limit_error_format_consistency(self):
        """
        Test that rate limit errors follow consistent format with retryAfter.
        
        Requirements: 6.5
        """
        error = RateLimitError(retry_after=60)
        response = format_error_response(error, 'test-request-id')
        
        # Verify consistent structure
        body = response['body']
        assert 'error' in body, "Body should have error field"
        assert 'code' in body, "Body should have code field"
        assert 'timestamp' in body, "Body should have timestamp field"
        assert 'requestId' in body, "Body should have requestId field"
        assert 'retryAfter' in body, "Body should have retryAfter field for rate limit errors"
        assert body['retryAfter'] == 60, "retryAfter should be 60 seconds"
        assert body['code'] == 'RATE_LIMIT_EXCEEDED', "Code should be RATE_LIMIT_EXCEEDED"
        assert response['statusCode'] == 429, "Status code should be 429"
    
    def test_external_api_error_format_consistency(self):
        """
        Test that external API errors follow consistent format.
        
        Requirements: 6.5
        """
        error = ExternalAPIError(
            'Failed to fetch prices',
            details={'attempts': 4}
        )
        response = format_error_response(error, 'test-request-id')
        
        # Verify consistent structure
        body = response['body']
        assert 'error' in body, "Body should have error field"
        assert 'code' in body, "Body should have code field"
        assert 'timestamp' in body, "Body should have timestamp field"
        assert 'requestId' in body, "Body should have requestId field"
        assert 'details' in body, "Body should have details field"
        assert body['code'] == 'EXTERNAL_API_ERROR', "Code should be EXTERNAL_API_ERROR"
        assert response['statusCode'] == 502, "Status code should be 502"
    
    def test_all_error_types_have_required_fields(self):
        """
        Test that all error types include required fields.
        
        Requirements: 6.5
        """
        # Test various error types
        errors = [
            ValidationError('Validation failed'),
            AuthenticationError('Auth failed'),
            RateLimitError(60),
            ExternalAPIError('API failed'),
            DatabaseError('DB failed'),
            RuntimeError('Unexpected error')
        ]
        
        required_fields = ['error', 'code', 'timestamp', 'requestId']
        
        for error in errors:
            response = format_error_response(error, 'test-request-id')
            body = response['body']
            
            for field in required_fields:
                assert field in body, f"{error.__class__.__name__} should have {field} field"
    
    def test_error_response_json_serializable(self):
        """
        Test that all error responses are JSON serializable.
        
        Requirements: 6.5
        """
        errors = [
            ValidationError('Validation failed', details={'field': 'symbols'}),
            AuthenticationError('Auth failed'),
            RateLimitError(60),
            ExternalAPIError('API failed', details={'attempts': 4}),
            DatabaseError('DB failed'),
            RuntimeError('Unexpected error')
        ]
        
        for error in errors:
            response = format_error_response(error, 'test-request-id')
            body = response['body']
            
            # Should be able to serialize to JSON
            try:
                json_str = json.dumps(body)
                # Should be able to deserialize back
                parsed = json.loads(json_str)
                assert parsed == body, f"{error.__class__.__name__} should round-trip through JSON"
            except (TypeError, ValueError) as e:
                pytest.fail(f"{error.__class__.__name__} response not JSON serializable: {e}")
    
    def test_error_response_headers_consistent(self):
        """
        Test that all error responses have consistent headers.
        
        Requirements: 6.5
        """
        errors = [
            ValidationError('Validation failed'),
            AuthenticationError('Auth failed'),
            RateLimitError(60),
            ExternalAPIError('API failed'),
            DatabaseError('DB failed'),
            RuntimeError('Unexpected error')
        ]
        
        for error in errors:
            response = format_error_response(error, 'test-request-id')
            headers = response['headers']
            
            assert 'Content-Type' in headers, f"{error.__class__.__name__} should have Content-Type header"
            assert headers['Content-Type'] == 'application/json', "Content-Type should be application/json"
            assert 'Access-Control-Allow-Origin' in headers, f"{error.__class__.__name__} should have CORS header"
    
    def test_error_code_matches_error_type(self):
        """
        Test that error codes match their error types.
        
        Requirements: 6.5
        """
        test_cases = [
            (ValidationError('Test'), 'VALIDATION_ERROR', 400),
            (AuthenticationError('Test'), 'UNAUTHORIZED', 401),
            (RateLimitError(60), 'RATE_LIMIT_EXCEEDED', 429),
            (ExternalAPIError('Test'), 'EXTERNAL_API_ERROR', 502),
            (DatabaseError('Test'), 'DATABASE_ERROR', 500),
            (RuntimeError('Test'), 'INTERNAL_ERROR', 500)
        ]
        
        for error, expected_code, expected_status in test_cases:
            response = format_error_response(error, 'test-request-id')
            body = response['body']
            
            assert body['code'] == expected_code, \
                f"{error.__class__.__name__} should have code {expected_code}"
            assert response['statusCode'] == expected_status, \
                f"{error.__class__.__name__} should have status code {expected_status}"
    
    def test_error_message_is_string(self):
        """
        Test that error messages are always strings.
        
        Requirements: 6.5
        """
        errors = [
            ValidationError('Validation failed'),
            AuthenticationError('Auth failed'),
            RateLimitError(60),
            ExternalAPIError('API failed'),
            DatabaseError('DB failed'),
            RuntimeError('Unexpected error')
        ]
        
        for error in errors:
            response = format_error_response(error, 'test-request-id')
            body = response['body']
            
            assert isinstance(body['error'], str), \
                f"{error.__class__.__name__} error message should be a string"
            assert len(body['error']) > 0, \
                f"{error.__class__.__name__} error message should not be empty"
    
    def test_timestamp_format_consistent(self):
        """
        Test that timestamps follow consistent ISO 8601 format.
        
        Requirements: 6.5
        """
        errors = [
            ValidationError('Test'),
            AuthenticationError('Test'),
            RateLimitError(60),
            ExternalAPIError('Test'),
            DatabaseError('Test'),
            RuntimeError('Test')
        ]
        
        for error in errors:
            response = format_error_response(error, 'test-request-id')
            body = response['body']
            
            timestamp = body['timestamp']
            
            # Should end with 'Z' for UTC
            assert timestamp.endswith('Z'), \
                f"{error.__class__.__name__} timestamp should end with 'Z'"
            
            # Should be valid ISO 8601
            try:
                datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
            except ValueError:
                pytest.fail(f"{error.__class__.__name__} timestamp not valid ISO 8601: {timestamp}")


class TestErrorHandlingIntegration:
    """
    Integration tests for error handling with error formatting.
    
    Requirements: 6.1, 6.2, 6.5
    """
    
    def test_authentication_error_response_format(self):
        """
        Test that authentication errors produce properly formatted responses.
        
        Requirements: 6.1, 6.5
        """
        # Create authentication error
        error = AuthenticationError('Invalid API key')
        
        # Format error response
        response = format_error_response(error, 'test-request-id-005')
        
        # Verify response
        assert response['statusCode'] == 401, "Should return 401 for authentication error"
        
        body = response['body']
        assert body['code'] == 'UNAUTHORIZED', "Error code should be UNAUTHORIZED"
        assert 'error' in body, "Response should contain error message"
        assert 'timestamp' in body, "Response should contain timestamp"
        assert 'requestId' in body, "Response should contain requestId"
        assert body['requestId'] == 'test-request-id-005'
    
    def test_rate_limit_error_response_format(self):
        """
        Test that rate limit errors produce properly formatted responses.
        
        Requirements: 6.1, 6.5
        """
        # Create rate limit error
        error = RateLimitError(retry_after=60)
        
        # Format error response
        response = format_error_response(error, 'test-request-id-006')
        
        # Verify response
        assert response['statusCode'] == 429, "Should return 429 for rate limit error"
        
        body = response['body']
        assert body['code'] == 'RATE_LIMIT_EXCEEDED', "Error code should be RATE_LIMIT_EXCEEDED"
        assert 'retryAfter' in body, "Response should contain retryAfter"
        assert body['retryAfter'] == 60, "retryAfter should be 60 seconds"
        assert 'error' in body, "Response should contain error message"
        assert 'timestamp' in body, "Response should contain timestamp"
        assert 'requestId' in body, "Response should contain requestId"
    
    def test_multiple_validation_errors_same_format(self):
        """
        Test that multiple validation errors all follow the same format.
        
        Requirements: 6.1, 6.5
        """
        errors = [
            ValidationError('Missing required parameter'),
            ValidationError('Empty parameter value'),
            ValidationError('Unsupported symbol')
        ]
        
        for i, error in enumerate(errors):
            response = format_error_response(error, f'test-request-id-{i}')
            
            # All should have same status code
            assert response['statusCode'] == 400, f"Error {i} should return 400"
            
            # All should have same structure
            body = response['body']
            assert 'error' in body, f"Error {i} should have error field"
            assert 'code' in body, f"Error {i} should have code field"
            assert 'timestamp' in body, f"Error {i} should have timestamp field"
            assert 'requestId' in body, f"Error {i} should have requestId field"
            assert body['code'] == 'VALIDATION_ERROR', f"Error {i} should have VALIDATION_ERROR code"
