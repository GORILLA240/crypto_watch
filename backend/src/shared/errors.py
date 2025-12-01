"""
Error handling utilities.

Defines custom exceptions and error response formatting.
"""

from typing import Dict, Any, Optional
from datetime import datetime
import uuid


class CryptoWatchError(Exception):
    """Base exception for Crypto Watch backend."""
    def __init__(self, message: str, code: str, status_code: int = 500, details: Optional[Dict] = None):
        self.message = message
        self.code = code
        self.status_code = status_code
        self.details = details or {}
        super().__init__(self.message)


class ValidationError(CryptoWatchError):
    """Raised when request validation fails."""
    def __init__(self, message: str, details: Optional[Dict] = None):
        super().__init__(message, 'VALIDATION_ERROR', 400, details)


class AuthenticationError(CryptoWatchError):
    """Raised when authentication fails."""
    def __init__(self, message: str = 'Invalid API key', details: Optional[Dict] = None):
        super().__init__(message, 'UNAUTHORIZED', 401, details)


class RateLimitError(CryptoWatchError):
    """Raised when rate limit is exceeded."""
    def __init__(self, retry_after: int = 60, details: Optional[Dict] = None):
        super().__init__('Rate limit exceeded', 'RATE_LIMIT_EXCEEDED', 429, details)
        self.retry_after = retry_after


class ExternalAPIError(CryptoWatchError):
    """Raised when external API call fails."""
    def __init__(self, message: str, details: Optional[Dict] = None):
        super().__init__(message, 'EXTERNAL_API_ERROR', 502, details)


class DatabaseError(CryptoWatchError):
    """Raised when database operation fails."""
    def __init__(self, message: str, details: Optional[Dict] = None):
        super().__init__(message, 'DATABASE_ERROR', 500, details)


def format_error_response(error: Exception, request_id: Optional[str] = None) -> Dict[str, Any]:
    """
    Format error as API Gateway response with consistent structure.
    
    Validates: Requirements 6.1, 6.2, 6.5
    
    All error responses follow a consistent JSON structure:
    - error: Human-readable error message
    - code: Error code constant
    - timestamp: ISO 8601 timestamp
    - requestId: Unique request identifier
    - details: Optional additional context
    - retryAfter: Optional retry delay (for rate limit errors)
    
    Args:
        error: Exception to format
        request_id: Optional request ID for tracking
        
    Returns:
        API Gateway response dictionary with consistent error format
    """
    if isinstance(error, CryptoWatchError):
        status_code = error.status_code
        body = {
            'error': error.message,
            'code': error.code,
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'requestId': request_id or str(uuid.uuid4())
        }
        
        if error.details:
            body['details'] = error.details
            
        if isinstance(error, RateLimitError):
            body['retryAfter'] = error.retry_after
    else:
        # Unexpected error - don't expose internal details
        status_code = 500
        body = {
            'error': 'Internal server error',
            'code': 'INTERNAL_ERROR',
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'requestId': request_id or str(uuid.uuid4())
        }
    
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': body
    }
