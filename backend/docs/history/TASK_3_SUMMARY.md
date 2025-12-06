# Task 3 Implementation Summary: Cache Management Logic

## Overview
Implemented comprehensive cache management system with TTL calculation, freshness checking, and high-level cache operations integrated with DynamoDB.

## Implementation Details

### 1. Cache Utilities Module (`src/shared/cache.py`)

Created cache management utilities with the following functionality:

#### Core Functions

**`calculate_ttl(duration_seconds=3600)`**:
- Calculates Unix timestamp for DynamoDB TTL
- Default: 1 hour (3600 seconds)
- Returns: current_time + duration

**`is_cache_fresh(last_updated, threshold_minutes=5)`**:
- Checks if cached data is within freshness threshold
- Default threshold: 5 minutes (as per requirements)
- Handles timezone-aware and naive datetimes
- Returns: True if fresh, False if stale

**`get_cache_age_seconds(last_updated)`**:
- Calculates age of cached data in seconds
- Useful for monitoring and logging
- Returns: float (seconds since last update)

**`should_refresh_cache(last_updated, threshold_minutes=5)`**:
- Determines if cache refresh is needed
- Returns True if: no cache exists OR cache is stale
- Returns False if: cache exists and is fresh

### 2. CacheManager Class

High-level cache manager that integrates cache logic with DynamoDB operations:

#### Key Methods

**`get_fresh_price_data(symbol, threshold_minutes=5)`**:
- Retrieves price data only if fresh
- Returns None if stale or missing
- Single symbol operation

**`get_fresh_multiple_price_data(symbols, threshold_minutes=5)`**:
- Retrieves fresh data for multiple symbols
- Returns dictionary of symbol → CryptoPrice
- Only includes fresh data (filters out stale)

**`cache_price_data(price_data, ttl_seconds=3600)`**:
- Stores single price data with TTL
- Default TTL: 1 hour

**`cache_multiple_price_data(price_data_list, ttl_seconds=3600)`**:
- Batch stores multiple price data items
- More efficient than individual saves

**`should_refresh_symbol(symbol, threshold_minutes=5)`**:
- Checks if specific symbol needs refresh
- Returns True if cache missing or stale

**`get_cache_status(symbols, threshold_minutes=5)`**:
- Returns detailed cache status for multiple symbols
- Includes: exists, is_fresh, age_seconds, last_updated, needs_refresh
- Useful for debugging and monitoring

## Cache Strategy

### 5-Minute Freshness Threshold

The system uses a 5-minute cache freshness threshold (configurable):
- Data updated < 5 minutes ago: **FRESH** → Use cached data
- Data updated ≥ 5 minutes ago: **STALE** → Fetch new data
- No data exists: **MISSING** → Fetch new data

### TTL Configuration

- **Price Data**: 1 hour TTL (3600 seconds)
  - Automatically removed by DynamoDB after 1 hour
  - Prevents stale data accumulation
  
- **Rate Limit Data**: 1 hour TTL (3600 seconds)
  - Old rate limit records automatically cleaned up
  - Keeps table size manageable

### Cache-First Strategy

1. Check cache for requested symbols
2. Identify fresh vs. stale data
3. Return fresh data immediately
4. Fetch only stale/missing data from external API
5. Update cache with new data
6. Return combined result

## Test Coverage

### Unit Tests (`tests/unit/test_shared.py`)

**Cache Utility Tests** (8 tests):
1. ✅ `test_calculate_ttl`: TTL calculation accuracy
2. ✅ `test_calculate_ttl_custom_duration`: Custom duration support
3. ✅ `test_is_cache_fresh_within_threshold`: Fresh data detection
4. ✅ `test_is_cache_fresh_beyond_threshold`: Stale data detection
5. ✅ `test_is_cache_fresh_no_timezone`: Timezone handling
6. ✅ `test_get_cache_age_seconds`: Age calculation
7. ✅ `test_should_refresh_cache_no_data`: Missing cache handling
8. ✅ `test_should_refresh_cache_fresh_data`: Fresh cache handling
9. ✅ `test_should_refresh_cache_stale_data`: Stale cache handling

**All tests passing**: 9/9 ✅

## Requirements Validated

✅ **Requirement 2.1**: Cache-first strategy
- `is_cache_fresh()` implements 5-minute threshold
- CacheManager returns cached data when fresh

✅ **Requirement 2.2**: Cache invalidation
- `should_refresh_cache()` triggers refresh for stale data
- Automatic refresh when threshold exceeded

✅ **Requirement 2.4**: Timestamp persistence
- `calculate_ttl()` generates proper TTL values
- All cache operations include timestamps

✅ **Requirement 3.2**: Data storage with timestamp
- CacheManager stores lastUpdated with all price data
- TTL automatically calculated and applied

## Design Decisions

1. **Configurable Thresholds**: Freshness threshold can be adjusted per environment
2. **Timezone Handling**: Automatically handles both timezone-aware and naive datetimes
3. **Batch Operations**: Supports efficient multi-symbol operations
4. **Status Reporting**: Detailed cache status for monitoring
5. **Separation of Concerns**: Cache logic separate from DynamoDB operations
6. **Type Safety**: Full type hints for better IDE support

## Integration Points

The cache management system integrates with:
- **DynamoDB Client** (`db.py`): For data persistence
- **Data Models** (`models.py`): CryptoPrice with timestamps
- **API Lambda** (`api/handler.py`): Cache-first request handling
- **Update Lambda** (`update/handler.py`): Cache updates after fetching

## Usage Example

```python
from src.shared.cache import CacheManager

# Initialize cache manager
cache = CacheManager()

# Check if refresh needed
if cache.should_refresh_symbol('BTC', threshold_minutes=5):
    # Fetch from external API
    new_data = fetch_from_external_api('BTC')
    # Cache the new data
    cache.cache_price_data(new_data, ttl_seconds=3600)
else:
    # Use cached data
    cached_data = cache.get_fresh_price_data('BTC')

# Get status for multiple symbols
status = cache.get_cache_status(['BTC', 'ETH', 'ADA'])
for symbol, info in status.items():
    print(f"{symbol}: fresh={info['is_fresh']}, age={info['age_seconds']}s")
```

## Files Created

1. **Created**: `backend/src/shared/cache.py` (200+ lines)
2. **Modified**: `backend/tests/unit/test_shared.py` (added cache tests)

## Performance Considerations

- **Batch Operations**: Reduces DynamoDB API calls
- **Fresh Data Check**: Avoids unnecessary external API calls
- **TTL Automation**: DynamoDB handles cleanup (no manual deletion needed)
- **Efficient Queries**: Uses primary key lookups (not scans)

## Next Steps

Cache management is now ready for:
- Task 4: External API integration (cache updates)
- Task 5: Price Update Lambda (periodic cache refresh)
- Task 8: API Lambda (cache-first reads)

## Notes

- 5-minute threshold balances freshness vs. API call costs
- 1-hour TTL prevents indefinite data accumulation
- Timezone handling ensures correct freshness calculations
- CacheManager provides high-level interface for common operations
- Detailed status reporting aids in debugging and monitoring
