"""
Data transformation functions.

Converts data between external API format and internal format.
"""

from datetime import datetime
from typing import Dict, Any, List
from .models import CryptoPrice


# Mapping of cryptocurrency symbols to their full names and CoinGecko IDs
SYMBOL_TO_COINGECKO_ID = {
    'BTC': ('bitcoin', 'Bitcoin'),
    'ETH': ('ethereum', 'Ethereum'),
    'ADA': ('cardano', 'Cardano'),
    'BNB': ('binancecoin', 'Binance Coin'),
    'XRP': ('ripple', 'XRP'),
    'SOL': ('solana', 'Solana'),
    'DOT': ('polkadot', 'Polkadot'),
    'DOGE': ('dogecoin', 'Dogecoin'),
    'AVAX': ('avalanche-2', 'Avalanche'),
    'MATIC': ('matic-network', 'Polygon'),
    'LINK': ('chainlink', 'Chainlink'),
    'UNI': ('uniswap', 'Uniswap'),
    'LTC': ('litecoin', 'Litecoin'),
    'ATOM': ('cosmos', 'Cosmos'),
    'XLM': ('stellar', 'Stellar'),
    'ALGO': ('algorand', 'Algorand'),
    'VET': ('vechain', 'VeChain'),
    'ICP': ('internet-computer', 'Internet Computer'),
    'FIL': ('filecoin', 'Filecoin'),
    'TRX': ('tron', 'TRON')
}


def get_coingecko_ids(symbols: List[str]) -> str:
    """
    Convert cryptocurrency symbols to CoinGecko IDs.
    
    Args:
        symbols: List of cryptocurrency symbols (e.g., ['BTC', 'ETH'])
        
    Returns:
        Comma-separated string of CoinGecko IDs
        
    Example:
        >>> get_coingecko_ids(['BTC', 'ETH'])
        'bitcoin,ethereum'
    """
    ids = []
    for symbol in symbols:
        if symbol in SYMBOL_TO_COINGECKO_ID:
            coingecko_id, _ = SYMBOL_TO_COINGECKO_ID[symbol]
            ids.append(coingecko_id)
    return ','.join(ids)


def transform_coingecko_response(
    response_data: Dict[str, Any],
    timestamp: datetime = None
) -> List[CryptoPrice]:
    """
    Transform CoinGecko API response to internal CryptoPrice format.
    
    Args:
        response_data: Response from CoinGecko API
        timestamp: Timestamp for the data (defaults to current time)
        
    Returns:
        List of CryptoPrice instances
        
    Example CoinGecko response format:
        {
            "bitcoin": {
                "usd": 45000.50,
                "usd_market_cap": 850000000000,
                "usd_24h_change": 2.5
            },
            "ethereum": {
                "usd": 3000.25,
                "usd_market_cap": 360000000000,
                "usd_24h_change": -1.2
            }
        }
    """
    if timestamp is None:
        timestamp = datetime.utcnow()
    
    prices = []
    
    # Create reverse mapping from CoinGecko ID to symbol
    id_to_symbol = {
        coingecko_id: symbol
        for symbol, (coingecko_id, _) in SYMBOL_TO_COINGECKO_ID.items()
    }
    
    for coingecko_id, data in response_data.items():
        # Skip if we don't have a mapping for this ID
        if coingecko_id not in id_to_symbol:
            continue
        
        symbol = id_to_symbol[coingecko_id]
        _, name = SYMBOL_TO_COINGECKO_ID[symbol]
        
        # Extract data with defaults for missing fields
        price = data.get('usd', 0.0)
        market_cap = data.get('usd_market_cap', 0)
        change_24h = data.get('usd_24h_change', 0.0)
        
        crypto_price = CryptoPrice(
            symbol=symbol,
            name=name,
            price=price,
            change24h=change_24h,
            market_cap=int(market_cap),
            last_updated=timestamp
        )
        
        prices.append(crypto_price)
    
    return prices


def transform_external_api_response(
    response_data: Dict[str, Any],
    api_type: str = 'coingecko',
    timestamp: datetime = None
) -> List[CryptoPrice]:
    """
    Transform external API response to internal format.
    
    This function provides a unified interface for transforming responses
    from different external APIs. Currently supports CoinGecko.
    
    Args:
        response_data: Response from external API
        api_type: Type of external API ('coingecko', etc.)
        timestamp: Timestamp for the data (defaults to current time)
        
    Returns:
        List of CryptoPrice instances
        
    Raises:
        ValueError: If api_type is not supported
    """
    if api_type == 'coingecko':
        return transform_coingecko_response(response_data, timestamp)
    else:
        raise ValueError(f"Unsupported API type: {api_type}")


def get_symbol_name(symbol: str) -> str:
    """
    Get the full name for a cryptocurrency symbol.
    
    Args:
        symbol: Cryptocurrency symbol (e.g., 'BTC')
        
    Returns:
        Full name of the cryptocurrency
        
    Raises:
        ValueError: If symbol is not supported
    """
    if symbol not in SYMBOL_TO_COINGECKO_ID:
        raise ValueError(f"Unsupported symbol: {symbol}")
    
    _, name = SYMBOL_TO_COINGECKO_ID[symbol]
    return name


def is_supported_symbol(symbol: str) -> bool:
    """
    Check if a cryptocurrency symbol is supported.
    
    Args:
        symbol: Cryptocurrency symbol to check
        
    Returns:
        True if symbol is supported, False otherwise
    """
    return symbol in SYMBOL_TO_COINGECKO_ID
