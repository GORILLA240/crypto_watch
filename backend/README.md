# Crypto Watch Backend

Serverless AWS backend for cryptocurrency price data, optimized for smartwatch clients.

## Architecture

- **API Gateway**: RESTful API endpoints
- **Lambda Functions**: 
  - API Lambda: Handles price requests
  - Price Update Lambda: Fetches and updates prices every 5 minutes
- **DynamoDB**: Single-table design for price data, API keys, and rate limiting
- **EventBridge**: Scheduled price updates

## Project Structure

```
backend/
├── src/
│   ├── api/              # API Lambda function
│   │   ├── handler.py
│   │   └── requirements.txt
│   ├── update/           # Price Update Lambda function
│   │   ├── handler.py
│   │   └── requirements.txt
│   └── shared/           # Shared utilities
│       ├── __init__.py
│       ├── auth.py
│       ├── cache.py
│       ├── db.py
│       ├── errors.py
│       ├── external_api.py
│       ├── models.py
│       └── utils.py
├── tests/
│   ├── unit/
│   │   ├── test_api.py
│   │   ├── test_update.py
│   │   └── test_shared.py
│   └── integration/
│       └── test_e2e.py
├── template.yaml         # AWS SAM template
├── samconfig.toml        # SAM CLI configuration
├── requirements-dev.txt  # Development dependencies
└── README.md
```

## Prerequisites

- Python 3.11+
- AWS SAM CLI
- AWS CLI configured with credentials
- Docker (for local testing)

## Setup

1. Create virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements-dev.txt
```

3. Build the application:
```bash
sam build
```

4. Run locally:
```bash
sam local start-api
```

## Deployment

### Quick Deployment

Use the deployment script for automated deployment:

```bash
# Deploy to development
./scripts/deploy.sh dev

# Deploy to staging
./scripts/deploy.sh staging

# Deploy to production
./scripts/deploy.sh prod
```

The deployment script will:
1. Run all tests
2. Build the SAM application
3. Deploy to the specified environment
4. Display stack outputs

### Manual Deployment

#### Development Environment
```bash
sam build
sam deploy --config-file samconfig-dev.toml --config-env dev
```

#### Staging Environment
```bash
sam build
sam deploy --config-file samconfig-staging.toml --config-env staging
```

#### Production Environment
```bash
sam build
sam deploy --config-file samconfig-prod.toml --config-env prod
```

### First-Time Deployment

For first-time deployment, use guided mode:

```bash
sam build
sam deploy --guided
```

This will prompt you for:
- Stack name
- AWS Region
- Parameter values
- Confirmation before deployment

### Deployment Configuration

Environment-specific configurations are stored in:
- `samconfig-dev.toml` - Development environment
- `samconfig-staging.toml` - Staging environment
- `samconfig-prod.toml` - Production environment

Each configuration includes:
- Stack name
- S3 bucket for artifacts
- Parameter overrides (rate limits, cache TTL, log level)
- Resource tags

### Post-Deployment Setup

After deploying, you need to create API keys:

```bash
# Create a development API key
python scripts/setup-api-key.py --name "Development Key" --environment dev

# Create a production API key
python scripts/setup-api-key.py --name "Production App" --environment prod
```

See [API Key Management](docs/API_KEY_MANAGEMENT.md) for more details.

### Deployment Outputs

After successful deployment, you'll see:
- **ApiEndpoint**: The API Gateway URL
- **ApiFunctionArn**: ARN of the API Lambda function
- **UpdateFunctionArn**: ARN of the Price Update Lambda function
- **DynamoDBTableName**: Name of the DynamoDB table

Example:
```
ApiEndpoint: https://abc123.execute-api.us-east-1.amazonaws.com/Prod/
```

### Testing the Deployment

Test the deployed API:

```bash
# Get your API key from the setup script output
API_KEY="your-api-key-here"
API_URL="your-api-gateway-url"

# Test health endpoint (no auth required)
curl $API_URL/health

# Test prices endpoint
curl -H "X-API-Key: $API_KEY" "$API_URL/prices?symbols=BTC,ETH"
```

## Testing

Run unit tests:
```bash
pytest tests/unit/ -v
```

Run property-based tests:
```bash
pytest tests/unit/ -v -m property
```

Run integration tests:
```bash
pytest tests/integration/ -v
```

Run all tests with coverage:
```bash
pytest --cov=src --cov-report=html
```

## Environment Variables

### API Lambda
- `DYNAMODB_TABLE_NAME`: DynamoDB table name
- `RATE_LIMIT_PER_MINUTE`: Maximum requests per minute (default: 100)
- `CACHE_TTL_SECONDS`: Cache time-to-live (default: 300)
- `ENVIRONMENT`: Deployment environment (dev/staging/prod)

### Price Update Lambda
- `DYNAMODB_TABLE_NAME`: DynamoDB table name
- `EXTERNAL_API_URL`: External crypto price API URL
- `EXTERNAL_API_KEY`: API key for external service
- `SUPPORTED_SYMBOLS`: Comma-separated list of cryptocurrency symbols
- `ENVIRONMENT`: Deployment environment (dev/staging/prod)

## API Endpoints

### GET /prices

Get current prices for multiple cryptocurrencies.

**Query Parameters:**
- `symbols` (required): Comma-separated list of cryptocurrency symbols (e.g., `BTC,ETH,ADA`)

**Headers:**
- `X-API-Key` (required): Your API key
- `Accept-Encoding` (optional): Set to `gzip` for compressed responses

**Example Request:**
```bash
curl -H "X-API-Key: your-api-key" \
     "https://api.example.com/prices?symbols=BTC,ETH"
```

**Example Response:**
```json
{
  "data": [
    {
      "symbol": "BTC",
      "name": "Bitcoin",
      "price": 45000.50,
      "change24h": 2.5,
      "marketCap": 850000000000,
      "lastUpdated": "2024-01-15T10:30:00Z"
    },
    {
      "symbol": "ETH",
      "name": "Ethereum",
      "price": 3000.25,
      "change24h": -1.2,
      "marketCap": 360000000000,
      "lastUpdated": "2024-01-15T10:30:00Z"
    }
  ],
  "timestamp": "2024-01-15T10:30:05Z"
}
```

### GET /prices/{symbol}

Get current price for a single cryptocurrency.

**Path Parameters:**
- `symbol` (required): Cryptocurrency symbol (e.g., `BTC`)

**Headers:**
- `X-API-Key` (required): Your API key

**Example Request:**
```bash
curl -H "X-API-Key: your-api-key" \
     "https://api.example.com/prices/BTC"
```

### GET /health

Health check endpoint (no authentication required).

**Example Request:**
```bash
curl "https://api.example.com/health"
```

**Example Response (Healthy):**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "checks": {
    "dynamodb": "ok",
    "lastPriceUpdate": "2024-01-15T10:25:00Z",
    "cacheAge": 300
  }
}
```

**Example Response (Unhealthy):**
```json
{
  "status": "unhealthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "checks": {
    "dynamodb": "error",
    "lastPriceUpdate": "2024-01-15T09:00:00Z",
    "cacheAge": 5400
  },
  "error": "DynamoDB connection failed"
}
```

### Error Responses

All error responses follow a consistent format:

```json
{
  "error": "Human-readable error message",
  "code": "ERROR_CODE_CONSTANT",
  "timestamp": "2024-01-15T10:30:00Z",
  "requestId": "uuid-v4"
}
```

**Common Error Codes:**
- `400 Bad Request`: Invalid parameters or unsupported symbols
- `401 Unauthorized`: Missing or invalid API key
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Unexpected server error
- `503 Service Unavailable`: External API or DynamoDB unavailable

### Rate Limiting

- **Limit**: 100 requests per minute per API key (configurable)
- **Window**: Rolling 1-minute window
- **Response**: 429 status code with `retryAfter` field

**Rate Limit Response:**
```json
{
  "error": "Rate limit exceeded",
  "code": "RATE_LIMIT_EXCEEDED",
  "retryAfter": 60,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Supported Cryptocurrencies

The API supports the following cryptocurrencies:
- BTC (Bitcoin)
- ETH (Ethereum)
- ADA (Cardano)
- BNB (Binance Coin)
- XRP (Ripple)
- SOL (Solana)
- DOT (Polkadot)
- DOGE (Dogecoin)
- AVAX (Avalanche)
- MATIC (Polygon)
- LINK (Chainlink)
- UNI (Uniswap)
- LTC (Litecoin)
- ATOM (Cosmos)
- XLM (Stellar)
- ALGO (Algorand)
- VET (VeChain)
- ICP (Internet Computer)
- FIL (Filecoin)
- TRX (TRON)

## Monitoring

- CloudWatch Logs: `/aws/lambda/crypto-watch-api` and `/aws/lambda/crypto-watch-update`
- CloudWatch Metrics: Custom metrics for API requests, latency, and errors
- CloudWatch Alarms: Configured for automatic rollback on deployment issues

## License

MIT
