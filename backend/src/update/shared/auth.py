"""
Authentication and authorization utilities.

Provides API key validation and rate limiting.
"""

import os
from typing import Optional, Tuple
from datetime import datetime
import time

from .db import DynamoDBClient
from .models import APIKey, RateLimit
from .errors import AuthenticationError, RateLimitError


class AuthMiddleware:
    """Authentication and rate limiting middleware."""
    
    def __init__(self, db_client: Optional[DynamoDBClient] = None):
        """
        Initialize authentication middleware.
        
        Args:
            db_client: DynamoDB client instance (creates new if not provided)
        """
        self.db_client = db_client or DynamoDBClient()
        self.rate_limit_per_minute = int(os.environ.get('RATE_LIMIT_PER_MINUTE', '100'))
    
    def validate_api_key(self, api_key: Optional[str]) -> APIKey:
        """
        Validate API key and return API key information.
        
        Args:
            api_key: API key from request header
            
        Returns:
            APIKey instance if valid
            
        Raises:
            AuthenticationError: If API key is missing, invalid, or disabled
        """
        # Check if API key is provided
        if not api_key:
            raise AuthenticationError('Missing API key')
        
        # Retrieve API key from database
        api_key_data = self.db_client.get_api_key(api_key)
        
        # Check if API key exists
        if not api_key_data:
            raise AuthenticationError('Invalid API key')
        
        # Check if API key is enabled
        if not api_key_data.enabled:
            raise AuthenticationError('API key is disabled')
        
        return api_key_data
    
    def check_rate_limit(self, api_key: str) -> None:
        """
        Check and enforce rate limiting for an API key.
        
        Args:
            api_key: API key identifier
            
        Raises:
            RateLimitError: If rate limit is exceeded
        """
        # Get current minute identifier (format: YYYYMMDDHHMM)
        current_minute = datetime.utcnow().strftime('%Y%m%d%H%M')
        
        # Retrieve current rate limit data
        rate_limit_data = self.db_client.get_rate_limit(api_key, current_minute)
        
        if rate_limit_data:
            # Check if limit is exceeded
            if rate_limit_data.request_count >= self.rate_limit_per_minute:
                raise RateLimitError(retry_after=60)
            
            # Increment request count
            rate_limit_data.request_count += 1
        else:
            # Create new rate limit entry
            # TTL set to 1 hour from now (3600 seconds)
            ttl = int(time.time()) + 3600
            rate_limit_data = RateLimit(
                api_key=api_key,
                minute=current_minute,
                request_count=1,
                ttl=ttl
            )
        
        # Save updated rate limit data
        self.db_client.save_rate_limit(rate_limit_data)
    
    def authenticate_request(self, api_key: Optional[str]) -> Tuple[APIKey, None]:
        """
        Authenticate request and enforce rate limiting.
        
        This is the main entry point for authentication middleware.
        
        Args:
            api_key: API key from request header
            
        Returns:
            Tuple of (APIKey instance, None) if authentication succeeds
            
        Raises:
            AuthenticationError: If authentication fails
            RateLimitError: If rate limit is exceeded
        """
        # Validate API key
        api_key_data = self.validate_api_key(api_key)
        
        # Check rate limit
        self.check_rate_limit(api_key_data.key_id)
        
        return api_key_data, None


def extract_api_key(event: dict) -> Optional[str]:
    """
    Extract API key from API Gateway event.
    
    Args:
        event: API Gateway event dictionary
        
    Returns:
        API key string if found, None otherwise
    """
    # Check headers (case-insensitive)
    headers = event.get('headers', {})
    
    # Try different header name variations
    for header_name in ['X-API-Key', 'x-api-key', 'X-Api-Key']:
        if header_name in headers:
            return headers[header_name]
    
    return None
