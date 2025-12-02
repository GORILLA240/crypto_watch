"""
Shared utilities for Crypto Watch backend.

This package contains common functionality used by both API and Update Lambda functions.
"""

__version__ = '0.1.0'

from .models import CryptoPrice, APIKey, RateLimit
from .transformers import (
    transform_external_api_response,
    transform_coingecko_response,
    get_coingecko_ids,
    get_symbol_name,
    is_supported_symbol,
    SYMBOL_TO_COINGECKO_ID
)

__all__ = [
    'CryptoPrice',
    'APIKey',
    'RateLimit',
    'transform_external_api_response',
    'transform_coingecko_response',
    'get_coingecko_ids',
    'get_symbol_name',
    'is_supported_symbol',
    'SYMBOL_TO_COINGECKO_ID'
]
