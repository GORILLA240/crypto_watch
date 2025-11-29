"""
DynamoDB operations.

Provides database access layer for cryptocurrency prices, API keys, and rate limiting.
"""

import os
import boto3
from typing import Optional, List, Dict, Any
from datetime import datetime
from botocore.exceptions import ClientError

from .models import CryptoPrice, APIKey, RateLimit
from .cache import calculate_ttl


class DynamoDBClient:
    """DynamoDB client for cache operations."""
    
    def __init__(self, table_name: Optional[str] = None):
        """
        Initialize DynamoDB client.
        
        Args:
            table_name: Name of the DynamoDB table (defaults to environment variable)
        """
        self.table_name = table_name or os.environ.get('DYNAMODB_TABLE_NAME', 'crypto-watch-data')
        self.dynamodb = boto3.resource('dynamodb')
        self.table = self.dynamodb.Table(self.table_name)
    
    def get_price_data(self, symbol: str) -> Optional[CryptoPrice]:
        """
        Retrieve cached price data for a cryptocurrency symbol.
        
        Args:
            symbol: Cryptocurrency symbol (e.g., 'BTC', 'ETH')
            
        Returns:
            CryptoPrice instance if found, None otherwise
        """
        try:
            response = self.table.get_item(
                Key={
                    'PK': f'PRICE#{symbol}',
                    'SK': 'METADATA'
                }
            )
            
            if 'Item' in response:
                return CryptoPrice.from_dynamodb_item(response['Item'])
            
            return None
            
        except ClientError as e:
            # Log error but don't raise - return None to indicate cache miss
            print(f"Error retrieving price data for {symbol}: {e}")
            return None
    
    def get_multiple_price_data(self, symbols: List[str]) -> Dict[str, CryptoPrice]:
        """
        Retrieve cached price data for multiple cryptocurrency symbols.
        
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
            # Log error but don't raise - return empty dict to indicate cache miss
            print(f"Error retrieving multiple price data: {e}")
            return {}
    
    def save_price_data(self, price_data: CryptoPrice, ttl_seconds: int = 3600) -> bool:
        """
        Save price data to cache with TTL.
        
        Args:
            price_data: CryptoPrice instance to save
            ttl_seconds: Time-to-live in seconds (default: 1 hour)
            
        Returns:
            True if successful, False otherwise
        """
        try:
            item = price_data.to_dynamodb_item(ttl_seconds)
            
            self.table.put_item(Item=item)
            return True
            
        except ClientError as e:
            print(f"Error saving price data for {price_data.symbol}: {e}")
            return False
    
    def save_multiple_price_data(self, price_data_list: List[CryptoPrice], ttl_seconds: int = 3600) -> bool:
        """
        Save multiple price data items to cache with TTL.
        
        Args:
            price_data_list: List of CryptoPrice instances to save
            ttl_seconds: Time-to-live in seconds (default: 1 hour)
            
        Returns:
            True if all successful, False if any failed
        """
        if not price_data_list:
            return True
        
        try:
            # Use batch write for efficiency
            with self.table.batch_writer() as batch:
                for price_data in price_data_list:
                    item = price_data.to_dynamodb_item(ttl_seconds)
                    batch.put_item(Item=item)
            
            return True
            
        except ClientError as e:
            print(f"Error saving multiple price data: {e}")
            return False
    
    def get_api_key(self, key_id: str) -> Optional[APIKey]:
        """
        Retrieve API key information.
        
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
            print(f"Error retrieving API key {key_id}: {e}")
            return None
    
    def get_rate_limit(self, api_key: str, minute: str) -> Optional[RateLimit]:
        """
        Retrieve rate limit data for an API key and minute.
        
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
            print(f"Error retrieving rate limit for {api_key}/{minute}: {e}")
            return None
    
    def save_rate_limit(self, rate_limit: RateLimit) -> bool:
        """
        Save rate limit data.
        
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
            print(f"Error saving rate limit: {e}")
            return False
