"""
API Lambda Function Handler

Handles API Gateway requests for cryptocurrency prices.
Implements authentication, rate limiting, and response formatting.
Validates: Requirements 5.1, 5.3, 5.4
"""

import json
import os
import time
from typing import Dict, Any, List, Optional

from shared.auth import AuthMiddleware, extract_api_key
from shared.cache import CacheManager
from shared.external_api import ExternalAPIClient
from shared.errors import (
    ValidationError, 
    AuthenticationError, 
    RateLimitError,
    ExternalAPIError,
    format_error_response
)
from shared.utils import (
    setup_logger,
    log_request,
    log_error,
    get_current_timestamp_iso,
    log_lambda_invocation,
    log_lambda_completion
)
from shared.response_optimizer import format_optimized_response
from shared.metrics import get_metrics_publisher

# Initialize logger
logger = setup_logger(__name__)

# Initialize metrics publisher
metrics = get_metrics_publisher()

# Initialize components
auth_middleware = AuthMiddleware()
cache_manager = CacheManager()
external_api_client = ExternalAPIClient()

# Cache threshold in minutes
CACHE_THRESHOLD_MINUTES = int(os.environ.get('CACHE_TTL_SECONDS', '300')) // 60

# Supported cryptocurrency symbols
SUPPORTED_SYMBOLS = {
    'BTC', 'ETH', 'ADA', 'BNB', 'XRP', 'SOL', 'DOT', 'DOGE', 
    'AVAX', 'MATIC', 'LINK', 'UNI', 'LTC', 'ATOM', 'XLM', 
    'ALGO', 'VET', 'ICP', 'FIL', 'TRX'
}


def parse_request_parameters(event: Dict[str, Any]) -> List[str]:
    """
    Parse and validate request parameters to extract cryptocurrency symbols.
    
    Args:
        event: API Gateway event
        
    Returns:
        List of cryptocurrency symbols
        
    Raises:
        ValidationError: If parameters are invalid or missing
    """
    path = event.get('path', '')
    query_params = event.get('queryStringParameters') or {}
    path_params = event.get('pathParameters') or {}
    
    symbols = []
    
    # Check for single symbol in path parameter (e.g., /prices/BTC)
    if 'symbol' in path_params:
        symbol = path_params['symbol'].upper()
        symbols = [symbol]
    
    # Check for multiple symbols in query parameter (e.g., /prices?symbols=BTC,ETH)
    elif 'symbols' in query_params:
        symbols_param = query_params['symbols']
        if not symbols_param:
            raise ValidationError('symbols parameter cannot be empty')
        
        # Split by comma and clean up
        symbols = [s.strip().upper() for s in symbols_param.split(',') if s.strip()]
    
    # If no symbols specified, return error
    if not symbols:
        raise ValidationError(
            'Missing required parameter: symbols or symbol',
            details={'hint': 'Use ?symbols=BTC,ETH or /prices/{symbol}'}
        )
    
    # Validate symbols
    unsupported = [s for s in symbols if s not in SUPPORTED_SYMBOLS]
    if unsupported:
        raise ValidationError(
            f'Unsupported cryptocurrency symbols: {", ".join(unsupported)}',
            details={
                'unsupportedSymbols': unsupported,
                'supportedSymbols': sorted(list(SUPPORTED_SYMBOLS))
            }
        )
    
    return symbols





def handle_health_check(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Handle health check endpoint.
    
    Performs comprehensive system health checks:
    - DynamoDB connectivity test
    - Last price update timestamp check
    - Cache age calculation
    
    Returns 503 if any critical check fails.
    Validates: Requirements 5.5
    
    Args:
        event: API Gateway event
        
    Returns:
        Health check response with status and detailed checks
    """
    from datetime import datetime, timezone
    from shared.cache import get_cache_age_seconds
    
    timestamp = get_current_timestamp_iso()
    checks = {}
    is_healthy = True
    error_message = None
    
    # Check 1: DynamoDB connectivity
    try:
        # Perform a simple query to test DynamoDB connection
        # Try to get a known symbol to verify table access
        test_result = cache_manager.db_client.get_price_data('BTC')
        checks['dynamodb'] = 'ok'
        logger.info("Health check: DynamoDB connectivity OK")
    except Exception as e:
        checks['dynamodb'] = 'error'
        is_healthy = False
        error_message = f"DynamoDB connection failed: {str(e)}"
        logger.error(f"Health check: DynamoDB connectivity failed - {e}")
    
    # Check 2: Last price update timestamp
    last_update_timestamp = None
    cache_age = None
    
    try:
        # Get the most recent price data to determine last update
        # Check multiple symbols to find the most recent update
        symbols_to_check = ['BTC', 'ETH', 'ADA']
        most_recent_update = None
        
        for symbol in symbols_to_check:
            try:
                price_data = cache_manager.db_client.get_price_data(symbol)
                if price_data:
                    if most_recent_update is None or price_data.last_updated > most_recent_update:
                        most_recent_update = price_data.last_updated
            except Exception:
                continue
        
        if most_recent_update:
            last_update_timestamp = most_recent_update.isoformat().replace('+00:00', 'Z')
            cache_age = int(get_cache_age_seconds(most_recent_update))
            checks['lastPriceUpdate'] = last_update_timestamp
            checks['cacheAge'] = cache_age
            
            # Consider cache unhealthy if older than 15 minutes (3x the update interval)
            if cache_age > 900:  # 15 minutes
                is_healthy = False
                error_message = f"Price data is stale (age: {cache_age}s)"
                logger.warning(f"Health check: Cache is stale - {cache_age}s old")
            else:
                logger.info(f"Health check: Cache age OK - {cache_age}s")
        else:
            # No price data found - system might be initializing
            checks['lastPriceUpdate'] = None
            checks['cacheAge'] = None
            logger.warning("Health check: No price data found in cache")
            
    except Exception as e:
        checks['lastPriceUpdate'] = None
        checks['cacheAge'] = None
        logger.error(f"Health check: Failed to check price update status - {e}")
    
    # Build response
    response_body = {
        'status': 'healthy' if is_healthy else 'unhealthy',
        'timestamp': timestamp,
        'checks': checks
    }
    
    if error_message:
        response_body['error'] = error_message
    
    status_code = 200 if is_healthy else 503
    
    logger.info(f"Health check completed: status={response_body['status']}, code={status_code}")
    
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(response_body)
    }


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Handles API Gateway requests for cryptocurrency prices.
    
    Validates: Requirements 5.1, 5.3, 5.4
    
    Args:
        event: API Gateway event containing request details
        context: Lambda execution context
        
    Returns:
        API Gateway response with status code, headers, and body
    """
    # Track invocation timing
    start_time = get_current_timestamp_iso()
    start_time_ms = time.time() * 1000
    
    request_id = event.get('requestContext', {}).get('requestId', 'unknown')
    path = event.get('path', '')
    
    # Log Lambda invocation start
    log_lambda_invocation(
        logger,
        function_name='ApiFunction',
        event_type='APIGatewayProxyEvent',
        start_time=start_time
    )
    
    status_code = 200
    success = True
    
    try:
        # Check if this is a health check request
        path = event.get('path', '')
        if path == '/health' or path.endswith('/health'):
            return handle_health_check(event)
        
        # Extract API key from headers
        api_key = extract_api_key(event)
        
        # Log request (with masked API key)
        log_request(logger, event, api_key)
        
        # Authenticate and check rate limit
        try:
            auth_middleware.authenticate_request(api_key)
        except AuthenticationError as e:
            status_code = 401
            success = False
            logger.warning(f"Authentication failed: {e.message}")
            response = format_error_response(e, request_id)
            
            # Record metrics before returning
            end_time_ms = time.time() * 1000
            latency_ms = end_time_ms - start_time_ms
            metrics.record_api_request(path, status_code, latency_ms)
            log_lambda_completion(
                logger,
                function_name='ApiFunction',
                start_time=start_time,
                end_time=get_current_timestamp_iso(),
                duration_ms=latency_ms,
                success=success,
                statusCode=status_code
            )
            
            return {
                'statusCode': response['statusCode'],
                'headers': response['headers'],
                'body': json.dumps(response['body'])
            }
        except RateLimitError as e:
            status_code = 429
            success = False
            logger.warning(f"Rate limit exceeded for API key")
            response = format_error_response(e, request_id)
            
            # Record metrics before returning
            end_time_ms = time.time() * 1000
            latency_ms = end_time_ms - start_time_ms
            metrics.record_api_request(path, status_code, latency_ms)
            log_lambda_completion(
                logger,
                function_name='ApiFunction',
                start_time=start_time,
                end_time=get_current_timestamp_iso(),
                duration_ms=latency_ms,
                success=success,
                statusCode=status_code
            )
            
            return {
                'statusCode': response['statusCode'],
                'headers': response['headers'],
                'body': json.dumps(response['body'])
            }
        
        # Parse and validate request parameters
        symbols = parse_request_parameters(event)
        
        logger.info(f"Processing request for symbols: {symbols}")
        
        # Get cache status for requested symbols
        cache_status = cache_manager.get_cache_status(symbols, CACHE_THRESHOLD_MINUTES)
        
        # Separate fresh and stale symbols
        fresh_symbols = [s for s, status in cache_status.items() if status['is_fresh']]
        stale_symbols = [s for s, status in cache_status.items() if status['needs_refresh']]
        
        price_data_list = []
        
        # Get fresh data from cache
        if fresh_symbols:
            logger.info(f"Retrieving {len(fresh_symbols)} symbols from cache")
            fresh_data = cache_manager.get_fresh_multiple_price_data(fresh_symbols, CACHE_THRESHOLD_MINUTES)
            price_data_list.extend(fresh_data.values())
        
        # Fetch stale data from external API
        if stale_symbols:
            logger.info(f"Fetching {len(stale_symbols)} symbols from external API")
            try:
                new_data = external_api_client.fetch_prices(stale_symbols)
                
                # Cache the new data
                cache_manager.cache_multiple_price_data(new_data, ttl_seconds=3600)
                
                price_data_list.extend(new_data)
                
            except ExternalAPIError as e:
                # If external API fails, try to use stale cache data as fallback
                logger.warning(f"External API failed, attempting to use stale cache: {e.message}")
                
                stale_data = cache_manager.db_client.get_multiple_price_data(stale_symbols)
                
                if stale_data:
                    logger.info(f"Using {len(stale_data)} stale cache entries as fallback")
                    price_data_list.extend(stale_data.values())
                else:
                    # No cache available, return error
                    status_code = 503
                    success = False
                    logger.error("No cache data available for fallback")
                    response = format_error_response(e, request_id)
                    
                    # Record metrics before returning
                    end_time_ms = time.time() * 1000
                    latency_ms = end_time_ms - start_time_ms
                    metrics.record_api_request(path, status_code, latency_ms)
                    log_lambda_completion(
                        logger,
                        function_name='ApiFunction',
                        start_time=start_time,
                        end_time=get_current_timestamp_iso(),
                        duration_ms=latency_ms,
                        success=success,
                        statusCode=status_code
                    )
                    
                    return {
                        'statusCode': 503,
                        'headers': response['headers'],
                        'body': json.dumps(response['body'])
                    }
        
        # Sort by symbol for consistent ordering
        price_data_list.sort(key=lambda x: x.symbol)
        
        # Format and return optimized response (with optional compression)
        timestamp = get_current_timestamp_iso()
        headers = event.get('headers') or {}
        
        logger.info(f"Successfully processed request for {len(price_data_list)} symbols")
        
        # Record successful request metrics
        end_time_ms = time.time() * 1000
        latency_ms = end_time_ms - start_time_ms
        metrics.record_api_request(path, status_code, latency_ms)
        log_lambda_completion(
            logger,
            function_name='ApiFunction',
            start_time=start_time,
            end_time=get_current_timestamp_iso(),
            duration_ms=latency_ms,
            success=success,
            statusCode=status_code,
            symbolCount=len(price_data_list)
        )
        
        return format_optimized_response(price_data_list, timestamp, headers)
        
    except ValidationError as e:
        status_code = 400
        success = False
        logger.warning(f"Validation error: {e.message}")
        response = format_error_response(e, request_id)
        
        # Record metrics
        end_time_ms = time.time() * 1000
        latency_ms = end_time_ms - start_time_ms
        metrics.record_api_request(path, status_code, latency_ms)
        log_lambda_completion(
            logger,
            function_name='ApiFunction',
            start_time=start_time,
            end_time=get_current_timestamp_iso(),
            duration_ms=latency_ms,
            success=success,
            statusCode=status_code
        )
        
        return {
            'statusCode': response['statusCode'],
            'headers': response['headers'],
            'body': json.dumps(response['body'])
        }
        
    except Exception as e:
        status_code = 500
        success = False
        # Catch-all for unexpected errors
        log_error(logger, e, request_id)
        
        # Record metrics
        end_time_ms = time.time() * 1000
        latency_ms = end_time_ms - start_time_ms
        metrics.record_api_request(path, status_code, latency_ms)
        log_lambda_completion(
            logger,
            function_name='ApiFunction',
            start_time=start_time,
            end_time=get_current_timestamp_iso(),
            duration_ms=latency_ms,
            success=success,
            statusCode=status_code
        )
        
        # Don't expose internal error details to client
        response = format_error_response(e, request_id)
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(response['body'])
        }
