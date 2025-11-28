# Project Structure

This document provides a detailed overview of the Crypto Watch Backend project structure.

## Directory Tree

```
backend/
├── src/                          # Source code
│   ├── api/                      # API Lambda function
│   │   ├── handler.py           # API request handler
│   │   └── requirements.txt     # API function dependencies
│   │
│   ├── update/                   # Price Update Lambda function
│   │   ├── handler.py           # Price update handler
│   │   └── requirements.txt     # Update function dependencies
│   │
│   └── shared/                   # Shared utilities (Lambda Layer)
│       ├── __init__.py          # Package initialization
│       ├── auth.py              # Authentication & rate limiting
│       ├── cache.py             # Cache management utilities
│       ├── db.py                # DynamoDB operations
│       ├── errors.py            # Error handling & custom exceptions
│       ├── external_api.py      # External API client with retry logic
│       ├── models.py            # Data models (CryptoPrice, APIKey, etc.)
│       └── utils.py             # General utilities (logging, timestamps)
│
├── tests/                        # Test suite
│   ├── unit/                    # Unit tests
│   │   ├── __init__.py
│   │   ├── test_api.py         # API Lambda tests
│   │   ├── test_update.py      # Update Lambda tests
│   │   └── test_shared.py      # Shared utilities tests
│   │
│   ├── integration/             # Integration tests
│   │   ├── __init__.py
│   │   └── test_e2e.py         # End-to-end tests
│   │
│   ├── __init__.py
│   └── conftest.py              # Pytest fixtures and configuration
│
├── events/                       # Sample events for local testing
│   ├── api-event.json           # Sample API Gateway event
│   └── update-event.json        # Sample EventBridge event
│
├── scripts/                      # Utility scripts
│   ├── deploy.sh                # Deployment script
│   └── setup-api-key.py         # API key generation script
│
├── .aws-sam/                     # SAM build artifacts (gitignored)
├── venv/                         # Python virtual environment (gitignored)
├── htmlcov/                      # Coverage reports (gitignored)
│
├── template.yaml                 # AWS SAM CloudFormation template
├── samconfig.toml               # SAM CLI configuration
├── requirements-dev.txt         # Development dependencies
├── pytest.ini                   # Pytest configuration
├── pyproject.toml               # Python project configuration
├── .flake8                      # Flake8 linter configuration
├── .gitignore                   # Git ignore rules
├── Makefile                     # Common development commands
├── .env.example                 # Example environment variables
├── README.md                    # Project overview
├── SETUP.md                     # Setup instructions
└── STRUCTURE.md                 # This file
```

## Key Files

### Infrastructure

- **template.yaml**: AWS SAM template defining all infrastructure resources
  - DynamoDB table with GSI
  - API Lambda function with API Gateway integration
  - Price Update Lambda function with EventBridge schedule
  - CloudWatch alarms for monitoring
  - IAM roles and permissions

- **samconfig.toml**: SAM CLI configuration for different environments
  - Development environment settings
  - Staging environment settings
  - Production environment settings with CodeDeploy

### Source Code

#### API Lambda (`src/api/`)
- Handles HTTP requests from API Gateway
- Validates API keys
- Enforces rate limiting
- Retrieves cryptocurrency prices from DynamoDB
- Formats responses for smartwatch clients

#### Update Lambda (`src/update/`)
- Triggered by EventBridge every 5 minutes
- Fetches prices from external cryptocurrency API
- Implements retry logic with exponential backoff
- Updates DynamoDB with fresh price data

#### Shared Layer (`src/shared/`)
- **models.py**: Data classes for CryptoPrice, APIKey, RateLimit
- **db.py**: DynamoDB operations (get, put, query)
- **cache.py**: Cache freshness checking and TTL calculation
- **auth.py**: API key validation and rate limit enforcement
- **external_api.py**: External API client with retry logic
- **errors.py**: Custom exceptions and error response formatting
- **utils.py**: Logging, timestamp handling, API key masking

### Testing

- **tests/unit/**: Unit tests for individual functions and modules
- **tests/integration/**: End-to-end integration tests
- **tests/conftest.py**: Shared pytest fixtures
- **pytest.ini**: Pytest configuration and markers

### Configuration

- **requirements-dev.txt**: Development dependencies
  - pytest, hypothesis (testing)
  - black, flake8, mypy (code quality)
  - boto3, moto (AWS SDK and mocking)

- **pyproject.toml**: Python project metadata
  - Black formatter settings
  - MyPy type checker settings

- **.flake8**: Linter configuration
  - Line length: 100
  - Ignored rules for compatibility with Black

### Scripts

- **scripts/deploy.sh**: Automated deployment script
  - Runs tests before deployment
  - Validates SAM template
  - Deploys to specified environment

- **scripts/setup-api-key.py**: API key management
  - Generates cryptographically secure keys
  - Stores keys in DynamoDB

## Data Flow

### Read Path (API Request)
```
Client → API Gateway → API Lambda → DynamoDB → API Lambda → Client
                           ↓
                    Rate Limit Check
                    Cache Freshness Check
```

### Write Path (Price Update)
```
EventBridge → Update Lambda → External API → Update Lambda → DynamoDB
                                                    ↓
                                            Retry Logic (3 attempts)
```

## Environment Variables

### API Lambda
- `DYNAMODB_TABLE_NAME`: DynamoDB table name
- `RATE_LIMIT_PER_MINUTE`: Max requests per minute (default: 100)
- `CACHE_TTL_SECONDS`: Cache TTL in seconds (default: 300)
- `ENVIRONMENT`: Deployment environment (dev/staging/prod)
- `LOG_LEVEL`: Logging level (DEBUG/INFO/ERROR)

### Update Lambda
- `DYNAMODB_TABLE_NAME`: DynamoDB table name
- `EXTERNAL_API_URL`: External crypto API URL
- `EXTERNAL_API_KEY`: External API key (if required)
- `SUPPORTED_SYMBOLS`: Comma-separated cryptocurrency symbols
- `ENVIRONMENT`: Deployment environment
- `LOG_LEVEL`: Logging level

## DynamoDB Schema

### Table: crypto-watch-data-{environment}

**Primary Key:**
- PK (Partition Key): String
- SK (Sort Key): String

**GSI1:**
- GSI1PK (Partition Key): String
- GSI1SK (Sort Key): String

**Item Types:**

1. **Price Data**
   - PK: `PRICE#{symbol}`
   - SK: `METADATA`
   - Attributes: symbol, name, price, change24h, marketCap, lastUpdated, ttl

2. **API Key**
   - PK: `APIKEY#{keyId}`
   - SK: `METADATA`
   - Attributes: keyId, name, createdAt, enabled, lastUsedAt

3. **Rate Limit**
   - PK: `APIKEY#{keyId}`
   - SK: `RATELIMIT#{minute}`
   - Attributes: requestCount, ttl

## API Endpoints

- `GET /prices?symbols=BTC,ETH` - Get prices for multiple cryptocurrencies
- `GET /prices/{symbol}` - Get price for single cryptocurrency
- `GET /health` - Health check (no authentication)

## Development Commands

```bash
# Setup
make install              # Install dependencies

# Testing
make test                 # Run all tests
make test-unit           # Run unit tests
make test-property       # Run property-based tests

# Code Quality
make format              # Format code with Black
make lint                # Run linters

# Local Development
make build               # Build SAM application
make local               # Start API locally

# Deployment
make deploy-dev          # Deploy to development
make deploy-staging      # Deploy to staging
make deploy-prod         # Deploy to production

# Cleanup
make clean               # Remove build artifacts
```

## Next Steps

1. Implement data models and DynamoDB operations (Task 2)
2. Implement cache management logic (Task 3)
3. Implement external API client with retry logic (Task 4)
4. Implement Lambda handlers (Tasks 5, 7)
5. Implement authentication and rate limiting (Task 6)
6. Add comprehensive tests (Tasks 2.1-10.1)
7. Set up CI/CD pipeline (Task 17)
