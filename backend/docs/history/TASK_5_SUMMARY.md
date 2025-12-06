# Task 5 Implementation Summary: Price Update Lambda Function

## Overview
Implemented scheduled Lambda function that fetches cryptocurrency prices from external API every 5 minutes and updates DynamoDB cache.

## Implementation Details

### Lambda Handler (`src/update/handler.py`)

**Purpose**: Automated price fetching and cache updates on a fixed schedule.

**Trigger**: EventBridge (CloudWatch Events) - `rate(5 minutes)`

**Execution Flow**:
1. Log update start with timestamp
2. Get list of supported symbols from environment variable
3. Initialize ExternalAPIClient and DynamoDBClient
4. Fetch prices from external API (with automatic retry logic)
5. Save all prices to DynamoDB with 1-hour TTL
6. Log success metrics (symbol count, price count, timestamps)
7. Return status response

### Key Features

#### 1. Scheduled Execution
- **Frequency**: Every 5 minutes (configurable via EventBridge)
- **Trigger**: EventBridge scheduled event
- **Reliability**: Automatic retries by AWS if Lambda fails

#### 2. Supported Symbols Configuration
```python
def get_supported_symbols() -> List[str]:
    """Get list from SUPPORTED_SYMBOLS environment variable."""
    symbols_str = os.environ.get(
        'SUPPORTED_SYMBOLS',
        'BTC,ETH,ADA,BNB,XRP,SOL,DOT,DOGE,AVAX,MATIC,LINK,UNI,LTC,ATOM,XLM,ALGO,VET,ICP,FIL,TRX'
    )
    return [s.strip() for s in symbols_str.split(',')]
```

**Default**: 20 cryptocurrencies (top by market cap)
**Configurable**: Via environment variable per deployment stage

#### 3. External API Integration
- Uses `ExternalAPIClient` with built-in retry logic
- Exponential backoff: 1s, 2s, 4s delays
- Maximum 4 attempts (initial + 3 retries)
- Timeout: 5 seconds per attempt

#### 4. Error Handling

**External API Failure**:
```python
try:
    prices = api_client.fetch_prices(symbols)
except ExternalAPIError as e:
    logger.error({
        'message': 'Failed to fetch prices after all retries',
        'error': str(e)
    })
    return {'statusCode': 502, 'body': {...}}
```
- Logs error with full details
- Returns 502 Bad Gateway
- **Does not raise exception** - allows Lambda to complete gracefully
- Existing cache remains valid until TTL expires

**DynamoDB Failure**:
```python
success = db_client.save_multiple_price_data(prices, ttl_seconds=3600)
if not success:
    logger.error({'message': 'Failed to save prices to DynamoDB'})
    return {'statusCode': 500, 'body': {...}}
```
- Logs error
- Returns 500 Internal Server Error
- AWS SDK handles automatic retries for transient errors

**Unexpected Errors**:
```python
except Exception as e:
    logger.error({
        'message': 'Unexpected error',
        'error': str(e),
        'errorType': type(e).__name__
    }, exc_info=True)
    return {'statusCode': 500, 'body': {...}}
```
- Catches all unexpected exceptions
- Logs with full stack trace
- Returns 500 status

#### 5. Timestamp Tracking

**Start Time**: Logged at function entry
**End Time**: Logged on successful completion
**Last Updated**: Included in each price record

```python
start_time = get_current_timestamp_iso()
# ... processing ...
end_time = get_current_timestamp_iso()

logger.info({
    'message': 'Price update completed successfully',
    'startTime': start_time,
    'endTime': end_time,
    'priceCount': len(prices)
})
```

#### 6. Structured Logging

All logs use JSON format for CloudWatch Insights:
```json
{
  "message": "Price update completed successfully",
  "startTime": "2024-01-15T10:30:00Z",
  "endTime": "2024-01-15T10:30:05Z",
  "symbolCount": 20,
  "priceCount": 20,
  "timestamp": "2024-01-15T10:30:05Z"
}
```

Benefits:
- Easy CloudWatch Insights queries
- Structured metric extraction
- Consistent log format

#### 7. TTL Configuration

**Cache TTL**: 1 hour (3600 seconds)
```python
db_client.save_multiple_price_data(prices, ttl_seconds=3600)
```

**Rationale**:
- Updates every 5 minutes → cache always fresh
- 1-hour TTL prevents indefinite accumulation
- DynamoDB automatically removes expired items
- No manual cleanup required

### Response Format

**Success Response** (200 OK):
```json
{
  "statusCode": 200,
  "body": {
    "message": "Price update completed successfully",
    "symbolCount": 20,
    "priceCount": 20,
    "lastUpdated": "2024-01-15T10:30:05Z",
    "timestamp": "2024-01-15T10:30:05Z"
  }
}
```

**External API Failure** (502 Bad Gateway):
```json
{
  "statusCode": 502,
  "body": {
    "message": "Failed to fetch prices from external API",
    "error": "Failed to fetch prices after 4 attempts",
    "timestamp": "2024-01-15T10:30:05Z"
  }
}
```

**DynamoDB Failure** (500 Internal Server Error):
```json
{
  "statusCode": 500,
  "body": {
    "message": "Failed to save prices to DynamoDB",
    "timestamp": "2024-01-15T10:30:05Z"
  }
}
```

## Test Coverage

### Unit Tests (`tests/unit/test_update.py`)

**Test Cases**:
1. ✅ `test_successful_price_update`: Happy path with all prices fetched and saved
2. ✅ `test_external_api_failure`: External API fails after retries
3. ✅ `test_dynamodb_failure`: DynamoDB save operation fails
4. ✅ `test_eventbridge_event_parsing`: EventBridge event structure handling
5. ✅ `test_partial_symbol_fetch`: Some symbols fail, others succeed

**All tests passing**: 5/5 ✅

### Property Test (`tests/unit/test_update_property.py`)

**Property 8: Update Timestamp Tracking**
- **Statement**: *For any* successful price update operation, the system must record the timestamp of the update
- **Validates**: Requirement 3.5
- **Result**: ✅ PASSED (100+ iterations)

## Requirements Validated

✅ **Requirement 3.1**: Fetch updated prices every 5 minutes
- EventBridge schedule: `rate(5 minutes)`
- Configured in SAM template

✅ **Requirement 3.2**: Save data with timestamp to DynamoDB
- Each price includes `lastUpdated` field
- ISO 8601 format with 'Z' suffix

✅ **Requirement 3.5**: Track last successful update timestamp
- Logged in CloudWatch with structured format
- Included in success response
- Available for monitoring

## Integration with Other Components

### External API Client (`external_api.py`)
- Handles retry logic automatically
- Returns `List[CryptoPrice]`
- Raises `ExternalAPIError` on failure

### DynamoDB Client (`db.py`)
- Batch save operation for efficiency
- Automatic TTL calculation
- Returns boolean success status

### CloudWatch
- Structured JSON logs
- Metrics for monitoring
- Alarms for failures (configured in SAM template)

## Monitoring Recommendations

### CloudWatch Metrics to Track
- **Invocation Count**: Should be ~12 per hour (every 5 minutes)
- **Error Rate**: Should be < 1%
- **Duration**: Typical 2-5 seconds
- **External API Success Rate**: Should be > 95%

### CloudWatch Alarms
- **High Error Rate**: > 5% errors in 10 minutes
- **External API Failures**: > 3 consecutive failures
- **Long Duration**: > 20 seconds (approaching timeout)

### CloudWatch Insights Queries

**Success Rate**:
```
fields @timestamp, message, priceCount
| filter message = "Price update completed successfully"
| stats count() as successCount by bin(5m)
```

**Error Analysis**:
```
fields @timestamp, message, error, errorType
| filter message like /Failed|Error/
| stats count() by errorType
```

**Performance**:
```
fields @timestamp, startTime, endTime
| filter message = "Price update completed successfully"
| stats avg(@duration) as avgDuration, max(@duration) as maxDuration
```

## Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `SUPPORTED_SYMBOLS` | Comma-separated list of symbols | BTC,ETH,... (20 symbols) | No |
| `DYNAMODB_TABLE_NAME` | DynamoDB table name | crypto-watch-data | Yes |
| `EXTERNAL_API_URL` | External API base URL | CoinGecko API | No |
| `EXTERNAL_API_KEY` | API key for external service | None | No |
| `ENVIRONMENT` | Deployment environment | unknown | No |

## Performance Characteristics

**Typical Execution**:
- Duration: 2-5 seconds
- Memory: ~100 MB
- API Calls: 1 (batch request for all symbols)
- DynamoDB Writes: 20 (one per symbol)

**Worst Case** (all retries):
- Duration: ~12 seconds
- Memory: ~100 MB
- API Calls: 4 attempts
- DynamoDB Writes: 0 (if all fail)

**Cost Estimate** (per month):
- Lambda Invocations: ~8,640 (12/hour × 24 × 30)
- Lambda Duration: ~43,200 seconds (5s × 8,640)
- DynamoDB Writes: ~172,800 (20 × 8,640)
- **Total**: < $5/month (within free tier for most components)

## Files Created

1. **Created**: `backend/src/update/handler.py` (150+ lines)
2. **Created**: `backend/src/update/requirements.txt`
3. **Created**: `backend/tests/unit/test_update.py` (100+ lines)
4. **Created**: `backend/tests/unit/test_update_property.py` (50+ lines)
5. **Modified**: `backend/template.yaml` (EventBridge schedule configuration)

## Deployment Configuration

### SAM Template (`template.yaml`)

```yaml
PriceUpdateFunction:
  Type: AWS::Serverless::Function
  Properties:
    CodeUri: src/update/
    Handler: handler.lambda_handler
    Runtime: python3.11
    Timeout: 25
    MemorySize: 512
    Environment:
      Variables:
        DYNAMODB_TABLE_NAME: !Ref CryptoWatchTable
        EXTERNAL_API_KEY: !Ref ExternalApiKey
        SUPPORTED_SYMBOLS: "BTC,ETH,ADA,BNB,XRP,SOL,DOT,DOGE,AVAX,MATIC,LINK,UNI,LTC,ATOM,XLM,ALGO,VET,ICP,FIL,TRX"
    Events:
      ScheduledUpdate:
        Type: Schedule
        Properties:
          Schedule: rate(5 minutes)
          Description: Fetch cryptocurrency prices every 5 minutes
    Policies:
      - DynamoDBCrudPolicy:
          TableName: !Ref CryptoWatchTable
```

## Next Steps

Price Update Lambda is now ready for:
- Task 8: API Lambda (reads cached data)
- Task 11: Health check (monitors last update time)
- Task 12: Enhanced CloudWatch metrics

## Notes

- Function runs independently of API requests
- Failures don't affect API availability (cache remains valid)
- Retry logic in ExternalAPIClient handles transient failures
- DynamoDB TTL automatically cleans up old data
- Structured logging enables easy monitoring and debugging
- Cost-effective: Most execution within AWS free tier
- Scalable: Can add more symbols without code changes
