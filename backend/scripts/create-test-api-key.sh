#!/bin/bash
# Create a test API key for development

echo "Creating test API key for development..."
python scripts/setup-api-key.py \
    --name "Development Test Key" \
    --environment dev \
    --region us-east-1

echo ""
echo "Note: This script creates a test API key for local development."
echo "For production, use the setup-api-key.py script with appropriate parameters."
