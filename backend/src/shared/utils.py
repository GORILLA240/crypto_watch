"""
General utility functions.

Provides common utilities for logging, time handling, and data formatting.
"""

import json
import logging
import os
from datetime import datetime, timezone
from typing import Any, Dict


def setup_logger(name: str) -> logging.Logger:
    """
    Set up structured JSON logger.
    
    Args:
        name: Logger name
        
    Returns:
        Configured logger instance
    """
    logger = logging.getLogger(name)
    log_level = os.environ.get('LOG_LEVEL', 'INFO')
    logger.setLevel(getattr(logging, log_level))
    
    # Remove existing handlers
    logger.handlers = []
    
    # Add console handler with JSON formatting
    handler = logging.StreamHandler()
    handler.setLevel(getattr(logging, log_level))
    logger.addHandler(handler)
    
    return logger


def get_current_timestamp() -> datetime:
    """Get current UTC timestamp."""
    return datetime.now(timezone.utc)


def get_current_timestamp_iso() -> str:
    """Get current UTC timestamp in ISO format."""
    return get_current_timestamp().isoformat().replace('+00:00', 'Z')


def get_unix_timestamp(dt: datetime) -> int:
    """Convert datetime to Unix timestamp."""
    return int(dt.timestamp())


def mask_api_key(api_key: str) -> str:
    """
    Mask API key for logging.
    
    Args:
        api_key: Full API key
        
    Returns:
        Masked API key (e.g., 'key_abc***')
    """
    if len(api_key) <= 7:
        return 'key_***'
    return f"{api_key[:7]}***"


def log_request(logger: logging.Logger, event: Dict[str, Any], api_key: str = None) -> str:
    """
    Log API request details.
    
    Args:
        logger: Logger instance
        event: API Gateway event
        api_key: API key (will be masked)
        
    Returns:
        Request ID
    """
    request_id = event.get('requestContext', {}).get('requestId', 'unknown')
    
    log_data = {
        'requestId': request_id,
        'method': event.get('httpMethod'),
        'path': event.get('path'),
        'timestamp': get_current_timestamp_iso()
    }
    
    if api_key:
        log_data['apiKey'] = mask_api_key(api_key)
    
    logger.info(json.dumps(log_data))
    return request_id


def log_error(logger: logging.Logger, error: Exception, request_id: str = None, **kwargs) -> None:
    """
    Log error with details.
    
    Args:
        logger: Logger instance
        error: Exception to log
        request_id: Optional request ID
        **kwargs: Additional context
    """
    log_data = {
        'level': 'ERROR',
        'error': str(error),
        'errorType': type(error).__name__,
        'timestamp': get_current_timestamp_iso()
    }
    
    if request_id:
        log_data['requestId'] = request_id
    
    log_data.update(kwargs)
    
    logger.error(json.dumps(log_data), exc_info=True)
