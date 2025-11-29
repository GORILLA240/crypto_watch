"""
Cache management utilities.

Provides cache freshness checking and TTL calculation.
"""

import time
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any, TYPE_CHECKING

if TYPE_CHECKING:
    from .models import CryptoPrice


def calculate_ttl(duration_seconds: int = 3600) -> int:
    """
    Calculate TTL (Time To Live) timestamp for DynamoDB items.
    
    Args:
        duration_seconds: Duration in seconds from now (default: 1 hour)
        
    Returns:
        Unix timestamp when the item should expire
    """
    return int(time.time()) + duration_seconds


def is_cache_fresh(last_updated: datetime, threshold_minutes: int = 5) -> bool:
    """
    Check if cached data is still fresh based on the threshold.
    
    Args:
        last_updated: Timestamp when data was last updated
        threshold_minutes: Freshness threshold in minutes (default: 5)
        
    Returns:
        True if data is fresh (within threshold), False if stale
    """
    if last_updated.tzinfo is None:
        # Assume UTC if no timezone info
        last_updated = last_updated.replace(tzinfo=timezone.utc)
    
    current_time = datetime.now(timezone.utc)
    time_diff = current_time - last_updated
    
    # Convert threshold to seconds and compare
    threshold_seconds = threshold_minutes * 60
    return time_diff.total_seconds() < threshold_seconds


def get_cache_age_seconds(last_updated: datetime) -> float:
    """
    Get the age of cached data in seconds.
    
    Args:
        last_updated: Timestamp when data was last updated
        
    Returns:
        Age of the data in seconds
    """
    if last_updated.tzinfo is None:
        # Assume UTC if no timezone info
        last_updated = last_updated.replace(tzinfo=timezone.utc)
    
    current_time = datetime.now(timezone.utc)
    time_diff = current_time - last_updated
    
    return time_diff.total_seconds()


def should_refresh_cache(last_updated: Optional[datetime], threshold_minutes: int = 5) -> bool:
    """
    Determine if cache should be refreshed.
    
    Args:
        last_updated: Timestamp when data was last updated (None if no cache exists)
        threshold_minutes: Freshness threshold in minutes (default: 5)
        
    Returns:
        True if cache should be refreshed, False if current cache can be used
    """
    # If no cache exists, refresh is needed
    if last_updated is None:
        return True
    
    # If cache exists but is stale, refresh is needed
    return not is_cache_fresh(last_updated, threshold_minutes)


class CacheManager:
    """
    High-level cache manager that combines cache logic with DynamoDB operations.
    """
    
    def __init__(self, db_client=None):
        """
        Initialize cache manager.
        
        Args:
            db_client: DynamoDB client instance (will create one if None)
        """
        if db_client is None:
            from .db import DynamoDBClient
            self.db_client = DynamoDBClient()
        else:
            self.db_client = db_client
    
    def get_fresh_price_data(self, symbol: str, threshold_minutes: int = 5) -> Optional['CryptoPrice']:
        """
        Get price data if it's fresh, None if stale or missing.
        
        Args:
            symbol: Cryptocurrency symbol
            threshold_minutes: Freshness threshold in minutes
            
        Returns:
            CryptoPrice if fresh data exists, None otherwise
        """
        from .models import CryptoPrice
        
        price_data = self.db_client.get_price_data(symbol)
        
        if price_data is None:
            return None
        
        if is_cache_fresh(price_data.last_updated, threshold_minutes):
            return price_data
        
        return None
    
    def get_fresh_multiple_price_data(self, symbols: List[str], threshold_minutes: int = 5) -> Dict[str, 'CryptoPrice']:
        """
        Get price data for multiple symbols if they're fresh.
        
        Args:
            symbols: List of cryptocurrency symbols
            threshold_minutes: Freshness threshold in minutes
            
        Returns:
            Dictionary mapping symbols to fresh CryptoPrice instances
        """
        all_price_data = self.db_client.get_multiple_price_data(symbols)
        
        fresh_data = {}
        for symbol, price_data in all_price_data.items():
            if is_cache_fresh(price_data.last_updated, threshold_minutes):
                fresh_data[symbol] = price_data
        
        return fresh_data
    
    def cache_price_data(self, price_data: 'CryptoPrice', ttl_seconds: int = 3600) -> bool:
        """
        Cache price data with TTL.
        
        Args:
            price_data: CryptoPrice instance to cache
            ttl_seconds: Time-to-live in seconds
            
        Returns:
            True if successful, False otherwise
        """
        return self.db_client.save_price_data(price_data, ttl_seconds)
    
    def cache_multiple_price_data(self, price_data_list: List['CryptoPrice'], ttl_seconds: int = 3600) -> bool:
        """
        Cache multiple price data items with TTL.
        
        Args:
            price_data_list: List of CryptoPrice instances to cache
            ttl_seconds: Time-to-live in seconds
            
        Returns:
            True if all successful, False if any failed
        """
        return self.db_client.save_multiple_price_data(price_data_list, ttl_seconds)
    
    def should_refresh_symbol(self, symbol: str, threshold_minutes: int = 5) -> bool:
        """
        Check if a symbol's cache should be refreshed.
        
        Args:
            symbol: Cryptocurrency symbol
            threshold_minutes: Freshness threshold in minutes
            
        Returns:
            True if refresh needed, False if cache is fresh
        """
        price_data = self.db_client.get_price_data(symbol)
        
        if price_data is None:
            return True
        
        return should_refresh_cache(price_data.last_updated, threshold_minutes)
    
    def get_cache_status(self, symbols: List[str], threshold_minutes: int = 5) -> Dict[str, Dict[str, Any]]:
        """
        Get cache status for multiple symbols.
        
        Args:
            symbols: List of cryptocurrency symbols
            threshold_minutes: Freshness threshold in minutes
            
        Returns:
            Dictionary with cache status for each symbol
        """
        all_price_data = self.db_client.get_multiple_price_data(symbols)
        
        status = {}
        for symbol in symbols:
            if symbol in all_price_data:
                price_data = all_price_data[symbol]
                is_fresh = is_cache_fresh(price_data.last_updated, threshold_minutes)
                age_seconds = get_cache_age_seconds(price_data.last_updated)
                
                status[symbol] = {
                    'exists': True,
                    'is_fresh': is_fresh,
                    'age_seconds': age_seconds,
                    'last_updated': price_data.last_updated,
                    'needs_refresh': not is_fresh
                }
            else:
                status[symbol] = {
                    'exists': False,
                    'is_fresh': False,
                    'age_seconds': None,
                    'last_updated': None,
                    'needs_refresh': True
                }
        
        return status