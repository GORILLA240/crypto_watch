"""
API Lambda Function Handler

Handles API Gateway requests for cryptocurrency prices.
Implements authentication, rate limiting, and response formatting.
"""

import json
import os
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
from shared.utils import setup_logger, log_request, log_error, get_current_timestamp_iso

# Initialize logger
logger = setup_logger(__name__)

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


def format_response(price_data_list: List[Any]) -> Dict[str, Any]:
    """
    Format price data as API response.
    
    Args:
        price_data_list: List of CryptoPrice objects
        
    Returns:
        Formatted response dictionary
    """
    return {
        'data': [price.to_dict() for price in price_data_list],
        'timestamp': get_current_timestamp_iso()
    }


def handle_health_check(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Handle health check endpoint.
    
    Args:
        event: API Gateway event
        
    Returns:
        Health check response
    """
    # Health check doesn't require authentication
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'status': 'healthy',
            'timestamp': get_current_timestamp_iso(),
            'service': 'crypto-watch-api'
        })
    }


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Handles API Gateway requests for cryptocurrency prices.
    
    Args:
        event: API Gateway event containing request details
        context: Lambda execution context
        
    Returns:
        API Gateway response with status code, headers, and body
    """
    request_id = event.get('requestContext', {}).get('requestId', 'unknown')
    
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
            logger.warning(f"Authentication failed: {e.message}")
            response = format_error_response(e, request_id)
            return {
                'statusCode': response['statusCode'],
                'headers': response['headers'],
                'body': json.dumps(response['body'])
            }
        except RateLimitError as e:
            logger.warning(f"Rate limit exceeded for API key")
            response = format_error_response(e, request_id)
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
                    logger.error("No cache data available for fallback")
                    response = format_error_response(e, request_id)
                    return {
                        'statusCode': 503,
                        'headers': response['headers'],
                        'body': json.dumps(response['body'])
                    }
        
        # Sort by symbol for consistent ordering
        price_data_list.sort(key=lambda x: x.symbol)
        
        # Format and return response
        response_data = format_response(price_data_list)
        
        logger.info(f"Successfully processed request for {len(price_data_list)} symbols")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(response_data)
        }
        
    except ValidationError as e:
        logger.warning(f"Validation error: {e.message}")
        response = format_error_response(e, request_id)
        return {
            'statusCode': response['statusCode'],
            'headers': response['headers'],
            'body': json.dumps(response['body'])
        }
        
    except Exception as e:
        # Catch-all for unexpected errors
        log_error(logger, e, request_id)
        
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
