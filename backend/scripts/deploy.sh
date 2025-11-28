#!/bin/bash

# Deployment script for Crypto Watch Backend
# Usage: ./scripts/deploy.sh [dev|staging|prod]

set -e

ENVIRONMENT=${1:-dev}

echo "=========================================="
echo "Deploying Crypto Watch Backend"
echo "Environment: $ENVIRONMENT"
echo "=========================================="

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "Error: Invalid environment. Must be dev, staging, or prod"
    exit 1
fi

# Run tests
echo ""
echo "Running tests..."
pytest tests/unit/ -v

# Lint code
echo ""
echo "Running linters..."
flake8 src/ tests/

# Validate SAM template
echo ""
echo "Validating SAM template..."
sam validate --lint

# Build application
echo ""
echo "Building application..."
sam build

# Deploy
echo ""
echo "Deploying to $ENVIRONMENT..."
sam deploy --config-env $ENVIRONMENT

echo ""
echo "=========================================="
echo "Deployment complete!"
echo "=========================================="

# Get outputs
echo ""
echo "Stack outputs:"
aws cloudformation describe-stacks \
    --stack-name crypto-watch-backend-$ENVIRONMENT \
    --query 'Stacks[0].Outputs' \
    --output table
