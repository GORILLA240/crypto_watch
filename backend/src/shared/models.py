"""
Data models and type definitions.

Defines data structures for cryptocurrency prices, API keys, and rate limiting.
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Optional, Dict, Any
import time


@dataclass
class CryptoPrice:
    """Cryptocurrency price data model."""
    symbol: str
    name: str
    price: float
    change24h: float
    market_cap: int
    last_updated: datetime
    
    def to_dict(self) -> dict:
        """Convert to dictionary for API response."""
        return {
            'symbol': self.symbol,
            'name': self.name,
            'price': round(self.price, 2),
            'change24h': round(self.change24h, 1),
            'marketCap': self.market_cap,
            'lastUpdated': self.last_updated.isoformat() + 'Z'
        }
    
    def to_dynamodb_item(self, ttl_seconds: int = 3600) -> Dict[str, Any]:
        """
        Convert to DynamoDB item format.
        
        Args:
            ttl_seconds: Time-to-live in seconds (default: 1 hour)
            
        Returns:
            Dictionary representing DynamoDB item
        """
        current_timestamp = int(time.time())
        return {
            'PK': f'PRICE#{self.symbol}',
            'SK': 'METADATA',
            'symbol': self.symbol,
            'name': self.name,
            'price': self.price,
            'change24h': self.change24h,
            'marketCap': self.market_cap,
            'lastUpdated': self.last_updated.isoformat() + 'Z',
            'ttl': current_timestamp + ttl_seconds
        }
    
    @classmethod
    def from_dynamodb_item(cls, item: Dict[str, Any]) -> 'CryptoPrice':
        """
        Create CryptoPrice instance from DynamoDB item.
        
        Args:
            item: DynamoDB item dictionary
            
        Returns:
            CryptoPrice instance
        """
        # Parse ISO timestamp, removing 'Z' suffix if present
        timestamp_str = item['lastUpdated'].rstrip('Z')
        last_updated = datetime.fromisoformat(timestamp_str)
        
        return cls(
            symbol=item['symbol'],
            name=item['name'],
            price=float(item['price']),
            change24h=float(item['change24h']),
            market_cap=int(item['marketCap']),
            last_updated=last_updated
        )


@dataclass
class APIKey:
    """API key data model."""
    key_id: str
    name: str
    created_at: datetime
    enabled: bool
    last_used_at: Optional[datetime] = None
    
    def to_dynamodb_item(self) -> Dict[str, Any]:
        """
        Convert to DynamoDB item format.
        
        Returns:
            Dictionary representing DynamoDB item
        """
        item = {
            'PK': f'APIKEY#{self.key_id}',
            'SK': 'METADATA',
            'keyId': self.key_id,
            'name': self.name,
            'createdAt': self.created_at.isoformat() + 'Z',
            'enabled': self.enabled
        }
        
        if self.last_used_at:
            item['lastUsedAt'] = self.last_used_at.isoformat() + 'Z'
        
        return item
    
    @classmethod
    def from_dynamodb_item(cls, item: Dict[str, Any]) -> 'APIKey':
        """
        Create APIKey instance from DynamoDB item.
        
        Args:
            item: DynamoDB item dictionary
            
        Returns:
            APIKey instance
        """
        created_at = datetime.fromisoformat(item['createdAt'].rstrip('Z'))
        last_used_at = None
        
        if 'lastUsedAt' in item:
            last_used_at = datetime.fromisoformat(item['lastUsedAt'].rstrip('Z'))
        
        return cls(
            key_id=item['keyId'],
            name=item['name'],
            created_at=created_at,
            enabled=item['enabled'],
            last_used_at=last_used_at
        )


@dataclass
class RateLimit:
    """Rate limit tracking data model."""
    api_key: str
    minute: str
    request_count: int
    ttl: int
    
    def to_dynamodb_item(self) -> Dict[str, Any]:
        """
        Convert to DynamoDB item format.
        
        Returns:
            Dictionary representing DynamoDB item
        """
        return {
            'PK': f'APIKEY#{self.api_key}',
            'SK': f'RATELIMIT#{self.minute}',
            'requestCount': self.request_count,
            'ttl': self.ttl
        }
    
    @classmethod
    def from_dynamodb_item(cls, item: Dict[str, Any]) -> 'RateLimit':
        """
        Create RateLimit instance from DynamoDB item.
        
        Args:
            item: DynamoDB item dictionary
            
        Returns:
            RateLimit instance
        """
        # Extract api_key from PK (format: APIKEY#<key>)
        api_key = item['PK'].split('#', 1)[1]
        # Extract minute from SK (format: RATELIMIT#<minute>)
        minute = item['SK'].split('#', 1)[1]
        
        return cls(
            api_key=api_key,
            minute=minute,
            request_count=int(item['requestCount']),
            ttl=int(item['ttl'])
        )
