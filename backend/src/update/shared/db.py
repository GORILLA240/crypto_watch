"""
DynamoDB operations.

Provides database access layer for cryptocurrency prices, API keys, and rate limiting.
Validates: Requirements 5.4, 6.3

DynamoDB Retry Logic (Validates: Requirements 6.3):
- AWS SDK (boto3) includes built-in retry logic with exponential backoff
- Default retry configuration:
  - Standard retry mode with 3 maximum attempts
  - Exponential backoff with jitter
  - Automatic retry for throttling errors (ProvisionedThroughputExceededException)
  - Automatic retry for transient errors (500, 503, 504)
  - No retry for validation errors (400, 404)
- This implementation relies on AWS SDK's built-in retry mechanism
"""

import os
import boto3
import time
from typing import Optional, List, Dict, Any
from datetime import datetime
from botocore.exceptions import ClientError
from botocore.config import Config

from .models import CryptoPrice, APIKey, RateLimit
from .cache import calculate_ttl
from .metrics import get_metrics_publisher


class DynamoDBClient:
    """
    DynamoDB client for cache operations.
    
    Uses AWS SDK built-in retry logic with exponential backoff for transient errors.
    Validates: Requirements 6.3
    """
    
    def __init__(self, table_name: Optional[str] = None):
        """
        Initialize DynamoDB client with retry configuration.
        
        Args:
            table_name: Name of the DynamoDB table (defaults to environment variable)
        """
        self.table_name = table_name or os.environ.get('DYNAMODB_TABLE_NAME', 'crypto-watch-data')
        
        # Configure boto3 with explicit retry settings
        # Standard mode provides exponential backoff with jitter
        config = Config(
            retries={
                'mode': 'standard',
                'max_attempts': 3
            }
        )
        
        self.dynamodb = boto3.resource('dynamodb', config=config)
        self.table = self.dynamodb.Table(self.table_name)
        self.metrics = get_metrics_publisher()
    
    def get_price_data(self, symbol: str) -> Optional[CryptoPrice]:
        """
        Retrieve cached price data for a cryptocurrency symbol.
        
        AWS SDK automatically retries transient errors (throttling, 500/503/504).
        Validates: Requirements 5.4, 6.3
        
        Args:
            symbol: Cryptocurrency symbol (e.g., 'BTC', 'ETH')
            
        Returns:
            CryptoPrice instance if found, None otherwise
        """
        start_time = time.time()
        success = False
        
        try:
            response = self.table.get_item(
                Key={
                    'PK': f'PRICE#{symbol}',
                    'SK': 'METADATA'
                }
            )
            
            success = True
            latency_ms = (time.time() - start_time) * 1000
            self.metrics.record_dynamodb_operation('read', success, latency_ms)
            
            if 'Item' in response:
                return CryptoPrice.from_dynamodb_item(response['Item'])
            
            return None
            
        except ClientError as e:
            latency_ms = (time.time() - start_time) * 1000
            self.metrics.record_dynamodb_operation('read', success, latency_ms)
            
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            # AWS SDK has already retried transient errors
            # If we reach here, either it's a permanent error or retries exhausted
            print(f"DynamoDB error retrieving price data for {symbol}: {error_code} - {e}")
            return None
    
    def get_multiple_price_data(self, symbols: List[str]) -> Dict[str, CryptoPrice]:
        """
        Retrieve cached price data for multiple cryptocurrency symbols.
        
        AWS SDK automatically retries transient errors (throttling, 500/503/504).
        Validates: Requirements 6.3
        
        Args:
            symbols: List of cryptocurrency symbols
            
        Returns:
            Dictionary mapping symbols to CryptoPrice instances
        """
        if not symbols:
            return {}
        
        # Prepare batch get request
        request_items = {
            self.table_name: {
                'Keys': [
                    {
                        'PK': f'PRICE#{symbol}',
                        'SK': 'METADATA'
                    }
                    for symbol in symbols
                ]
            }
        }
        
        try:
            response = self.dynamodb.batch_get_item(RequestItems=request_items)
            
            result = {}
            if self.table_name in response.get('Responses', {}):
                for item in response['Responses'][self.table_name]:
                    price_data = CryptoPrice.from_dynamodb_item(item)
                    result[price_data.symbol] = price_data
            
            return result
            
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            # AWS SDK has already retried transient errors
            print(f"DynamoDB error retrieving multiple price data: {error_code} - {e}")
            return {}
    
    def save_price_data(self, price_data: CryptoPrice, ttl_seconds: int = 3600) -> bool:
        """
        Save price data to cache with TTL.
        
        AWS SDK automatically retries transient errors (throttling, 500/503/504).
        Validates: Requirements 5.4, 6.3
        
        Args:
            price_data: CryptoPrice instance to save
            ttl_seconds: Time-to-live in seconds (default: 1 hour)
            
        Returns:
            True if successful, False otherwise
        """
        start_time = time.time()
        success = False
        
        try:
            item = price_data.to_dynamodb_item(ttl_seconds)
            
            self.table.put_item(Item=item)
            success = True
            latency_ms = (time.time() - start_time) * 1000
            self.metrics.record_dynamodb_operation('write', success, latency_ms)
            return True
            
        except ClientError as e:
            latency_ms = (time.time() - start_time) * 1000
            self.metrics.record_dynamodb_operation('write', success, latency_ms)
            
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            # AWS SDK has already retried transient errors
            print(f"DynamoDB error saving price data for {price_data.symbol}: {error_code} - {e}")
            return False
    
    def save_multiple_price_data(self, price_data_list: List[CryptoPrice], ttl_seconds: int = 3600) -> bool:
        """
        Save multiple price data items to cache with TTL.
        
        AWS SDK automatically retries transient errors (throttling, 500/503/504).
        Validates: Requirements 5.4, 6.3
        
        Args:
            price_data_list: List of CryptoPrice instances to save
            ttl_seconds: Time-to-live in seconds (default: 1 hour)
            
        Returns:
            True if all successful, False if any failed
        """
        if not price_data_list:
            return True
        
        start_time = time.time()
        success = False
        
        try:
            # Use batch write for efficiency
            with self.table.batch_writer() as batch:
                for price_data in price_data_list:
                    item = price_data.to_dynamodb_item(ttl_seconds)
                    batch.put_item(Item=item)
            
            success = True
            latency_ms = (time.time() - start_time) * 1000
            self.metrics.record_dynamodb_operation('batch_write', success, latency_ms)
            return True
            
        except ClientError as e:
            latency_ms = (time.time() - start_time) * 1000
            self.metrics.record_dynamodb_operation('batch_write', success, latency_ms)
            
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            # AWS SDK has already retried transient errors
            print(f"DynamoDB error saving multiple price data: {error_code} - {e}")
            return False
    
    def get_api_key(self, key_id: str) -> Optional[APIKey]:
        """
        Retrieve API key information.
        
        AWS SDK automatically retries transient errors (throttling, 500/503/504).
        Validates: Requirements 6.3
        
        Args:
            key_id: API key identifier
            
        Returns:
            APIKey instance if found, None otherwise
        """
        try:
            response = self.table.get_item(
                Key={
                    'PK': f'APIKEY#{key_id}',
                    'SK': 'METADATA'
                }
            )
            
            if 'Item' in response:
                return APIKey.from_dynamodb_item(response['Item'])
            
            return None
            
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            # AWS SDK has already retried transient errors
            print(f"DynamoDB error retrieving API key {key_id}: {error_code} - {e}")
            return None
    
    def get_rate_limit(self, api_key: str, minute: str) -> Optional[RateLimit]:
        """
        Retrieve rate limit data for an API key and minute.
        
        AWS SDK automatically retries transient errors (throttling, 500/503/504).
        Validates: Requirements 6.3
        
        Args:
            api_key: API key identifier
            minute: Minute identifier (format: YYYYMMDDHHMM)
            
        Returns:
            RateLimit instance if found, None otherwise
        """
        try:
            response = self.table.get_item(
                Key={
                    'PK': f'APIKEY#{api_key}',
                    'SK': f'RATELIMIT#{minute}'
                }
            )
            
            if 'Item' in response:
                return RateLimit.from_dynamodb_item(response['Item'])
            
            return None
            
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            # AWS SDK has already retried transient errors
            print(f"DynamoDB error retrieving rate limit for {api_key}/{minute}: {error_code} - {e}")
            return None
    
    def save_rate_limit(self, rate_limit: RateLimit) -> bool:
        """
        Save rate limit data.
        
        AWS SDK automatically retries transient errors (throttling, 500/503/504).
        Validates: Requirements 6.3
        
        Args:
            rate_limit: RateLimit instance to save
            
        Returns:
            True if successful, False otherwise
        """
        try:
            item = rate_limit.to_dynamodb_item()
            self.table.put_item(Item=item)
            return True
            
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            # AWS SDK has already retried transient errors
            print(f"DynamoDB error saving rate limit: {error_code} - {e}")
            return False
