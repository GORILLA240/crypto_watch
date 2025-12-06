# Task 2 Implementation Summary: DynamoDB Table Design and Data Models

## Overview
Implemented DynamoDB table schema and Python data models for cryptocurrency prices, API keys, and rate limiting.

## Implementation Details

### 1. DynamoDB Table Schema (template.yaml)

Defined a single-table design with the following structure:

**Table Name**: `crypto-watch-data`

**Primary Key**:
- Partition Key: `PK` (String)
- Sort Key: `SK` (String)

**Global Secondary Index (GSI)**:
- GSI Name: `GSI1`
- Partition Key: `GSI1PK` (String)
- Sort Key: `GSI1SK` (String)

**TTL Configuration**:
- Enabled on `ttl` attribute
- Automatically removes expired items (cache data, rate limit records)

**Billing Mode**: PAY_PER_REQUEST (on-demand)

### 2. Data Models (src/shared/models.py)

#### CryptoPrice Model
Represents cryptocurrency price data with the following fields:
- `symbol`: Cryptocurrency symbol (e.g., "BTC")
- `name`: Full name (e.g., "Bitcoin")
- `price`: Current price (float)
- `change24h`: 24-hour percentage change (float)
- `market_cap`: Market capitalization (int)
- `last_updated`: Timestamp of last update (datetime)

**Key Methods**:
- `to_dict()`: Converts to API response format with numeric precision (price: 2 decimals, change24h: 1 decimal)
- `to_dynamodb_item()`: Converts to DynamoDB item format with TTL
- `from_dynamodb_item()`: Creates instance from DynamoDB item

**DynamoDB Format**:
```python
{
    'PK': 'PRICE#BTC',
    'SK': 'METADATA',
    'symbol': 'BTC',
    'name': 'Bitcoin',
    'price': 45000.50,
    'change24h': 2.5,
    'marketCap': 850000000000,
    'lastUpdated': '2024-01-15T10:30:00Z',
    'ttl': 1705318200
}
```

#### APIKey Model
Represents API key metadata:
- `key_id`: API key identifier
- `name`: Descriptive name
- `created_at`: Creation timestamp
- `enabled`: Whether key is active
- `last_used_at`: Last usage timestamp (optional)

**Key Methods**:
- `to_dynamodb_item()`: Converts to DynamoDB format
- `from_dynamodb_item()`: Creates instance from DynamoDB item

**DynamoDB Format**:
```python
{
    'PK': 'APIKEY#abc123',
    'SK': 'METADATA',
    'keyId': 'abc123',
    'name': 'Production App',
    'createdAt': '2024-01-01T00:00:00Z',
    'enabled': True,
    'lastUsedAt': '2024-01-15T10:30:00Z'  # Optional
}
```

#### RateLimit Model
Represents rate limiting tracking:
- `api_key`: API key identifier
- `minute`: Minute identifier (YYYYMMDDHHMM format)
- `request_count`: Number of requests in this minute
- `ttl`: Expiration timestamp

**Key Methods**:
- `to_dynamodb_item()`: Converts to DynamoDB format
- `from_dynamodb_item()`: Creates instance from DynamoDB item

**DynamoDB Format**:
```python
{
    'PK': 'APIKEY#abc123',
    'SK': 'RATELIMIT#202401151030',
    'requestCount': 45,
    'ttl': 1705318260
}
```

### 3. Data Transformation (src/shared/transformers.py)

Implemented functions to convert between external API format and internal format:

**Symbol Mapping**:
- Maps 20 cryptocurrency symbols to CoinGecko IDs
- Supports: BTC, ETH, ADA, BNB, XRP, SOL, DOT, DOGE, AVAX, MATIC, LINK, UNI, LTC, ATOM, XLM, ALGO, VET, ICP, FIL, TRX

**Key Functions**:
- `get_coingecko_ids(symbols)`: Converts symbols to CoinGecko IDs
- `transform_coingecko_response(data, timestamp)`: Transforms CoinGecko response to CryptoPrice list
- `transform_external_api_response(data, api_type, timestamp)`: Generic transformation interface
- `get_symbol_name(symbol)`: Gets full name for a symbol
- `is_supported_symbol(symbol)`: Checks if symbol is supported

**Transformation Example**:
```python
# External API format (CoinGecko)
{
    "bitcoin": {
        "usd": 45000.50,
        "usd_market_cap": 850000000000,
        "usd_24h_change": 2.5
    }
}

# Internal format (CryptoPrice)
CryptoPrice(
    symbol='BTC',
    name='Bitcoin',
    price=45000.50,
    change24h=2.5,
    market_cap=850000000000,
    last_updated=datetime(2024, 1, 15, 10, 30, 0)
)
```

## Access Patterns

The single-table design supports the following access patterns:

1. **Get price by symbol**: `PK = PRICE#BTC, SK = METADATA`
2. **Get all prices**: Query with `PK` begins_with `PRICE#`
3. **Get API key**: `PK = APIKEY#abc123, SK = METADATA`
4. **Get rate limit**: `PK = APIKEY#abc123, SK = RATELIMIT#202401151030`
5. **Get all rate limits for key**: Query with `PK = APIKEY#abc123, SK` begins_with `RATELIMIT#`

## Test Coverage

### Unit Tests (tests/unit/test_shared.py)

**CryptoPrice Model Tests** (6 tests):
- ✅ Initialization with valid data
- ✅ Conversion to dictionary with numeric precision
- ✅ Conversion to DynamoDB item with TTL
- ✅ Creation from DynamoDB item
- ✅ Round-trip conversion (model → DynamoDB → model)

**APIKey Model Tests** (6 tests):
- ✅ Initialization with and without last_used_at
- ✅ Conversion to DynamoDB item
- ✅ Creation from DynamoDB item with optional fields

**RateLimit Model Tests** (4 tests):
- ✅ Initialization
- ✅ Conversion to DynamoDB item
- ✅ Creation from DynamoDB item
- ✅ Round-trip conversion

**Transformer Tests** (11 tests):
- ✅ Symbol to CoinGecko ID conversion
- ✅ Single and multiple cryptocurrency transformation
- ✅ Handling missing fields with defaults
- ✅ Skipping unknown CoinGecko IDs
- ✅ Generic API transformation interface
- ✅ Symbol name lookup
- ✅ Symbol support checking

**Total**: 27 unit tests, all passing

## Requirements Validated

✅ **Requirement 1.2**: Data structure includes price, 24h change, market cap
- CryptoPrice model contains all required fields
- Numeric precision properly limited (price: 2 decimals, change24h: 1 decimal)

✅ **Requirement 2.4**: Timestamp persistence
- All models include timestamp fields
- TTL automatically calculated and stored

✅ **Requirement 3.2**: Data storage with timestamp
- DynamoDB items include lastUpdated field
- ISO format with 'Z' suffix for UTC

## Design Decisions

1. **Single-Table Design**: All entity types in one table for cost efficiency and performance
2. **Composite Keys**: PK/SK pattern enables flexible querying
3. **TTL Automation**: DynamoDB automatically removes expired items
4. **Numeric Precision**: Applied at model level (to_dict method) for consistency
5. **ISO Timestamps**: Standard format with 'Z' suffix for UTC clarity
6. **Dataclasses**: Used for clean, type-safe model definitions
7. **Bidirectional Conversion**: All models support to/from DynamoDB conversion

## Files Created/Modified

1. **Created**: `backend/src/shared/models.py` (200+ lines)
2. **Created**: `backend/src/shared/transformers.py` (150+ lines)
3. **Modified**: `backend/template.yaml` (DynamoDB table definition)
4. **Created**: `backend/tests/unit/test_shared.py` (partial - model tests)

## Next Steps

The data models are now ready for use in:
- Task 3: Cache management logic
- Task 4: External API integration
- Task 5: Price Update Lambda
- Task 6: Authentication and rate limiting
- Task 8: API Lambda function

## Notes

- All models use Python dataclasses for clean syntax
- Type hints throughout for better IDE support
- Comprehensive test coverage ensures reliability
- Transformation functions handle missing data gracefully
- Design supports future expansion (additional cryptocurrencies, new fields)
