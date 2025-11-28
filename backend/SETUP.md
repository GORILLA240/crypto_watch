# Setup Guide

This guide will help you set up the Crypto Watch Backend development environment.

## Prerequisites

Before you begin, ensure you have the following installed:

1. **Python 3.11 or higher**
   - Download from: https://www.python.org/downloads/
   - Verify installation: `python --version` or `python3 --version`

2. **AWS CLI**
   - Download from: https://aws.amazon.com/cli/
   - Configure with: `aws configure`

3. **AWS SAM CLI**
   - Installation guide: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
   - Verify installation: `sam --version`

4. **Docker** (for local testing)
   - Download from: https://www.docker.com/products/docker-desktop

## Initial Setup

### 1. Create Virtual Environment

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate
```

### 2. Install Dependencies

```bash
# Install development dependencies
pip install -r requirements-dev.txt

# Verify installation
pytest --version
sam --version
```

### 3. Configure Environment Variables

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your values
# Note: .env is gitignored and won't be committed
```

### 4. Validate SAM Template

```bash
# Validate the CloudFormation template
sam validate --lint
```

## Development Workflow

### Running Tests

```bash
# Run all tests
make test

# Run unit tests only
make test-unit

# Run property-based tests only
make test-property

# Run integration tests
make test-integration

# Run tests with coverage report
pytest --cov=src --cov-report=html
# Open htmlcov/index.html to view coverage
```

### Code Quality

```bash
# Format code
make format

# Run linters
make lint

# Type checking
mypy src/
```

### Local Development

```bash
# Build the application
make build

# Start API locally
make local

# In another terminal, test the API
curl http://localhost:3000/health
```

### Invoking Functions Locally

```bash
# Invoke API function with sample event
sam local invoke ApiFunction --event events/api-event.json

# Invoke Update function with sample event
sam local invoke PriceUpdateFunction --event events/update-event.json
```

## Deployment

### First-Time Deployment

For first-time deployment, you'll need to create an S3 bucket for SAM artifacts:

```bash
# SAM will create this automatically with --resolve-s3 flag
# Or create manually:
aws s3 mb s3://crypto-watch-sam-artifacts-<your-account-id>
```

### Deploy to Development

```bash
# Build and deploy
make deploy-dev

# Or use the deployment script
./scripts/deploy.sh dev
```

### Deploy to Staging

```bash
make deploy-staging
```

### Deploy to Production

```bash
make deploy-prod
```

## Setting Up API Keys

After deploying, you need to create at least one API key:

```bash
# Generate and store API key
python scripts/setup-api-key.py --environment dev --name "Test App"

# Save the generated API key securely
```

## Testing the Deployed API

```bash
# Get the API endpoint from CloudFormation outputs
aws cloudformation describe-stacks \
    --stack-name crypto-watch-backend-dev \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
    --output text

# Test health endpoint (no auth required)
curl https://<api-endpoint>/dev/health

# Test prices endpoint (requires API key)
curl -H "X-Api-Key: <your-api-key>" \
    "https://<api-endpoint>/dev/prices?symbols=BTC,ETH"
```

## Troubleshooting

### SAM Build Fails

- Ensure Python 3.11 is installed
- Check that all requirements.txt files are present
- Try: `sam build --use-container` to build in Docker

### Tests Fail

- Ensure virtual environment is activated
- Install dev dependencies: `pip install -r requirements-dev.txt`
- Check Python version: `python --version`

### Deployment Fails

- Verify AWS credentials: `aws sts get-caller-identity`
- Check IAM permissions for CloudFormation, Lambda, DynamoDB, API Gateway
- Review CloudFormation events in AWS Console

### Local API Not Starting

- Ensure Docker is running
- Check port 3000 is not in use
- Try: `sam local start-api --debug`

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
│   └── shared/           # Shared utilities (Lambda Layer)
│       ├── __init__.py
│       ├── auth.py       # Authentication & rate limiting
│       ├── cache.py      # Cache management
│       ├── db.py         # DynamoDB operations
│       ├── errors.py     # Error handling
│       ├── external_api.py  # External API client
│       ├── models.py     # Data models
│       └── utils.py      # General utilities
├── tests/
│   ├── unit/             # Unit tests
│   ├── integration/      # Integration tests
│   └── conftest.py       # Pytest configuration
├── events/               # Sample events for local testing
├── scripts/              # Utility scripts
├── template.yaml         # AWS SAM template
├── samconfig.toml        # SAM CLI configuration
├── requirements-dev.txt  # Development dependencies
├── pytest.ini            # Pytest configuration
├── Makefile              # Common commands
└── README.md
```

## Next Steps

1. Complete Task 2: Implement DynamoDB table design and data models
2. Complete Task 3: Implement cache management logic
3. Continue with remaining tasks in tasks.md

## Additional Resources

- [AWS SAM Documentation](https://docs.aws.amazon.com/serverless-application-model/)
- [Python Hypothesis Documentation](https://hypothesis.readthedocs.io/)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
