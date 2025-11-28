"""
Property-based tests for data transformation functions.

Tests universal properties that should hold across all valid inputs.
"""

import pytest
from hypothesis import given, strategies as st, settings
from datetime import datetime
from src.shared.transformers import (
    transform_coingecko_response,
    transform_external_api_response,
    get_coingecko_ids,
    get_symbol_name,
    is_supported_symbol,
    SYMBOL_TO_COINGECKO_ID
)
from src.shared.models import CryptoPrice


# Strategy for generating valid cryptocurrency symbols
valid_symbols = st.sampled_from(list(SYMBOL_TO_COINGECKO_ID.keys()))

# Strategy for generating valid CoinGecko IDs
valid_coingecko_ids = st.sampled_from([
    coingecko_id for coingecko_id, _ in SYMBOL_TO_COINGECKO_ID.values()
])

# Strategy for generating price data
price_data = st.fixed_dictionaries({
    'usd': st.floats(min_value=0.01, max_value=1000000.0, allow_nan=False, allow_infinity=False),
    'usd_market_cap': st.floats(min_value=0, max_value=1e15, allow_nan=False, allow_infinity=False),
    'usd_24h_change': st.floats(min_value=-100.0, max_value=1000.0, allow_nan=False, allow_infinity=False)
})

# Strategy for generating CoinGecko API responses
def coingecko_response_strategy():
    """Generate valid CoinGecko API response data."""
    return st.dictionaries(
        keys=valid_coingecko_ids,
        values=price_data,
        min_size=1,
        max_size=20
    )


@pytest.mark.property
class TestTransformersProperties:
    """Property-based tests for data transformers."""
    
    @settings(max_examples=100)
    @given(response_data=coingecko_response_strategy())
    def test_property_1_complete_response_data_structure(self, response_data):
        """
        Feature: crypto-watch-backend, Property 1: Complete response data structure
        
        Property: For any valid cryptocurrency price data, the formatted API response
        should include symbol, name, price, 24-hour percentage change, market cap,
        and lastUpdated timestamp for each requested cryptocurrency.
        
        Validates: Requirements 1.2, 1.3
        """
        # Transform the CoinGecko response to internal format
        timestamp = datetime(2024, 1, 15, 10, 30, 0)
        crypto_prices = transform_coingecko_response(response_data, timestamp)
        
        # Property: Every transformed price should have all required fields
        for crypto_price in crypto_prices:
            # Convert to API response format
            api_response = crypto_price.to_dict()
            
            # Assert all required fields are present
            assert 'symbol' in api_response, "Response must include 'symbol' field"
            assert 'name' in api_response, "Response must include 'name' field"
            assert 'price' in api_response, "Response must include 'price' field"
            assert 'change24h' in api_response, "Response must include 'change24h' field"
            assert 'marketCap' in api_response, "Response must include 'marketCap' field"
            assert 'lastUpdated' in api_response, "Response must include 'lastUpdated' field"
            
            # Assert field types are correct
            assert isinstance(api_response['symbol'], str), "symbol must be a string"
            assert isinstance(api_response['name'], str), "name must be a string"
            assert isinstance(api_response['price'], (int, float)), "price must be numeric"
            assert isinstance(api_response['change24h'], (int, float)), "change24h must be numeric"
            assert isinstance(api_response['marketCap'], int), "marketCap must be an integer"
            assert isinstance(api_response['lastUpdated'], str), "lastUpdated must be a string"
            
            # Assert values are valid
            assert len(api_response['symbol']) > 0, "symbol must not be empty"
            assert len(api_response['name']) > 0, "name must not be empty"
            assert api_response['price'] >= 0, "price must be non-negative"
            assert 'T' in api_response['lastUpdated'], "lastUpdated must be ISO format"
            assert api_response['lastUpdated'].endswith('Z'), "lastUpdated must end with 'Z'"
            
            # Assert numeric precision constraints (from design doc)
            # Price should be rounded to 2 decimal places
            price_str = str(api_response['price'])
            if '.' in price_str:
                decimal_places = len(price_str.split('.')[1])
                assert decimal_places <= 2, f"price should have at most 2 decimal places, got {decimal_places}"
            
            # Change24h should be rounded to 1 decimal place
            change_str = str(api_response['change24h'])
            if '.' in change_str:
                decimal_places = len(change_str.split('.')[1])
                assert decimal_places <= 1, f"change24h should have at most 1 decimal place, got {decimal_places}"
    
    @settings(max_examples=100)
    @given(
        symbols=st.lists(valid_symbols, min_size=1, max_size=10, unique=True)
    )
    def test_coingecko_ids_conversion(self, symbols):
        """
        Property: Converting symbols to CoinGecko IDs should produce valid,
        comma-separated IDs that can be used in API requests.
        """
        result = get_coingecko_ids(symbols)
        
        # Should return a string
        assert isinstance(result, str)
        
        # Should contain comma-separated values if multiple symbols
        if len(symbols) > 1:
            assert ',' in result
        
        # Each ID should be valid
        ids = result.split(',')
        assert len(ids) == len(symbols)
        
        for coingecko_id in ids:
            # Should be non-empty
            assert len(coingecko_id) > 0
            # Should be a valid CoinGecko ID
            assert coingecko_id in [cg_id for cg_id, _ in SYMBOL_TO_COINGECKO_ID.values()]
    
    @settings(max_examples=100)
    @given(symbol=valid_symbols)
    def test_symbol_name_lookup(self, symbol):
        """
        Property: For any supported symbol, get_symbol_name should return
        a non-empty name string.
        """
        name = get_symbol_name(symbol)
        
        assert isinstance(name, str)
        assert len(name) > 0
        assert name == SYMBOL_TO_COINGECKO_ID[symbol][1]
    
    @settings(max_examples=100)
    @given(symbol=valid_symbols)
    def test_supported_symbol_check(self, symbol):
        """
        Property: All symbols in SYMBOL_TO_COINGECKO_ID should be
        recognized as supported.
        """
        assert is_supported_symbol(symbol) is True
    
    @settings(max_examples=100)
    @given(
        symbol=st.text(
            alphabet=st.characters(blacklist_categories=('Cs',)),
            min_size=1,
            max_size=10
        ).filter(lambda s: s not in SYMBOL_TO_COINGECKO_ID)
    )
    def test_unsupported_symbol_check(self, symbol):
        """
        Property: Symbols not in SYMBOL_TO_COINGECKO_ID should be
        recognized as unsupported.
        """
        assert is_supported_symbol(symbol) is False
    
    @settings(max_examples=100)
    @given(response_data=coingecko_response_strategy())
    def test_external_api_response_coingecko_type(self, response_data):
        """
        Property: transform_external_api_response with 'coingecko' type
        should produce the same result as transform_coingecko_response.
        """
        timestamp = datetime(2024, 1, 15, 10, 30, 0)
        
        result1 = transform_external_api_response(response_data, 'coingecko', timestamp)
        result2 = transform_coingecko_response(response_data, timestamp)
        
        # Should produce identical results
        assert len(result1) == len(result2)
        
        for price1, price2 in zip(result1, result2):
            assert price1.symbol == price2.symbol
            assert price1.name == price2.name
            assert price1.price == price2.price
            assert price1.change24h == price2.change24h
            assert price1.market_cap == price2.market_cap
            assert price1.last_updated == price2.last_updated
