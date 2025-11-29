"""
Property-based tests for cache management functions.

Tests universal properties that should hold across all valid inputs.
"""

import pytest
from hypothesis import given, strategies as st, settings
from datetime import datetime, timezone, timedelta
from src.shared.cache import (
    is_cache_fresh,
    should_refresh_cache,
    get_cache_age_seconds,
    calculate_ttl
)


# Strategy for generating valid timestamps
def timestamp_strategy():
    """Generate valid datetime objects with timezone info."""
    return st.datetimes(
        min_value=datetime(2020, 1, 1),
        max_value=datetime(2030, 12, 31)
    ).map(lambda dt: dt.replace(tzinfo=timezone.utc))


# Strategy for generating timestamps without timezone (assumes UTC)
def naive_timestamp_strategy():
    """Generate valid datetime objects without timezone info."""
    # Generate timestamps in the past to avoid negative age calculations
    return st.datetimes(
        min_value=datetime(2020, 1, 1),
        max_value=datetime.now() - timedelta(seconds=1)  # At least 1 second in the past
    )


# Strategy for generating threshold values in minutes
threshold_minutes_strategy = st.integers(min_value=1, max_value=60)

# Strategy for generating age differences in seconds
age_seconds_strategy = st.integers(min_value=0, max_value=7200)  # 0 to 2 hours


@pytest.mark.property
class TestCacheProperties:
    """Property-based tests for cache management."""
    
    @settings(max_examples=100)
    @given(
        threshold_minutes=threshold_minutes_strategy,
        age_seconds=age_seconds_strategy
    )
    def test_property_2_cache_freshness_determines_data_source(self, threshold_minutes, age_seconds):
        """
        Feature: crypto-watch-backend, Property 2: Cache freshness determines data source
        
        Property: For any price data request, if cached data exists with a timestamp 
        less than threshold minutes old, the system should return cached data without 
        fetching from external API.
        
        Validates: Requirements 2.1
        """
        # Create a timestamp that is exactly age_seconds old
        current_time = datetime.now(timezone.utc)
        last_updated = current_time - timedelta(seconds=age_seconds)
        
        # Test cache freshness logic
        is_fresh = is_cache_fresh(last_updated, threshold_minutes)
        should_refresh = should_refresh_cache(last_updated, threshold_minutes)
        
        # Convert threshold to seconds for comparison
        threshold_seconds = threshold_minutes * 60
        
        # Property: Cache is fresh if and only if age is less than threshold
        if age_seconds < threshold_seconds:
            assert is_fresh is True, f"Data {age_seconds}s old should be fresh with {threshold_minutes}min threshold"
            assert should_refresh is False, f"Fresh data should not require refresh"
        else:
            assert is_fresh is False, f"Data {age_seconds}s old should be stale with {threshold_minutes}min threshold"
            assert should_refresh is True, f"Stale data should require refresh"
        
        # Property: is_cache_fresh and should_refresh_cache should be inverses
        assert is_fresh == (not should_refresh), "is_cache_fresh and should_refresh_cache should be inverses"
        
        # Property: Cache age calculation should be consistent
        calculated_age = get_cache_age_seconds(last_updated)
        # Allow small tolerance for test execution time (up to 1 second)
        assert abs(calculated_age - age_seconds) <= 1.0, f"Cache age calculation mismatch: expected ~{age_seconds}, got {calculated_age}"
    
    @settings(max_examples=100)
    @given(
        timestamp=naive_timestamp_strategy(),
        threshold_minutes=threshold_minutes_strategy
    )
    def test_cache_freshness_with_naive_timestamps(self, timestamp, threshold_minutes):
        """
        Property: Cache freshness logic should handle naive timestamps by assuming UTC.
        """
        # Test with naive timestamp (no timezone info)
        is_fresh = is_cache_fresh(timestamp, threshold_minutes)
        should_refresh = should_refresh_cache(timestamp, threshold_minutes)
        
        # Should not raise exceptions
        assert isinstance(is_fresh, bool)
        assert isinstance(should_refresh, bool)
        
        # Should be inverses
        assert is_fresh == (not should_refresh)
        
        # Age calculation should work
        age = get_cache_age_seconds(timestamp)
        assert isinstance(age, (int, float))
        assert age >= 0
    
    @settings(max_examples=100)
    @given(threshold_minutes=threshold_minutes_strategy)
    def test_none_timestamp_always_requires_refresh(self, threshold_minutes):
        """
        Property: When no cached data exists (None timestamp), refresh should always be required.
        """
        should_refresh = should_refresh_cache(None, threshold_minutes)
        
        # Property: No cache always requires refresh
        assert should_refresh is True, "Missing cache data should always require refresh"
    
    @settings(max_examples=100)
    @given(
        duration_seconds=st.integers(min_value=1, max_value=86400)  # 1 second to 1 day
    )
    def test_ttl_calculation_property(self, duration_seconds):
        """
        Property: TTL calculation should always return a timestamp in the future.
        """
        import time
        
        before_time = int(time.time())
        ttl = calculate_ttl(duration_seconds)
        after_time = int(time.time())
        
        # Property: TTL should be in the future
        assert ttl > before_time, "TTL should be greater than current time"
        
        # Property: TTL should be approximately current_time + duration
        expected_min = before_time + duration_seconds
        expected_max = after_time + duration_seconds
        assert expected_min <= ttl <= expected_max, f"TTL {ttl} should be between {expected_min} and {expected_max}"
    
    @settings(max_examples=100)
    @given(
        threshold1=st.integers(min_value=1, max_value=30),
        threshold2=st.integers(min_value=31, max_value=60)
    )
    def test_threshold_monotonicity(self, threshold1, threshold2):
        """
        Property: If data is fresh with a smaller threshold, it should also be fresh with a larger threshold.
        """
        # Generate a timestamp in the past
        current_time = datetime.now(timezone.utc)
        timestamp = current_time - timedelta(minutes=20)  # 20 minutes ago
        
        # Ensure threshold1 < threshold2
        if threshold1 >= threshold2:
            threshold1, threshold2 = threshold2, threshold1
        
        is_fresh_small = is_cache_fresh(timestamp, threshold1)
        is_fresh_large = is_cache_fresh(timestamp, threshold2)
        
        # Property: Monotonicity - if fresh with smaller threshold, must be fresh with larger threshold
        if is_fresh_small:
            assert is_fresh_large, f"Data fresh with {threshold1}min threshold should also be fresh with {threshold2}min threshold"
    
    @settings(max_examples=100)
    @given(
        offset_seconds=st.integers(min_value=0, max_value=3600),
        threshold_minutes=threshold_minutes_strategy
    )
    def test_temporal_consistency(self, offset_seconds, threshold_minutes):
        """
        Property: As time progresses, data should become less fresh (or stay the same freshness).
        """
        # Create two timestamps where timestamp2 is older than timestamp1
        current_time = datetime.now(timezone.utc)
        timestamp1 = current_time - timedelta(minutes=10)  # 10 minutes ago
        timestamp2 = timestamp1 - timedelta(seconds=offset_seconds)  # Even older
        
        is_fresh1 = is_cache_fresh(timestamp1, threshold_minutes)
        is_fresh2 = is_cache_fresh(timestamp2, threshold_minutes)
        
        # Property: Older data should not be fresher than newer data
        if is_fresh2:
            assert is_fresh1, "Newer data should be at least as fresh as older data"
        
        # Property: Age should increase with older timestamps
        age1 = get_cache_age_seconds(timestamp1)
        age2 = get_cache_age_seconds(timestamp2)
        
        # Allow small tolerance for test execution time
        assert age2 >= age1 - 1.0, f"Older timestamp should have greater age: age1={age1}, age2={age2}"
    
    @settings(max_examples=100)
    @given(
        threshold_minutes=threshold_minutes_strategy,
        age_seconds=age_seconds_strategy
    )
    def test_property_3_cache_invalidation_triggers_refresh(self, threshold_minutes, age_seconds):
        """
        Feature: crypto-watch-backend, Property 3: Cache invalidation triggers refresh
        
        Property: For any price data request, if cached data is older than threshold minutes 
        or does not exist, the system should fetch fresh data from the external API.
        
        This property is the inverse of Property 2 - it tests that stale or missing cache 
        triggers a refresh operation.
        
        Validates: Requirements 2.2
        """
        # Test Case 1: No cache exists (None timestamp) - should always require refresh
        should_refresh_no_cache = should_refresh_cache(None, threshold_minutes)
        assert should_refresh_no_cache is True, "Missing cache should always trigger refresh"
        
        # Test Case 2: Cache exists with specific age
        current_time = datetime.now(timezone.utc)
        last_updated = current_time - timedelta(seconds=age_seconds)
        
        # Calculate threshold in seconds
        threshold_seconds = threshold_minutes * 60
        
        # Test the refresh logic
        should_refresh = should_refresh_cache(last_updated, threshold_minutes)
        is_fresh = is_cache_fresh(last_updated, threshold_minutes)
        
        # Property: Cache older than threshold should trigger refresh
        if age_seconds >= threshold_seconds:
            assert should_refresh is True, f"Cache {age_seconds}s old should trigger refresh with {threshold_minutes}min threshold"
            assert is_fresh is False, f"Cache {age_seconds}s old should not be fresh with {threshold_minutes}min threshold"
        else:
            # Cache is fresh, should not trigger refresh
            assert should_refresh is False, f"Fresh cache {age_seconds}s old should not trigger refresh with {threshold_minutes}min threshold"
            assert is_fresh is True, f"Cache {age_seconds}s old should be fresh with {threshold_minutes}min threshold"
        
        # Property: should_refresh_cache should be the inverse of is_cache_fresh
        assert should_refresh == (not is_fresh), "should_refresh_cache and is_cache_fresh should be inverses"
        
        # Property: Boundary condition - exactly at threshold
        # Data at exactly threshold_seconds should be considered stale (>=, not >)
        if age_seconds == threshold_seconds:
            assert should_refresh is True, f"Cache exactly at threshold ({threshold_seconds}s) should trigger refresh"
            assert is_fresh is False, f"Cache exactly at threshold ({threshold_seconds}s) should not be fresh"
    
    @settings(max_examples=100)
    @given(
        threshold_minutes=st.integers(min_value=1, max_value=60),
        extra_seconds=st.integers(min_value=1, max_value=3600)
    )
    def test_stale_cache_always_requires_refresh(self, threshold_minutes, extra_seconds):
        """
        Property: Any cache older than the threshold should always require refresh.
        
        This is a focused test for Property 3 that ensures stale cache detection is reliable.
        """
        # Create a timestamp that is definitely stale (threshold + extra time)
        current_time = datetime.now(timezone.utc)
        threshold_seconds = threshold_minutes * 60
        stale_age_seconds = threshold_seconds + extra_seconds
        stale_timestamp = current_time - timedelta(seconds=stale_age_seconds)
        
        # Test that stale cache triggers refresh
        should_refresh = should_refresh_cache(stale_timestamp, threshold_minutes)
        is_fresh = is_cache_fresh(stale_timestamp, threshold_minutes)
        
        # Property: Stale cache must trigger refresh
        assert should_refresh is True, f"Cache {stale_age_seconds}s old (threshold: {threshold_seconds}s) should trigger refresh"
        assert is_fresh is False, f"Cache {stale_age_seconds}s old should not be fresh"
        
        # Property: Cache age should be greater than threshold
        cache_age = get_cache_age_seconds(stale_timestamp)
        assert cache_age >= threshold_seconds, f"Stale cache age {cache_age}s should be >= threshold {threshold_seconds}s"
    
    @settings(max_examples=100)
    @given(
        symbol=st.text(min_size=1, max_size=10, alphabet=st.characters(whitelist_categories=('Lu',))),
        name=st.text(min_size=1, max_size=50),
        price=st.floats(min_value=0.01, max_value=1000000.0, allow_nan=False, allow_infinity=False),
        change24h=st.floats(min_value=-100.0, max_value=1000.0, allow_nan=False, allow_infinity=False),
        market_cap=st.integers(min_value=1, max_value=10**15),
        ttl_seconds=st.integers(min_value=60, max_value=86400)
    )
    def test_property_4_timestamp_persistence(self, symbol, name, price, change24h, market_cap, ttl_seconds):
        """
        Feature: crypto-watch-backend, Property 4: Timestamp persistence
        
        Property: For any price update operation, the data stored in DynamoDB should 
        include a lastUpdated timestamp and a TTL value.
        
        This property ensures that when price data is saved to DynamoDB, it always 
        includes both a lastUpdated timestamp (for cache freshness checks) and a TTL 
        value (for automatic data expiration).
        
        Validates: Requirements 2.4, 3.2
        """
        from src.shared.models import CryptoPrice
        import time
        
        # Create a CryptoPrice instance with current timestamp
        current_time = datetime.now(timezone.utc)
        price_data = CryptoPrice(
            symbol=symbol,
            name=name,
            price=price,
            change24h=change24h,
            market_cap=market_cap,
            last_updated=current_time
        )
        
        # Convert to DynamoDB item format
        before_conversion = int(time.time())
        dynamodb_item = price_data.to_dynamodb_item(ttl_seconds)
        after_conversion = int(time.time())
        
        # Property 1: DynamoDB item must include lastUpdated timestamp
        assert 'lastUpdated' in dynamodb_item, "DynamoDB item must include lastUpdated field"
        assert dynamodb_item['lastUpdated'] is not None, "lastUpdated field must not be None"
        assert isinstance(dynamodb_item['lastUpdated'], str), "lastUpdated must be a string (ISO format)"
        
        # Property 2: lastUpdated timestamp should be in ISO format
        try:
            # Parse the timestamp to verify it's valid ISO format
            parsed_timestamp = datetime.fromisoformat(dynamodb_item['lastUpdated'].rstrip('Z'))
            assert parsed_timestamp is not None, "lastUpdated should be parseable as ISO timestamp"
        except (ValueError, AttributeError) as e:
            pytest.fail(f"lastUpdated timestamp is not valid ISO format: {e}")
        
        # Property 3: DynamoDB item must include TTL value
        assert 'ttl' in dynamodb_item, "DynamoDB item must include ttl field"
        assert dynamodb_item['ttl'] is not None, "ttl field must not be None"
        assert isinstance(dynamodb_item['ttl'], int), "ttl must be an integer (Unix timestamp)"
        
        # Property 4: TTL should be in the future (current_time + ttl_seconds)
        expected_ttl_min = before_conversion + ttl_seconds
        expected_ttl_max = after_conversion + ttl_seconds
        actual_ttl = dynamodb_item['ttl']
        
        assert expected_ttl_min <= actual_ttl <= expected_ttl_max, \
            f"TTL {actual_ttl} should be between {expected_ttl_min} and {expected_ttl_max}"
        
        # Property 5: TTL should be greater than current time
        assert actual_ttl > before_conversion, "TTL should be in the future"
        
        # Property 6: Round-trip consistency - data should be recoverable
        # Convert back from DynamoDB item to CryptoPrice
        recovered_price = CryptoPrice.from_dynamodb_item(dynamodb_item)
        
        # Verify all fields are preserved
        assert recovered_price.symbol == symbol, "Symbol should be preserved in round-trip"
        assert recovered_price.name == name, "Name should be preserved in round-trip"
        assert abs(recovered_price.price - price) < 0.01, "Price should be preserved in round-trip"
        assert abs(recovered_price.change24h - change24h) < 0.01, "Change24h should be preserved in round-trip"
        assert recovered_price.market_cap == market_cap, "Market cap should be preserved in round-trip"
        
        # Property 7: Timestamp should be preserved in round-trip (within 1 second tolerance)
        time_diff = abs((recovered_price.last_updated - current_time).total_seconds())
        assert time_diff < 1.0, f"Timestamp should be preserved in round-trip (diff: {time_diff}s)"
        
        # Property 8: All required DynamoDB keys should be present
        assert 'PK' in dynamodb_item, "DynamoDB item must include PK (partition key)"
        assert 'SK' in dynamodb_item, "DynamoDB item must include SK (sort key)"
        assert dynamodb_item['PK'] == f'PRICE#{symbol}', "PK should follow PRICE#<symbol> format"
        assert dynamodb_item['SK'] == 'METADATA', "SK should be METADATA for price data"