"""
Property-based tests for authentication and authorization.

Tests universal properties that should hold across all valid inputs.
"""

import pytest
from hypothesis import given, strategies as st, settings, assume
from datetime import datetime, timezone
from unittest.mock import Mock, MagicMock
from src.shared.auth import AuthMiddleware, extract_api_key
from src.shared.models import APIKey
from src.shared.errors import AuthenticationError, RateLimitError


# Strategy for generating valid API key strings
valid_api_key_strategy = st.text(
    alphabet=st.characters(whitelist_categories=('Lu', 'Ll', 'Nd')),
    min_size=16,
    max_size=64
)

# Strategy for generating API key names
api_key_name_strategy = st.text(
    alphabet=st.characters(whitelist_categories=('Lu', 'Ll', 'Nd', 'Zs')),
    min_size=1,
    max_size=50
).filter(lambda s: len(s.strip()) > 0)

# Strategy for generating timestamps
timestamp_strategy = st.datetimes(
    min_value=datetime(2020, 1, 1),
    max_value=datetime(2030, 12, 31)
).map(lambda dt: dt.replace(tzinfo=timezone.utc))

# Strategy for generating boolean values
enabled_strategy = st.booleans()


@pytest.mark.property
class TestAuthenticationProperties:
    """Property-based tests for authentication."""
    
    @settings(max_examples=100)
    @given(
        api_key=valid_api_key_strategy,
        name=api_key_name_strategy,
        created_at=timestamp_strategy,
        enabled=enabled_strategy
    )
    def test_property_9_authentication_requirement_valid_key(
        self, api_key, name, created_at, enabled
    ):
        """
        Feature: crypto-watch-backend, Property 9: Authentication requirement
        
        Property: For any API endpoint request (except health check), the system 
        should validate the presence and validity of an API key before processing 
        the request.
        
        This test verifies that valid, enabled API keys are accepted and invalid 
        or disabled keys are rejected.
        
        Validates: Requirements 4.1
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create an APIKey instance
        api_key_data = APIKey(
            key_id=api_key,
            name=name,
            created_at=created_at,
            enabled=enabled
        )
        
        # Configure mock to return the API key data
        mock_db_client.get_api_key.return_value = api_key_data
        mock_db_client.get_rate_limit.return_value = None
        mock_db_client.save_rate_limit.return_value = True
        
        # Create auth middleware with mocked DB client
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Property 1: Valid and enabled API keys should be accepted
        if enabled:
            try:
                result = auth_middleware.validate_api_key(api_key)
                
                # Should return the APIKey instance
                assert result is not None, "Valid API key should return APIKey instance"
                assert isinstance(result, APIKey), "Result should be an APIKey instance"
                assert result.key_id == api_key, "Returned key_id should match input"
                assert result.enabled is True, "Returned key should be enabled"
                
                # DB client should have been called with the correct key
                mock_db_client.get_api_key.assert_called_once_with(api_key)
                
            except AuthenticationError:
                pytest.fail("Valid and enabled API key should not raise AuthenticationError")
        
        # Property 2: Valid but disabled API keys should be rejected
        else:
            with pytest.raises(AuthenticationError) as exc_info:
                auth_middleware.validate_api_key(api_key)
            
            # Should raise with appropriate message
            assert "disabled" in str(exc_info.value).lower(), \
                "Disabled API key should raise error mentioning 'disabled'"
            
            # DB client should have been called
            mock_db_client.get_api_key.assert_called_once_with(api_key)
    
    @settings(max_examples=100)
    @given(api_key=valid_api_key_strategy)
    def test_property_9_authentication_requirement_missing_key(self, api_key):
        """
        Property: Missing API keys (None or empty) should always be rejected.
        
        Validates: Requirements 4.1
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Property: None API key should be rejected
        with pytest.raises(AuthenticationError) as exc_info:
            auth_middleware.validate_api_key(None)
        
        assert "missing" in str(exc_info.value).lower(), \
            "Missing API key should raise error mentioning 'missing'"
        
        # DB client should NOT be called for None key
        mock_db_client.get_api_key.assert_not_called()
        
        # Reset mock
        mock_db_client.reset_mock()
        
        # Property: Empty string API key should be rejected
        with pytest.raises(AuthenticationError) as exc_info:
            auth_middleware.validate_api_key("")
        
        assert "missing" in str(exc_info.value).lower(), \
            "Empty API key should raise error mentioning 'missing'"
        
        # DB client should NOT be called for empty key
        mock_db_client.get_api_key.assert_not_called()
    
    @settings(max_examples=100)
    @given(api_key=valid_api_key_strategy)
    def test_property_9_authentication_requirement_invalid_key(self, api_key):
        """
        Property: API keys that don't exist in the database should be rejected.
        
        Validates: Requirements 4.1
        """
        # Create a mock DynamoDB client that returns None (key not found)
        mock_db_client = Mock()
        mock_db_client.get_api_key.return_value = None
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Property: Non-existent API key should be rejected
        with pytest.raises(AuthenticationError) as exc_info:
            auth_middleware.validate_api_key(api_key)
        
        assert "invalid" in str(exc_info.value).lower(), \
            "Invalid API key should raise error mentioning 'invalid'"
        
        # DB client should have been called
        mock_db_client.get_api_key.assert_called_once_with(api_key)
    
    @settings(max_examples=100)
    @given(
        api_key=valid_api_key_strategy,
        name=api_key_name_strategy,
        created_at=timestamp_strategy
    )
    def test_authentication_consistency(self, api_key, name, created_at):
        """
        Property: Authentication should be consistent - the same valid key 
        should always be accepted, and the same invalid key should always be rejected.
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create an enabled APIKey instance
        api_key_data = APIKey(
            key_id=api_key,
            name=name,
            created_at=created_at,
            enabled=True
        )
        
        mock_db_client.get_api_key.return_value = api_key_data
        mock_db_client.get_rate_limit.return_value = None
        mock_db_client.save_rate_limit.return_value = True
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Property: Multiple validations of the same key should produce consistent results
        result1 = auth_middleware.validate_api_key(api_key)
        result2 = auth_middleware.validate_api_key(api_key)
        
        assert result1.key_id == result2.key_id, "Consistent key should produce consistent results"
        assert result1.enabled == result2.enabled, "Enabled status should be consistent"
    
    @settings(max_examples=100)
    @given(
        headers=st.dictionaries(
            keys=st.sampled_from(['X-API-Key', 'x-api-key', 'X-Api-Key']),  # Only the variants actually supported
            values=valid_api_key_strategy,
            min_size=1,
            max_size=1
        )
    )
    def test_api_key_extraction_case_insensitive(self, headers):
        """
        Property: API key extraction should handle common case variations of the header name.
        
        Note: The current implementation supports 'X-API-Key', 'x-api-key', and 'X-Api-Key'.
        """
        # Create an API Gateway event with headers
        event = {
            'headers': headers
        }
        
        # Extract API key
        extracted_key = extract_api_key(event)
        
        # Property: Should extract the key for supported header name variations
        assert extracted_key is not None, "API key should be extracted from headers"
        assert extracted_key in headers.values(), "Extracted key should match one of the header values"
    
    @settings(max_examples=100)
    @given(
        other_headers=st.dictionaries(
            keys=st.text(min_size=1, max_size=20).filter(
                lambda k: k.lower() not in ['x-api-key', 'x-api-key', 'x-api-key']
            ),
            values=st.text(min_size=1, max_size=50),
            min_size=0,
            max_size=5
        )
    )
    def test_api_key_extraction_missing(self, other_headers):
        """
        Property: When no API key header is present, extraction should return None.
        """
        # Create an API Gateway event without API key header
        event = {
            'headers': other_headers
        }
        
        # Extract API key
        extracted_key = extract_api_key(event)
        
        # Property: Should return None when API key header is missing
        assert extracted_key is None, "Should return None when API key header is missing"
    
    @settings(max_examples=100)
    @given(
        api_key=valid_api_key_strategy,
        name=api_key_name_strategy,
        created_at=timestamp_strategy
    )
    def test_authenticate_request_full_flow(self, api_key, name, created_at):
        """
        Property: The authenticate_request method should validate both API key 
        and rate limiting in sequence.
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create an enabled APIKey instance
        api_key_data = APIKey(
            key_id=api_key,
            name=name,
            created_at=created_at,
            enabled=True
        )
        
        mock_db_client.get_api_key.return_value = api_key_data
        mock_db_client.get_rate_limit.return_value = None
        mock_db_client.save_rate_limit.return_value = True
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Property: authenticate_request should succeed for valid key
        result, _ = auth_middleware.authenticate_request(api_key)
        
        assert result is not None, "authenticate_request should return APIKey instance"
        assert isinstance(result, APIKey), "Result should be an APIKey instance"
        assert result.key_id == api_key, "Returned key_id should match input"
        
        # Property: Both validation and rate limit check should be called
        mock_db_client.get_api_key.assert_called()
        mock_db_client.get_rate_limit.assert_called()
        mock_db_client.save_rate_limit.assert_called()
    
    @settings(max_examples=100)
    @given(api_key=valid_api_key_strategy)
    def test_authenticate_request_rejects_invalid_key(self, api_key):
        """
        Property: authenticate_request should reject invalid keys before checking rate limits.
        """
        # Create a mock DynamoDB client that returns None (key not found)
        mock_db_client = Mock()
        mock_db_client.get_api_key.return_value = None
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Property: Should raise AuthenticationError for invalid key
        with pytest.raises(AuthenticationError):
            auth_middleware.authenticate_request(api_key)
        
        # Property: Rate limit check should NOT be called for invalid key
        mock_db_client.get_rate_limit.assert_not_called()
        mock_db_client.save_rate_limit.assert_not_called()
    
    @settings(max_examples=100)
    @given(
        whitespace=st.text(
            alphabet=st.characters(whitelist_categories=('Zs',)),
            min_size=1,
            max_size=10
        )
    )
    def test_whitespace_only_api_key_behavior(self, whitespace):
        """
        Property: API keys consisting only of whitespace are treated as invalid keys
        (not found in database) rather than missing keys.
        
        Note: The current implementation only checks for None or empty string as "missing".
        Whitespace-only keys are passed to the database lookup and will fail as invalid.
        """
        # Create a mock DynamoDB client that returns None (key not found)
        mock_db_client = Mock()
        mock_db_client.get_api_key.return_value = None
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Property: Whitespace-only keys should be rejected
        # They will be looked up in the database and fail as invalid
        with pytest.raises(AuthenticationError) as exc_info:
            auth_middleware.validate_api_key(whitespace)
        
        # Should raise an authentication error (either "missing" or "invalid")
        error_message = str(exc_info.value).lower()
        assert "missing" in error_message or "invalid" in error_message, \
            "Whitespace-only key should raise authentication error"


@pytest.mark.property
class TestRateLimitProperties:
    """Property-based tests for rate limiting."""
    
    @settings(max_examples=100)
    @given(
        api_key=valid_api_key_strategy,
        name=api_key_name_strategy,
        created_at=timestamp_strategy,
        request_count=st.integers(min_value=0, max_value=150)
    )
    def test_property_10_rate_limit_enforcement(
        self, api_key, name, created_at, request_count
    ):
        """
        Feature: crypto-watch-backend, Property 10: Rate limit enforcement
        
        Property: For any API key, after 100 requests within a 60-second window, 
        subsequent requests should be rejected until the window resets.
        
        This test verifies that:
        1. Requests within the limit (< 100) are accepted
        2. Requests at or exceeding the limit (>= 100) are rejected with RateLimitError
        3. The rate limit counter is properly incremented
        
        Validates: Requirements 4.3
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create an enabled APIKey instance
        api_key_data = APIKey(
            key_id=api_key,
            name=name,
            created_at=created_at,
            enabled=True
        )
        
        # Configure mock to return the API key data
        mock_db_client.get_api_key.return_value = api_key_data
        
        # Create rate limit data with the given request count
        from src.shared.models import RateLimit
        import time
        
        current_minute = datetime.utcnow().strftime('%Y%m%d%H%M')
        ttl = int(time.time()) + 3600
        
        if request_count > 0:
            rate_limit_data = RateLimit(
                api_key=api_key,
                minute=current_minute,
                request_count=request_count,
                ttl=ttl
            )
            mock_db_client.get_rate_limit.return_value = rate_limit_data
        else:
            # No existing rate limit data
            mock_db_client.get_rate_limit.return_value = None
        
        mock_db_client.save_rate_limit.return_value = True
        
        # Create auth middleware with default rate limit (100 requests/minute)
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Property 1: Requests within the limit should be accepted
        if request_count < 100:
            try:
                # Should not raise RateLimitError
                auth_middleware.check_rate_limit(api_key)
                
                # Verify that save_rate_limit was called to increment the counter
                mock_db_client.save_rate_limit.assert_called_once()
                
                # Verify the saved rate limit has incremented count
                saved_rate_limit = mock_db_client.save_rate_limit.call_args[0][0]
                if request_count > 0:
                    assert saved_rate_limit.request_count == request_count + 1, \
                        f"Request count should be incremented from {request_count} to {request_count + 1}"
                else:
                    assert saved_rate_limit.request_count == 1, \
                        "First request should set count to 1"
                
            except RateLimitError:
                pytest.fail(f"Request count {request_count} is within limit, should not raise RateLimitError")
        
        # Property 2: Requests at or exceeding the limit should be rejected
        else:
            with pytest.raises(RateLimitError) as exc_info:
                auth_middleware.check_rate_limit(api_key)
            
            # Verify the error has retry_after set
            assert exc_info.value.retry_after == 60, \
                "RateLimitError should have retry_after set to 60 seconds"
            
            # Verify that save_rate_limit was NOT called (no increment when limit exceeded)
            mock_db_client.save_rate_limit.assert_not_called()
    
    @settings(max_examples=100)
    @given(
        api_key=valid_api_key_strategy,
        name=api_key_name_strategy,
        created_at=timestamp_strategy,
        num_requests=st.integers(min_value=1, max_value=150)
    )
    def test_rate_limit_sequential_requests(
        self, api_key, name, created_at, num_requests
    ):
        """
        Property: Sequential requests should increment the counter correctly,
        and the 101st request should be rejected.
        
        This simulates making multiple requests in sequence and verifies
        that rate limiting kicks in at the correct threshold.
        
        Validates: Requirements 4.3
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create an enabled APIKey instance
        api_key_data = APIKey(
            key_id=api_key,
            name=name,
            created_at=created_at,
            enabled=True
        )
        
        mock_db_client.get_api_key.return_value = api_key_data
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Simulate sequential requests
        from src.shared.models import RateLimit
        import time
        
        current_minute = datetime.utcnow().strftime('%Y%m%d%H%M')
        ttl = int(time.time()) + 3600
        current_count = 0
        
        for i in range(1, num_requests + 1):
            # Update mock to return current rate limit state
            if current_count > 0:
                rate_limit_data = RateLimit(
                    api_key=api_key,
                    minute=current_minute,
                    request_count=current_count,
                    ttl=ttl
                )
                mock_db_client.get_rate_limit.return_value = rate_limit_data
            else:
                mock_db_client.get_rate_limit.return_value = None
            
            # Reset mock call history
            mock_db_client.save_rate_limit.reset_mock()
            
            # Property: Requests 1-100 should succeed
            if current_count < 100:
                try:
                    auth_middleware.check_rate_limit(api_key)
                    current_count += 1
                    
                    # Verify save was called
                    assert mock_db_client.save_rate_limit.called, \
                        f"Request {i} should save rate limit data"
                    
                except RateLimitError:
                    pytest.fail(f"Request {i} (count={current_count}) should not be rate limited")
            
            # Property: Request 101+ should be rejected
            else:
                with pytest.raises(RateLimitError):
                    auth_middleware.check_rate_limit(api_key)
                
                # Count should not increment after limit is reached
                # (we break here since all subsequent requests will fail)
                break
    
    @settings(max_examples=100)
    @given(
        api_key=valid_api_key_strategy,
        name=api_key_name_strategy,
        created_at=timestamp_strategy
    )
    def test_rate_limit_boundary_at_100(self, api_key, name, created_at):
        """
        Property: The exact boundary condition - the 100th request should succeed,
        but the 101st request should fail.
        
        Validates: Requirements 4.3
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create an enabled APIKey instance
        api_key_data = APIKey(
            key_id=api_key,
            name=name,
            created_at=created_at,
            enabled=True
        )
        
        mock_db_client.get_api_key.return_value = api_key_data
        mock_db_client.save_rate_limit.return_value = True
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        from src.shared.models import RateLimit
        import time
        
        current_minute = datetime.utcnow().strftime('%Y%m%d%H%M')
        ttl = int(time.time()) + 3600
        
        # Test the 100th request (count = 99, will become 100)
        rate_limit_99 = RateLimit(
            api_key=api_key,
            minute=current_minute,
            request_count=99,
            ttl=ttl
        )
        mock_db_client.get_rate_limit.return_value = rate_limit_99
        
        # Property: 100th request should succeed
        try:
            auth_middleware.check_rate_limit(api_key)
            
            # Verify it was saved with count = 100
            saved_rate_limit = mock_db_client.save_rate_limit.call_args[0][0]
            assert saved_rate_limit.request_count == 100, \
                "100th request should set count to 100"
            
        except RateLimitError:
            pytest.fail("100th request should not be rate limited")
        
        # Reset mock
        mock_db_client.save_rate_limit.reset_mock()
        
        # Test the 101st request (count = 100, limit reached)
        rate_limit_100 = RateLimit(
            api_key=api_key,
            minute=current_minute,
            request_count=100,
            ttl=ttl
        )
        mock_db_client.get_rate_limit.return_value = rate_limit_100
        
        # Property: 101st request should be rejected
        with pytest.raises(RateLimitError) as exc_info:
            auth_middleware.check_rate_limit(api_key)
        
        assert exc_info.value.retry_after == 60, \
            "Rate limit error should have retry_after = 60"
        
        # Verify save was NOT called
        mock_db_client.save_rate_limit.assert_not_called()
    
    @settings(max_examples=100)
    @given(
        api_key=valid_api_key_strategy,
        name=api_key_name_strategy,
        created_at=timestamp_strategy,
        request_count=st.integers(min_value=0, max_value=99)
    )
    def test_rate_limit_window_isolation(
        self, api_key, name, created_at, request_count
    ):
        """
        Property: Rate limits are isolated per minute window.
        Different minute windows should have independent counters.
        
        Validates: Requirements 4.3
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create an enabled APIKey instance
        api_key_data = APIKey(
            key_id=api_key,
            name=name,
            created_at=created_at,
            enabled=True
        )
        
        mock_db_client.get_api_key.return_value = api_key_data
        mock_db_client.save_rate_limit.return_value = True
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        from src.shared.models import RateLimit
        import time
        
        # Simulate two different minute windows
        minute_1 = "202401151030"
        minute_2 = "202401151031"
        ttl = int(time.time()) + 3600
        
        # First window has some requests
        rate_limit_1 = RateLimit(
            api_key=api_key,
            minute=minute_1,
            request_count=request_count,
            ttl=ttl
        )
        
        # Mock returns data for minute_1
        mock_db_client.get_rate_limit.return_value = rate_limit_1
        
        # Make a request in minute_1
        try:
            auth_middleware.check_rate_limit(api_key)
            
            # Verify the counter was incremented for minute_1
            saved_rate_limit = mock_db_client.save_rate_limit.call_args[0][0]
            assert saved_rate_limit.minute == minute_1, \
                "Should save to the correct minute window"
            assert saved_rate_limit.request_count == request_count + 1, \
                "Should increment the counter for minute_1"
            
        except RateLimitError:
            pytest.fail("Request within limit should not be rate limited")
        
        # Reset mock
        mock_db_client.save_rate_limit.reset_mock()
        
        # Now simulate a new minute window with no existing data
        mock_db_client.get_rate_limit.return_value = None
        
        # Property: New minute window should start with fresh counter
        try:
            auth_middleware.check_rate_limit(api_key)
            
            # Verify a new rate limit entry was created with count = 1
            saved_rate_limit = mock_db_client.save_rate_limit.call_args[0][0]
            assert saved_rate_limit.request_count == 1, \
                "New minute window should start with count = 1"
            
        except RateLimitError:
            pytest.fail("New minute window should not be rate limited")
    
    @settings(max_examples=100)
    @given(
        api_key=valid_api_key_strategy,
        name=api_key_name_strategy,
        created_at=timestamp_strategy
    )
    def test_authenticate_request_enforces_rate_limit(
        self, api_key, name, created_at
    ):
        """
        Property: The authenticate_request method should enforce rate limiting
        after validating the API key.
        
        Validates: Requirements 4.3
        """
        # Create a mock DynamoDB client
        mock_db_client = Mock()
        
        # Create an enabled APIKey instance
        api_key_data = APIKey(
            key_id=api_key,
            name=name,
            created_at=created_at,
            enabled=True
        )
        
        mock_db_client.get_api_key.return_value = api_key_data
        
        # Create rate limit data at the limit
        from src.shared.models import RateLimit
        import time
        
        current_minute = datetime.utcnow().strftime('%Y%m%d%H%M')
        ttl = int(time.time()) + 3600
        
        rate_limit_at_limit = RateLimit(
            api_key=api_key,
            minute=current_minute,
            request_count=100,
            ttl=ttl
        )
        mock_db_client.get_rate_limit.return_value = rate_limit_at_limit
        
        # Create auth middleware
        auth_middleware = AuthMiddleware(db_client=mock_db_client)
        
        # Property: authenticate_request should raise RateLimitError when limit is exceeded
        with pytest.raises(RateLimitError) as exc_info:
            auth_middleware.authenticate_request(api_key)
        
        # Verify the error details
        assert exc_info.value.retry_after == 60, \
            "RateLimitError should have retry_after = 60"
        assert exc_info.value.status_code == 429, \
            "RateLimitError should have status code 429"
        
        # Verify that API key validation was called first
        mock_db_client.get_api_key.assert_called_once_with(api_key)
        
        # Verify that rate limit check was called
        mock_db_client.get_rate_limit.assert_called_once()
