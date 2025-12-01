"""
Price Update Lambda Function Handler

Fetches and updates cryptocurrency prices from external API.
Implements retry logic with exponential backoff.
Validates: Requirements 5.1, 5.3, 5.4
"""

import json
import os
import sys
import time
from typing import Dict, Any, List

# Add shared module to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'shared'))

try:
    from external_api import ExternalAPIClient
    from db import DynamoDBClient
    from utils import (
        setup_logger,
        get_current_timestamp_iso,
        log_lambda_invocation,
        log_lambda_completion,
        log_error
    )
    from errors import ExternalAPIError
    from metrics import get_metrics_publisher
except ImportError:
    # Fallback for test environment
    from shared.external_api import ExternalAPIClient
    from shared.db import DynamoDBClient
    from shared.utils import (
        setup_logger,
        get_current_timestamp_iso,
        log_lambda_invocation,
        log_lambda_completion,
        log_error
    )
    from shared.errors import ExternalAPIError
    from shared.metrics import get_metrics_publisher


logger = setup_logger(__name__)
metrics = get_metrics_publisher()


def get_supported_symbols() -> List[str]:
    """
    Get list of supported cryptocurrency symbols from environment.
    
    Returns:
        List of cryptocurrency symbols
    """
    symbols_str = os.environ.get('SUPPORTED_SYMBOLS', 'BTC,ETH,ADA,BNB,XRP,SOL,DOT,DOGE,AVAX,MATIC,LINK,UNI,LTC,ATOM,XLM,ALGO,VET,ICP,FIL,TRX')
    return [s.strip() for s in symbols_str.split(',') if s.strip()]


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Fetches and updates cryptocurrency prices from external API.
    
    This function is triggered by EventBridge on a schedule (every 5 minutes).
    It fetches current prices for all supported cryptocurrencies and saves
    them to DynamoDB with timestamps.
    
    Validates: Requirements 3.1, 3.2, 3.5, 5.1, 5.3, 5.4
    
    Args:
        event: EventBridge scheduled event
        context: Lambda execution context
        
    Returns:
        Status information about the update operation
    """
    start_time = get_current_timestamp_iso()
    start_time_ms = time.time() * 1000
    success = True
    
    # Log Lambda invocation start
    log_lambda_invocation(
        logger,
        function_name='PriceUpdateFunction',
        event_type='EventBridgeScheduledEvent',
        start_time=start_time
    )
    
    logger.info(json.dumps({
        'event': 'price_update_started',
        'timestamp': start_time,
        'environment': os.environ.get('ENVIRONMENT', 'unknown')
    }))
    
    try:
        # Get supported symbols
        symbols = get_supported_symbols()
        logger.info(json.dumps({
            'event': 'fetching_prices',
            'symbolCount': len(symbols),
            'symbols': symbols
        }))
        
        # Initialize clients
        api_client = ExternalAPIClient()
        db_client = DynamoDBClient()
        
        # Fetch prices from external API (with retry logic)
        try:
            prices = api_client.fetch_prices(symbols)
            logger.info(json.dumps({
                'event': 'prices_fetched',
                'priceCount': len(prices)
            }))
            
            # Record successful external API call metric
            metrics.record_external_api_call(success=True)
            
        except ExternalAPIError as e:
            # All retries exhausted
            success = False
            log_error(logger, e)
            
            # Record failed external API call metric
            metrics.record_external_api_call(success=False)
            
            # Record Lambda completion
            end_time_ms = time.time() * 1000
            duration_ms = end_time_ms - start_time_ms
            metrics.record_lambda_invocation('PriceUpdateFunction', duration_ms, success)
            log_lambda_completion(
                logger,
                function_name='PriceUpdateFunction',
                start_time=start_time,
                end_time=get_current_timestamp_iso(),
                duration_ms=duration_ms,
                success=success,
                error=str(e)
            )
            
            # Return error response but don't raise - allow Lambda to complete
            return {
                'statusCode': 502,
                'body': json.dumps({
                    'message': 'Failed to fetch prices from external API',
                    'error': str(e),
                    'timestamp': get_current_timestamp_iso()
                })
            }
        
        # Save prices to DynamoDB
        # TTL set to 1 hour (3600 seconds) as per design
        db_success = db_client.save_multiple_price_data(prices, ttl_seconds=3600)
        
        # Record DynamoDB write metric
        metrics.record_dynamodb_operation('write', db_success)
        
        if not db_success:
            success = False
            logger.error(json.dumps({
                'event': 'dynamodb_save_failed',
                'timestamp': get_current_timestamp_iso()
            }))
            
            # Record Lambda completion
            end_time_ms = time.time() * 1000
            duration_ms = end_time_ms - start_time_ms
            metrics.record_lambda_invocation('PriceUpdateFunction', duration_ms, success)
            log_lambda_completion(
                logger,
                function_name='PriceUpdateFunction',
                start_time=start_time,
                end_time=get_current_timestamp_iso(),
                duration_ms=duration_ms,
                success=success
            )
            
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'message': 'Failed to save prices to DynamoDB',
                    'timestamp': get_current_timestamp_iso()
                })
            }
        
        # Log success with metrics
        end_time = get_current_timestamp_iso()
        end_time_ms = time.time() * 1000
        duration_ms = end_time_ms - start_time_ms
        
        logger.info(json.dumps({
            'event': 'price_update_completed',
            'startTime': start_time,
            'endTime': end_time,
            'duration': duration_ms,
            'symbolCount': len(symbols),
            'priceCount': len(prices),
            'timestamp': end_time
        }))
        
        # Record Lambda completion metrics
        metrics.record_lambda_invocation('PriceUpdateFunction', duration_ms, success)
        log_lambda_completion(
            logger,
            function_name='PriceUpdateFunction',
            start_time=start_time,
            end_time=end_time,
            duration_ms=duration_ms,
            success=success,
            symbolCount=len(symbols),
            priceCount=len(prices)
        )
        
        # Return success response
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Price update completed successfully',
                'symbolCount': len(symbols),
                'priceCount': len(prices),
                'lastUpdated': end_time,
                'timestamp': end_time
            })
        }
        
    except Exception as e:
        # Catch any unexpected errors
        success = False
        log_error(logger, e)
        
        # Record Lambda completion metrics
        end_time_ms = time.time() * 1000
        duration_ms = end_time_ms - start_time_ms
        metrics.record_lambda_invocation('PriceUpdateFunction', duration_ms, success)
        log_lambda_completion(
            logger,
            function_name='PriceUpdateFunction',
            start_time=start_time,
            end_time=get_current_timestamp_iso(),
            duration_ms=duration_ms,
            success=success,
            error=str(e)
        )
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Unexpected error during price update',
                'error': str(e),
                'timestamp': get_current_timestamp_iso()
            })
        }
