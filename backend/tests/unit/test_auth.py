"""
Unit tests for authentication and authorization.

Tests specific examples and edge cases for authentication logic.
"""

import pytest
from unittest.mock import Mock, patch
from datetime import datetime, timezone
import time

from src.shared.auth import AuthMiddleware, extract_api_key
from src.shared.models import APIKey, RateLimit
from src.shared.errors import AuthenticationError, RateLimitError


class TestAuthenticationValidation:
    """Unit tests for API key validation."""
    
    def test_valid_api_key_accepted(self):
        """
        Test that a valid and enabled API key is accepted.
        
        Requirements: 4.1
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create a valid, enabled API key
        api_key = "test_valid_key_12345"
        api_key_data = APIKey(
            key_id=api_key,
            name="Test API Key",
            created_at=datetime(2024, 1, 1, tzinfo=timezone.utc),
            enabled=True
        )
        
        # Configure mock to return the API key
        mock_db_client.get_api_key.return_value = api_key_data
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Validate the API key
        result = auth_middleware.validate_api_key(api_key)
        
        # Assertions
        assert result is not None, "Valid API key should return APIKey instance"
        assert isinstance(result, APIKey), "Result should be an APIKey instance"
        assert result.key_id == api_key, "Returned key_id should match input"
        assert result.enabled is True, "Returned key should be enabled"
        
        # Verify DB client was called correctly
        mock_db_client.get_api_key.assert_called_once_with(api_key)
    
    def test_invalid_api_key_rejected(self):
        """
        Test that an API key that doesn't exist in the database is rejected.
        
        Requirements: 4.1
        """
        # Create a mock DynamoDB client that returns None (key not found)
        mock_db_client = Mock()
        mock_db_client.get_api_key.return_value = None
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Try to validate a non-existent API key
        invalid_key = "nonexistent_key_12345"
        
        # Should raise AuthenticationError
        with pytest.raises(AuthenticationError) as exc_info:
            auth_middleware.validate_api_key(invalid_key)
        
        # Verify error message
        assert "invalid" in str(exc_info.value).lower(), \
            "Error message should mention 'invalid'"
        
        # Verify DB client was called
        mock_db_client.get_api_key.assert_called_once_with(invalid_key)
    
    def test_missing_api_key_rejected_none(self):
        """
        Test that a None API key is rejected as missing.
        
        Requirements: 4.1, 4.2
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Try to validate None API key
        with pytest.raises(AuthenticationError) as exc_info:
            auth_middleware.validate_api_key(None)
        
        # Verify error message
        assert "missing" in str(exc_info.value).lower(), \
            "Error message should mention 'missing'"
        
        # Verify DB client was NOT called for None key
        mock_db_client.get_api_key.assert_not_called()
    
    def test_missing_api_key_rejected_empty_string(self):
        """
        Test that an empty string API key is rejected as missing.
        
        Requirements: 4.1, 4.2
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Try to validate empty string API key
        with pytest.raises(AuthenticationError) as exc_info:
            auth_middleware.validate_api_key("")
        
        # Verify error message
        assert "missing" in str(exc_info.value).lower(), \
            "Error message should mention 'missing'"
        
        # Verify DB client was NOT called for empty key
        mock_db_client.get_api_key.assert_not_called()
    
    def test_disabled_api_key_rejected(self):
        """
        Test that a valid but disabled API key is rejected.
        
        Requirements: 4.1, 4.2
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create a valid but disabled API key
        api_key = "test_disabled_key_12345"
        api_key_data = APIKey(
            key_id=api_key,
            name="Disabled API Key",
            created_at=datetime(2024, 1, 1, tzinfo=timezone.utc),
            enabled=False
        )
        
        # Configure mock to return the disabled API key
        mock_db_client.get_api_key.return_value = api_key_data
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Try to validate the disabled API key
        with pytest.raises(AuthenticationError) as exc_info:
            auth_middleware.validate_api_key(api_key)
        
        # Verify error message
        assert "disabled" in str(exc_info.value).lower(), \
            "Error message should mention 'disabled'"
        
        # Verify DB client was called
        mock_db_client.get_api_key.assert_called_once_with(api_key)


class TestAPIKeyExtraction:
    """Unit tests for API key extraction from request headers."""
    
    def test_extract_api_key_standard_header(self):
        """
        Test extracting API key from standard X-API-Key header.
        
        Requirements: 4.1
        """
        api_key = "test_key_12345"
        event = {
            'headers': {
                'X-API-Key': api_key
            }
        }
        
        extracted = extract_api_key(event)
        
        assert extracted == api_key, "Should extract API key from X-API-Key header"
    
    def test_extract_api_key_lowercase_header(self):
        """
        Test extracting API key from lowercase x-api-key header.
        
        Requirements: 4.1
        """
        api_key = "test_key_12345"
        event = {
            'headers': {
                'x-api-key': api_key
            }
        }
        
        extracted = extract_api_key(event)
        
        assert extracted == api_key, "Should extract API key from x-api-key header"
    
    def test_extract_api_key_mixed_case_header(self):
        """
        Test extracting API key from mixed case X-Api-Key header.
        
        Requirements: 4.1
        """
        api_key = "test_key_12345"
        event = {
            'headers': {
                'X-Api-Key': api_key
            }
        }
        
        extracted = extract_api_key(event)
        
        assert extracted == api_key, "Should extract API key from X-Api-Key header"
    
    def test_extract_api_key_missing_header(self):
        """
        Test that extraction returns None when API key header is missing.
        
        Requirements: 4.1
        """
        event = {
            'headers': {
                'Content-Type': 'application/json',
                'User-Agent': 'Test Client'
            }
        }
        
        extracted = extract_api_key(event)
        
        assert extracted is None, "Should return None when API key header is missing"
    
    def test_extract_api_key_empty_headers(self):
        """
        Test that extraction returns None when headers dict is empty.
        
        Requirements: 4.1
        """
        event = {
            'headers': {}
        }
        
        extracted = extract_api_key(event)
        
        assert extracted is None, "Should return None when headers are empty"
    
    def test_extract_api_key_no_headers(self):
        """
        Test that extraction returns None when headers key is missing from event.
        
        Requirements: 4.1
        """
        event = {}
        
        extracted = extract_api_key(event)
        
        assert extracted is None, "Should return None when headers key is missing"


class TestAuthenticateRequest:
    """Unit tests for the full authentication flow."""
    
    def test_authenticate_request_success(self):
        """
        Test successful authentication with valid API key and within rate limit.
        
        Requirements: 4.1
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create a valid, enabled API key
        api_key = "test_valid_key_12345"
        api_key_data = APIKey(
            key_id=api_key,
            name="Test API Key",
            created_at=datetime(2024, 1, 1, tzinfo=timezone.utc),
            enabled=True
        )
        
        # Configure mocks
        mock_db_client.get_api_key.return_value = api_key_data
        mock_db_client.get_rate_limit.return_value = None  # No existing rate limit
        mock_db_client.save_rate_limit.return_value = True
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Authenticate request
        result, _ = auth_middleware.authenticate_request(api_key)
        
        # Assertions
        assert result is not None, "Should return APIKey instance"
        assert isinstance(result, APIKey), "Result should be an APIKey instance"
        assert result.key_id == api_key, "Returned key_id should match input"
        
        # Verify both validation and rate limit check were called
        mock_db_client.get_api_key.assert_called_once()
        mock_db_client.get_rate_limit.assert_called_once()
        mock_db_client.save_rate_limit.assert_called_once()
    
    def test_authenticate_request_invalid_key(self):
        """
        Test that authentication fails for invalid API key.
        
        Requirements: 4.1, 4.2
        """
        # Create a mock DynamoDB client that returns None (key not found)
        mock_db_client = Mock()
        mock_db_client.get_api_key.return_value = None
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Try to authenticate with invalid key
        invalid_key = "invalid_key_12345"
        
        # Should raise AuthenticationError
        with pytest.raises(AuthenticationError):
            auth_middleware.authenticate_request(invalid_key)
        
        # Verify rate limit check was NOT called for invalid key
        mock_db_client.get_rate_limit.assert_not_called()
        mock_db_client.save_rate_limit.assert_not_called()
    
    def test_authenticate_request_missing_key(self):
        """
        Test that authentication fails for missing API key.
        
        Requirements: 4.1, 4.2
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Try to authenticate with None key
        with pytest.raises(AuthenticationError):
            auth_middleware.authenticate_request(None)
        
        # Verify DB was not called
        mock_db_client.get_api_key.assert_not_called()
        mock_db_client.get_rate_limit.assert_not_called()
        mock_db_client.save_rate_limit.assert_not_called()
    
    def test_authenticate_request_disabled_key(self):
        """
        Test that authentication fails for disabled API key.
        
        Requirements: 4.1, 4.2
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create a disabled API key
        api_key = "test_disabled_key_12345"
        api_key_data = APIKey(
            key_id=api_key,
            name="Disabled API Key",
            created_at=datetime(2024, 1, 1, tzinfo=timezone.utc),
            enabled=False
        )
        
        # Configure mock
        mock_db_client.get_api_key.return_value = api_key_data
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Try to authenticate with disabled key
        with pytest.raises(AuthenticationError):
            auth_middleware.authenticate_request(api_key)
        
        # Verify rate limit check was NOT called for disabled key
        mock_db_client.get_rate_limit.assert_not_called()
        mock_db_client.save_rate_limit.assert_not_called()
    
    def test_authenticate_request_rate_limit_exceeded(self):
        """
        Test that authentication fails when rate limit is exceeded.
        
        Requirements: 4.1
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create a valid, enabled API key
        api_key = "test_valid_key_12345"
        api_key_data = APIKey(
            key_id=api_key,
            name="Test API Key",
            created_at=datetime(2024, 1, 1, tzinfo=timezone.utc),
            enabled=True
        )
        
        # Create rate limit data at the limit
        current_minute = datetime.utcnow().strftime('%Y%m%d%H%M')
        ttl = int(time.time()) + 3600
        rate_limit_data = RateLimit(
            api_key=api_key,
            minute=current_minute,
            request_count=100,  # At the limit
            ttl=ttl
        )
        
        # Configure mocks
        mock_db_client.get_api_key.return_value = api_key_data
        mock_db_client.get_rate_limit.return_value = rate_limit_data
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Try to authenticate - should fail due to rate limit
        with pytest.raises(RateLimitError) as exc_info:
            auth_middleware.authenticate_request(api_key)
        
        # Verify error details
        assert exc_info.value.retry_after == 60, "Should have retry_after = 60"
        
        # Verify API key validation was called
        mock_db_client.get_api_key.assert_called_once()
        
        # Verify rate limit check was called
        mock_db_client.get_rate_limit.assert_called_once()
        
        # Verify save was NOT called (no increment when limit exceeded)
        mock_db_client.save_rate_limit.assert_not_called()


class TestRateLimiting:
    """Unit tests for rate limiting logic."""
    
    def test_requests_within_limit_accepted(self):
        """
        Test that requests within the rate limit are accepted.
        
        Requirements: 4.3
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create a valid, enabled API key
        api_key = "test_valid_key_12345"
        
        # Create rate limit data with count below limit (50 out of 100)
        current_minute = datetime.utcnow().strftime('%Y%m%d%H%M')
        ttl = int(time.time()) + 3600
        rate_limit_data = RateLimit(
            api_key=api_key,
            minute=current_minute,
            request_count=50,
            ttl=ttl
        )
        
        # Configure mock to return existing rate limit data
        mock_db_client.get_rate_limit.return_value = rate_limit_data
        mock_db_client.save_rate_limit.return_value = True
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Check rate limit - should not raise exception
        auth_middleware.check_rate_limit(api_key)
        
        # Verify rate limit was checked
        mock_db_client.get_rate_limit.assert_called_once_with(api_key, current_minute)
        
        # Verify rate limit was saved with incremented count
        mock_db_client.save_rate_limit.assert_called_once()
        saved_rate_limit = mock_db_client.save_rate_limit.call_args[0][0]
        assert saved_rate_limit.request_count == 51, \
            "Request count should be incremented from 50 to 51"
    
    def test_requests_exceeding_limit_rejected(self):
        """
        Test that requests exceeding the rate limit are rejected.
        
        Requirements: 4.3, 4.4
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create a valid API key
        api_key = "test_valid_key_12345"
        
        # Create rate limit data at the limit (100 requests)
        current_minute = datetime.utcnow().strftime('%Y%m%d%H%M')
        ttl = int(time.time()) + 3600
        rate_limit_data = RateLimit(
            api_key=api_key,
            minute=current_minute,
            request_count=100,
            ttl=ttl
        )
        
        # Configure mock to return rate limit at the limit
        mock_db_client.get_rate_limit.return_value = rate_limit_data
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Check rate limit - should raise RateLimitError
        with pytest.raises(RateLimitError) as exc_info:
            auth_middleware.check_rate_limit(api_key)
        
        # Verify error details
        assert exc_info.value.retry_after == 60, \
            "Should have retry_after = 60 seconds"
        
        # Verify rate limit was checked
        mock_db_client.get_rate_limit.assert_called_once_with(api_key, current_minute)
        
        # Verify rate limit was NOT saved (no increment when limit exceeded)
        mock_db_client.save_rate_limit.assert_not_called()
    
    def test_requests_exceeding_limit_rejected_above_100(self):
        """
        Test that requests are rejected when count is above the limit.
        
        This tests the edge case where request_count > 100.
        
        Requirements: 4.3, 4.4
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create a valid API key
        api_key = "test_valid_key_12345"
        
        # Create rate limit data above the limit (105 requests)
        current_minute = datetime.utcnow().strftime('%Y%m%d%H%M')
        ttl = int(time.time()) + 3600
        rate_limit_data = RateLimit(
            api_key=api_key,
            minute=current_minute,
            request_count=105,
            ttl=ttl
        )
        
        # Configure mock to return rate limit above the limit
        mock_db_client.get_rate_limit.return_value = rate_limit_data
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Check rate limit - should raise RateLimitError
        with pytest.raises(RateLimitError) as exc_info:
            auth_middleware.check_rate_limit(api_key)
        
        # Verify error details
        assert exc_info.value.retry_after == 60, \
            "Should have retry_after = 60 seconds"
        
        # Verify save was not called
        mock_db_client.save_rate_limit.assert_not_called()
    
    def test_rate_limit_window_reset(self):
        """
        Test that rate limit resets when moving to a new time window.
        
        When a new minute starts, the rate limit counter should start fresh.
        
        Requirements: 4.3, 4.4
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create a valid API key
        api_key = "test_valid_key_12345"
        
        # Configure mock to return None (no existing rate limit for new minute)
        mock_db_client.get_rate_limit.return_value = None
        mock_db_client.save_rate_limit.return_value = True
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Get current minute
        current_minute = datetime.utcnow().strftime('%Y%m%d%H%M')
        
        # Check rate limit - should not raise exception
        auth_middleware.check_rate_limit(api_key)
        
        # Verify rate limit was checked for current minute
        mock_db_client.get_rate_limit.assert_called_once_with(api_key, current_minute)
        
        # Verify a new rate limit entry was created with count = 1
        mock_db_client.save_rate_limit.assert_called_once()
        saved_rate_limit = mock_db_client.save_rate_limit.call_args[0][0]
        assert saved_rate_limit.request_count == 1, \
            "New rate limit window should start with count = 1"
        assert saved_rate_limit.api_key == api_key, \
            "Rate limit should be associated with the API key"
        assert saved_rate_limit.minute == current_minute, \
            "Rate limit should be for the current minute"
        assert saved_rate_limit.ttl > int(time.time()), \
            "TTL should be set to a future time"
    
    def test_first_request_in_window(self):
        """
        Test that the first request in a new window is accepted.
        
        Requirements: 4.3
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create a valid API key
        api_key = "test_first_request_key"
        
        # Configure mock to return None (no existing rate limit)
        mock_db_client.get_rate_limit.return_value = None
        mock_db_client.save_rate_limit.return_value = True
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Check rate limit - should not raise exception
        auth_middleware.check_rate_limit(api_key)
        
        # Verify rate limit was saved with count = 1
        mock_db_client.save_rate_limit.assert_called_once()
        saved_rate_limit = mock_db_client.save_rate_limit.call_args[0][0]
        assert saved_rate_limit.request_count == 1, \
            "First request should have count = 1"
    
    def test_request_at_99_accepted(self):
        """
        Test that the 100th request (count at 99, incremented to 100) is accepted.
        
        This tests the boundary condition where we're just at the limit.
        
        Requirements: 4.3
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create a valid API key
        api_key = "test_boundary_key"
        
        # Create rate limit data at 99 requests
        current_minute = datetime.utcnow().strftime('%Y%m%d%H%M')
        ttl = int(time.time()) + 3600
        rate_limit_data = RateLimit(
            api_key=api_key,
            minute=current_minute,
            request_count=99,
            ttl=ttl
        )
        
        # Configure mock
        mock_db_client.get_rate_limit.return_value = rate_limit_data
        mock_db_client.save_rate_limit.return_value = True
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Check rate limit - should not raise exception (99 < 100)
        auth_middleware.check_rate_limit(api_key)
        
        # Verify rate limit was saved with count = 100
        mock_db_client.save_rate_limit.assert_called_once()
        saved_rate_limit = mock_db_client.save_rate_limit.call_args[0][0]
        assert saved_rate_limit.request_count == 100, \
            "Request count should be incremented from 99 to 100"


class TestAuthenticationEdgeCases:
    """Unit tests for edge cases in authentication."""
    
    def test_whitespace_only_api_key(self):
        """
        Test that API keys consisting only of whitespace are rejected.
        
        Note: Whitespace-only keys are passed to DB lookup and fail as invalid.
        
        Requirements: 4.1, 4.2
        """
        # Create a mock DynamoDB client that returns None (key not found)
        mock_db_client = Mock()
        mock_db_client.get_api_key.return_value = None
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Try to validate whitespace-only key
        whitespace_key = "   \t\n  "
        
        # Should raise AuthenticationError
        with pytest.raises(AuthenticationError):
            auth_middleware.validate_api_key(whitespace_key)
        
        # Verify DB client was called (whitespace keys are looked up)
        mock_db_client.get_api_key.assert_called_once_with(whitespace_key)
    
    def test_very_long_api_key(self):
        """
        Test that very long API keys are handled correctly.
        
        Requirements: 4.1
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create a very long API key (1000 characters)
        long_key = "a" * 1000
        api_key_data = APIKey(
            key_id=long_key,
            name="Long API Key",
            created_at=datetime(2024, 1, 1, tzinfo=timezone.utc),
            enabled=True
        )
        
        # Configure mock
        mock_db_client.get_api_key.return_value = api_key_data
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Validate the long API key
        result = auth_middleware.validate_api_key(long_key)
        
        # Should succeed
        assert result is not None, "Long API key should be accepted if valid"
        assert result.key_id == long_key, "Returned key_id should match input"
    
    def test_api_key_with_special_characters(self):
        """
        Test that API keys with special characters are handled correctly.
        
        Requirements: 4.1
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create an API key with special characters
        special_key = "test-key_123.456@example"
        api_key_data = APIKey(
            key_id=special_key,
            name="Special API Key",
            created_at=datetime(2024, 1, 1, tzinfo=timezone.utc),
            enabled=True
        )
        
        # Configure mock
        mock_db_client.get_api_key.return_value = api_key_data
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Validate the API key with special characters
        result = auth_middleware.validate_api_key(special_key)
        
        # Should succeed
        assert result is not None, "API key with special characters should be accepted if valid"
        assert result.key_id == special_key, "Returned key_id should match input"
