#!/bin/bash
# Deployment script for crypto-watch-backend
# Usage: ./scripts/deploy.sh [environment]
# Example: ./scripts/deploy.sh dev

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if environment is provided
if [ -z "$1" ]; then
    print_error "Environment not specified"
    echo "Usage: ./scripts/deploy.sh [environment]"
    echo "Environments: dev, staging, prod"
    exit 1
fi

ENVIRONMENT=$1

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    echo "Valid environments: dev, staging, prod"
    exit 1
fi

print_info "Starting deployment for environment: $ENVIRONMENT"
echo ""

# Check if SAM CLI is installed
if ! command -v sam &> /dev/null; then
    print_error "SAM CLI is not installed"
    echo "Please install SAM CLI: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html"
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS CLI is not configured"
    echo "Please configure AWS CLI: aws configure"
    exit 1
fi

print_info "AWS Account: $(aws sts get-caller-identity --query Account --output text)"
print_info "AWS Region: $(aws configure get region)"
echo ""

# Set parameters based on environment
case $ENVIRONMENT in
    dev)
        STACK_NAME="crypto-watch-backend-dev"
        PARAMETER_FILE="samconfig-dev.toml"
        ;;
    staging)
        STACK_NAME="crypto-watch-backend-staging"
        PARAMETER_FILE="samconfig-staging.toml"
        ;;
    prod)
        STACK_NAME="crypto-watch-backend-prod"
        PARAMETER_FILE="samconfig-prod.toml"
        ;;
esac

print_info "Stack Name: $STACK_NAME"
print_info "Parameter File: $PARAMETER_FILE"
echo ""

# Run tests before deployment
print_info "Running tests..."
if python -m pytest tests/ -v --tb=short; then
    print_info "✓ All tests passed"
else
    print_error "✗ Tests failed"
    print_warn "Deployment aborted due to test failures"
    exit 1
fi
echo ""

# Build the application
print_info "Building SAM application..."
if sam build; then
    print_info "✓ Build successful"
else
    print_error "✗ Build failed"
    exit 1
fi
echo ""

# Deploy the application
print_info "Deploying to $ENVIRONMENT..."
if [ -f "$PARAMETER_FILE" ]; then
    print_info "Using parameter file: $PARAMETER_FILE"
    sam deploy --config-file "$PARAMETER_FILE" --config-env "$ENVIRONMENT"
else
    print_warn "Parameter file not found: $PARAMETER_FILE"
    print_info "Using guided deployment..."
    sam deploy --guided --stack-name "$STACK_NAME"
fi

if [ $? -eq 0 ]; then
    print_info "✓ Deployment successful"
    echo ""
    
    # Get stack outputs
    print_info "Stack Outputs:"
    aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --query 'Stacks[0].Outputs' \
        --output table
    
    echo ""
    print_info "Deployment completed successfully!"
    print_info "Environment: $ENVIRONMENT"
    print_info "Stack: $STACK_NAME"
else
    print_error "✗ Deployment failed"
    exit 1
fi
