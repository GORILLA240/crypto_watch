"""
External API client.

Handles communication with external cryptocurrency price APIs.
Implements retry logic with exponential backoff.
"""

import os
import time
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime, timezone
import requests

from .models import CryptoPrice
from .errors import ExternalAPIError
from .utils import setup_logger, get_current_timestamp

logger = setup_logger(__name__)


class ExternalAPIClient:
    """
    Client for fetching cryptocurrency prices from external API.
    
    Implements retry logic with exponential backoff:
    - Attempt 1: Immediate
    - Attempt 2: Wait 1 second
    - Attempt 3: Wait 2 seconds
    - Attempt 4: Wait 4 seconds
    
    Each attempt has a 5-second timeout.
    """
    
    # Retry configuration
    MAX_RETRIES = 3
    RETRY_DELAYS = [1, 2, 4]  # Exponential backoff delays in seconds
    REQUEST_TIMEOUT = 5  # Timeout per attempt in seconds
    
    # Symbol mapping from internal to external API format
    SYMBOL_MAPPING = {
        'BTC': 'bitcoin',
        'ETH': 'ethereum',
        'ADA': 'cardano',
        'BNB': 'binancecoin',
        'XRP': 'ripple',
        'SOL': 'solana',
        'DOT': 'polkadot',
        'DOGE': 'dogecoin',
        'AVAX': 'avalanche-2',
        'MATIC': 'matic-network',
        'LINK': 'chainlink',
        'UNI': 'uniswap',
        'LTC': 'litecoin',
        'ATOM': 'cosmos',
        'XLM': 'stellar',
        'ALGO': 'algorand',
        'VET': 'vechain',
        'ICP': 'internet-computer',
        'FIL': 'filecoin',
        'TRX': 'tron'
    }
    
    # Reverse mapping for converting back
    REVERSE_SYMBOL_MAPPING = {v: k for k, v in SYMBOL_MAPPING.items()}
    
    # Name mapping
    NAME_MAPPING = {
        'BTC': 'Bitcoin',
        'ETH': 'Ethereum',
        'ADA': 'Cardano',
        'BNB': 'Binance Coin',
        'XRP': 'XRP',
        'SOL': 'Solana',
        'DOT': 'Polkadot',
        'DOGE': 'Dogecoin',
        'AVAX': 'Avalanche',
        'MATIC': 'Polygon',
        'LINK': 'Chainlink',
        'UNI': 'Uniswap',
        'LTC': 'Litecoin',
        'ATOM': 'Cosmos',
        'XLM': 'Stellar',
        'ALGO': 'Algorand',
        'VET': 'VeChain',
        'ICP': 'Internet Computer',
        'FIL': 'Filecoin',
        'TRX': 'TRON'
    }
    
    def __init__(self, api_url: Optional[str] = None, api_key: Optional[str] = None):
        """
        Initialize external API client.
        
        Args:
            api_url: Base URL for external API (defaults to CoinGecko)
            api_key: API key for external service (optional for CoinGecko free tier)
        """
        self.api_url = api_url or os.environ.get(
            'EXTERNAL_API_URL',
            'https://api.coingecko.com/api/v3'
        )
        self.api_key = api_key or os.environ.get('EXTERNAL_API_KEY')
    
    def fetch_prices(self, symbols: List[str]) -> List[CryptoPrice]:
        """
        Fetch cryptocurrency prices for given symbols.
        
        Implements retry logic with exponential backoff. If all retries fail,
        raises ExternalAPIError.
        
        Args:
            symbols: List of cryptocurrency symbols (e.g., ['BTC', 'ETH'])
            
        Returns:
            List of CryptoPrice objects
            
        Raises:
            ExternalAPIError: If all retry attempts fail
        """
        # Convert symbols to external API format
        external_ids = [self.SYMBOL_MAPPING.get(symbol, symbol.lower()) for symbol in symbols]
        ids_param = ','.join(external_ids)
        
        url = f"{self.api_url}/simple/price"
        params = {
            'ids': ids_param,
            'vs_currencies': 'usd',
            'include_market_cap': 'true',
            'include_24hr_change': 'true'
        }
        
        headers = {}
        if self.api_key:
            headers['X-CG-API-KEY'] = self.api_key
        
        last_error = None
        
        # Initial attempt + retries
        for attempt in range(self.MAX_RETRIES + 1):
            try:
                logger.info(f"Fetching prices from external API (attempt {attempt + 1}/{self.MAX_RETRIES + 1})")
                
                response = requests.get(
                    url,
                    params=params,
                    headers=headers,
                    timeout=self.REQUEST_TIMEOUT
                )
                
                # Check for HTTP errors
                response.raise_for_status()
                
                # Parse and transform response
                data = response.json()
                prices = self._transform_response(data, symbols)
                
                logger.info(f"Successfully fetched {len(prices)} prices from external API")
                return prices
                
            except requests.exceptions.Timeout as e:
                last_error = e
                error_msg = f"Request timeout on attempt {attempt + 1}"
                logger.warning(error_msg)
                
            except requests.exceptions.RequestException as e:
                last_error = e
                error_msg = f"Request failed on attempt {attempt + 1}: {str(e)}"
                logger.warning(error_msg)
                
            except (ValueError, KeyError) as e:
                last_error = e
                error_msg = f"Failed to parse response on attempt {attempt + 1}: {str(e)}"
                logger.warning(error_msg)
            
            # If not the last attempt, wait before retrying
            if attempt < self.MAX_RETRIES:
                delay = self.RETRY_DELAYS[attempt]
                logger.info(f"Waiting {delay} seconds before retry...")
                time.sleep(delay)
        
        # All retries exhausted
        error_message = f"Failed to fetch prices after {self.MAX_RETRIES + 1} attempts"
        logger.error(f"{error_message}. Last error: {str(last_error)}")
        
        raise ExternalAPIError(
            error_message,
            details={
                'attempts': self.MAX_RETRIES + 1,
                'lastError': str(last_error),
                'symbols': symbols
            }
        )
    
    def _transform_response(self, data: Dict[str, Any], requested_symbols: List[str]) -> List[CryptoPrice]:
        """
        Transform external API response to internal CryptoPrice format.
        
        Args:
            data: Response data from external API
            requested_symbols: List of symbols that were requested
            
        Returns:
            List of CryptoPrice objects
            
        Raises:
            ValueError: If response data is invalid or missing required fields
        """
        prices = []
        current_time = get_current_timestamp()
        
        for symbol in requested_symbols:
            external_id = self.SYMBOL_MAPPING.get(symbol, symbol.lower())
            
            if external_id not in data:
                logger.warning(f"Symbol {symbol} not found in API response")
                continue
            
            coin_data = data[external_id]
            
            # Validate required fields
            if 'usd' not in coin_data:
                logger.warning(f"Missing price data for {symbol}")
                continue
            
            # Extract data with defaults for optional fields
            price = float(coin_data['usd'])
            change_24h = float(coin_data.get('usd_24h_change', 0.0))
            market_cap = int(coin_data.get('usd_market_cap', 0))
            
            crypto_price = CryptoPrice(
                symbol=symbol,
                name=self.NAME_MAPPING.get(symbol, symbol),
                price=price,
                change24h=change_24h,
                market_cap=market_cap,
                last_updated=current_time
            )
            
            prices.append(crypto_price)
        
        if not prices:
            raise ValueError("No valid price data found in response")
        
        return prices


def fetch_crypto_prices(symbols: List[str]) -> List[CryptoPrice]:
    """
    Convenience function to fetch cryptocurrency prices.
    
    Args:
        symbols: List of cryptocurrency symbols
        
    Returns:
        List of CryptoPrice objects
        
    Raises:
        ExternalAPIError: If fetching fails after all retries
    """
    client = ExternalAPIClient()
    return client.fetch_prices(symbols)
