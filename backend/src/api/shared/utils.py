"""
General utility functions.

Provides common utilities for logging, time handling, and data formatting.
Validates: Requirements 5.1, 5.2
"""

import json
import logging
import os
from datetime import datetime, timezone
from typing import Any, Dict, Optional


class StructuredJSONFormatter(logging.Formatter):
    """
    Custom formatter that outputs structured JSON logs.
    
    Validates: Requirements 5.1
    """
    
    def format(self, record: logging.LogRecord) -> str:
        """
        Format log record as structured JSON.
        
        Args:
            record: Log record to format
            
        Returns:
            JSON-formatted log string
        """
        log_data = {
            'timestamp': datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z'),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage()
        }
        
        # Add exception info if present
        if record.exc_info:
            log_data['exception'] = self.formatException(record.exc_info)
        
        # Add extra fields if present
        if hasattr(record, 'request_id'):
            log_data['requestId'] = record.request_id
        if hasattr(record, 'api_key'):
            log_data['apiKey'] = record.api_key
        if hasattr(record, 'endpoint'):
            log_data['endpoint'] = record.endpoint
        if hasattr(record, 'duration'):
            log_data['duration'] = record.duration
        if hasattr(record, 'status_code'):
            log_data['statusCode'] = record.status_code
        
        return json.dumps(log_data)


def get_log_level_from_environment() -> str:
    """
    Determine log level based on environment.
    
    Returns DEBUG for dev, INFO for staging, ERROR for prod.
    Can be overridden with LOG_LEVEL environment variable.
    
    Returns:
        Log level string (DEBUG, INFO, ERROR)
    """
    # Check for explicit LOG_LEVEL override
    if 'LOG_LEVEL' in os.environ:
        return os.environ['LOG_LEVEL'].upper()
    
    # Determine based on ENVIRONMENT
    environment = os.environ.get('ENVIRONMENT', 'dev').lower()
    
    if environment == 'prod' or environment == 'production':
        return 'ERROR'
    elif environment == 'staging' or environment == 'stage':
        return 'INFO'
    else:  # dev, development, or unknown
        return 'DEBUG'


def setup_logger(name: str) -> logging.Logger:
    """
    Set up structured JSON logger with environment-based log level.
    
    Validates: Requirements 5.1
    
    Args:
        name: Logger name
        
    Returns:
        Configured logger instance with structured JSON formatting
    """
    logger = logging.getLogger(name)
    
    # Get log level based on environment
    log_level = get_log_level_from_environment()
    logger.setLevel(getattr(logging, log_level))
    
    # Remove existing handlers to avoid duplicates
    logger.handlers = []
    
    # Add console handler with structured JSON formatting
    handler = logging.StreamHandler()
    handler.setLevel(getattr(logging, log_level))
    handler.setFormatter(StructuredJSONFormatter())
    logger.addHandler(handler)
    
    # Prevent propagation to root logger
    logger.propagate = False
    
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


def log_request(
    logger: logging.Logger,
    event: Dict[str, Any],
    api_key: Optional[str] = None,
    extra_fields: Optional[Dict[str, Any]] = None
) -> str:
    """
    Log API request details with structured JSON format.
    
    Validates: Requirements 4.5, 5.1
    
    Args:
        logger: Logger instance
        event: API Gateway event
        api_key: API key (will be masked)
        extra_fields: Additional fields to include in log
        
    Returns:
        Request ID
    """
    request_id = event.get('requestContext', {}).get('requestId', 'unknown')
    
    log_data = {
        'event': 'api_request',
        'requestId': request_id,
        'method': event.get('httpMethod'),
        'path': event.get('path'),
        'timestamp': get_current_timestamp_iso()
    }
    
    # Add masked API key if present
    if api_key:
        log_data['apiKey'] = mask_api_key(api_key)
    
    # Add query parameters (without sensitive data)
    query_params = event.get('queryStringParameters')
    if query_params:
        log_data['queryParams'] = query_params
    
    # Add extra fields
    if extra_fields:
        log_data.update(extra_fields)
    
    logger.info(json.dumps(log_data))
    return request_id


def log_error(
    logger: logging.Logger,
    error: Exception,
    request_id: Optional[str] = None,
    **kwargs
) -> None:
    """
    Log error with detailed information including stack trace.
    
    Validates: Requirements 5.2
    
    Args:
        logger: Logger instance
        error: Exception to log
        request_id: Optional request ID
        **kwargs: Additional context
    """
    import traceback
    
    log_data = {
        'level': 'ERROR',
        'event': 'error',
        'error': str(error),
        'errorType': type(error).__name__,
        'timestamp': get_current_timestamp_iso(),
        'stackTrace': traceback.format_exc()
    }
    
    if request_id:
        log_data['requestId'] = request_id
    
    # Add any additional context
    log_data.update(kwargs)
    
    logger.error(json.dumps(log_data), exc_info=True)


def log_lambda_invocation(
    logger: logging.Logger,
    function_name: str,
    event_type: str,
    start_time: str
) -> None:
    """
    Log Lambda function invocation start.
    
    Validates: Requirements 5.1
    
    Args:
        logger: Logger instance
        function_name: Name of the Lambda function
        event_type: Type of event triggering the function
        start_time: ISO timestamp of invocation start
    """
    log_data = {
        'event': 'lambda_invocation_start',
        'functionName': function_name,
        'eventType': event_type,
        'startTime': start_time,
        'timestamp': get_current_timestamp_iso()
    }
    
    logger.info(json.dumps(log_data))


def log_lambda_completion(
    logger: logging.Logger,
    function_name: str,
    start_time: str,
    end_time: str,
    duration_ms: float,
    success: bool,
    **kwargs
) -> None:
    """
    Log Lambda function invocation completion.
    
    Validates: Requirements 5.1
    
    Args:
        logger: Logger instance
        function_name: Name of the Lambda function
        start_time: ISO timestamp of invocation start
        end_time: ISO timestamp of invocation end
        duration_ms: Execution duration in milliseconds
        success: Whether invocation succeeded
        **kwargs: Additional context
    """
    log_data = {
        'event': 'lambda_invocation_complete',
        'functionName': function_name,
        'startTime': start_time,
        'endTime': end_time,
        'duration': duration_ms,
        'status': 'success' if success else 'failure',
        'timestamp': get_current_timestamp_iso()
    }
    
    log_data.update(kwargs)
    
    logger.info(json.dumps(log_data))
