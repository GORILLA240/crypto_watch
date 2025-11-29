"""
Price Update Lambda Function Handler

Fetches and updates cryptocurrency prices from external API.
Implements retry logic with exponential backoff.
"""

import json
import os
import sys
from typing import Dict, Any, List

# Add shared module to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'shared'))

from external_api import ExternalAPIClient
from db import DynamoDBClient
from utils import setup_logger, get_current_timestamp_iso
from errors import ExternalAPIError


logger = setup_logger(__name__)


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
    
    Args:
        event: EventBridge scheduled event
        context: Lambda execution context
        
    Returns:
        Status information about the update operation
        
    Requirements:
        - 3.1: Fetch updated prices every 5 minutes from external API
        - 3.2: Save fetched data with timestamp to DynamoDB
        - 3.5: Track timestamp of last successful update
    """
    start_time = get_current_timestamp_iso()
    
    logger.info(json.dumps({
        'message': 'Price update started',
        'timestamp': start_time,
        'environment': os.environ.get('ENVIRONMENT', 'unknown')
    }))
    
    try:
        # Get supported symbols
        symbols = get_supported_symbols()
        logger.info(json.dumps({
            'message': 'Fetching prices',
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
                'message': 'Successfully fetched prices from external API',
                'priceCount': len(prices)
            }))
        except ExternalAPIError as e:
            # All retries exhausted
            logger.error(json.dumps({
                'message': 'Failed to fetch prices after all retries',
                'error': str(e),
                'errorType': 'ExternalAPIError',
                'timestamp': get_current_timestamp_iso()
            }))
            
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
        success = db_client.save_multiple_price_data(prices, ttl_seconds=3600)
        
        if not success:
            logger.error(json.dumps({
                'message': 'Failed to save prices to DynamoDB',
                'timestamp': get_current_timestamp_iso()
            }))
            
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'message': 'Failed to save prices to DynamoDB',
                    'timestamp': get_current_timestamp_iso()
                })
            }
        
        # Log success with metrics
        end_time = get_current_timestamp_iso()
        logger.info(json.dumps({
            'message': 'Price update completed successfully',
            'startTime': start_time,
            'endTime': end_time,
            'symbolCount': len(symbols),
            'priceCount': len(prices),
            'timestamp': end_time
        }))
        
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
        logger.error(json.dumps({
            'message': 'Unexpected error during price update',
            'error': str(e),
            'errorType': type(e).__name__,
            'timestamp': get_current_timestamp_iso()
        }), exc_info=True)
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Unexpected error during price update',
                'error': str(e),
                'timestamp': get_current_timestamp_iso()
            })
        }
