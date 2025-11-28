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

### Development Environment
```bash
sam deploy --config-env dev
```

### Staging Environment
```bash
sam deploy --config-env staging
```

### Production Environment
```bash
sam deploy --config-env prod
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

- `GET /prices?symbols=BTC,ETH` - Get current prices for specified cryptocurrencies
- `GET /prices/{symbol}` - Get current price for a single cryptocurrency
- `GET /health` - Health check endpoint (no authentication required)

## Monitoring

- CloudWatch Logs: `/aws/lambda/crypto-watch-api` and `/aws/lambda/crypto-watch-update`
- CloudWatch Metrics: Custom metrics for API requests, latency, and errors
- CloudWatch Alarms: Configured for automatic rollback on deployment issues

## License

MIT
