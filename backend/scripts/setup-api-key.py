#!/usr/bin/env python3
"""
API Key Setup Script

Generates and stores API keys in DynamoDB for the crypto-watch-backend.
This script can be used to create initial API keys for development and testing.

Usage:
    python scripts/setup-api-key.py --name "Development Key" --environment dev
    python scripts/setup-api-key.py --name "Production App" --environment prod
"""

import argparse
import secrets
import sys
import os
from datetime import datetime, timezone

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

import boto3
from shared.models import APIKey


def generate_api_key(length: int = 32) -> str:
    """
    Generate a cryptographically secure API key.
    
    Args:
        length: Length of the API key (default: 32 characters)
        
    Returns:
        Secure random API key string
    """
    # Use secrets module for cryptographically strong random generation
    # Generate URL-safe base64 encoded string
    return secrets.token_urlsafe(length)


def save_api_key_to_dynamodb(
    api_key: str,
    name: str,
    table_name: str,
    region: str = 'us-east-1'
) -> bool:
    """
    Save API key to DynamoDB.
    
    Args:
        api_key: The API key string
        name: Descriptive name for the API key
        table_name: DynamoDB table name
        region: AWS region
        
    Returns:
        True if successful, False otherwise
    """
    try:
        # Create DynamoDB resource
        dynamodb = boto3.resource('dynamodb', region_name=region)
        table = dynamodb.Table(table_name)
        
        # Create APIKey model
        api_key_model = APIKey(
            key_id=api_key,
            name=name,
            created_at=datetime.now(timezone.utc),
            enabled=True
        )
        
        # Convert to DynamoDB item and save
        item = api_key_model.to_dynamodb_item()
        table.put_item(Item=item)
        
        print(f"✓ API key saved to DynamoDB table: {table_name}")
        return True
        
    except Exception as e:
        print(f"✗ Error saving API key to DynamoDB: {e}")
        return False


def main():
    """Main function to generate and store API key."""
    parser = argparse.ArgumentParser(
        description='Generate and store API keys for crypto-watch-backend'
    )
    parser.add_argument(
        '--name',
        required=True,
        help='Descriptive name for the API key (e.g., "Development Key", "Production App")'
    )
    parser.add_argument(
        '--environment',
        choices=['dev', 'staging', 'prod'],
        default='dev',
        help='Environment (dev, staging, prod)'
    )
    parser.add_argument(
        '--table-name',
        help='DynamoDB table name (overrides environment default)'
    )
    parser.add_argument(
        '--region',
        default='us-east-1',
        help='AWS region (default: us-east-1)'
    )
    parser.add_argument(
        '--length',
        type=int,
        default=32,
        help='API key length (default: 32)'
    )
    
    args = parser.parse_args()
    
    # Determine table name based on environment
    if args.table_name:
        table_name = args.table_name
    else:
        table_name = f'crypto-watch-data-{args.environment}'
    
    print("=" * 60)
    print("Crypto Watch Backend - API Key Setup")
    print("=" * 60)
    print(f"Environment: {args.environment}")
    print(f"Table Name: {table_name}")
    print(f"Region: {args.region}")
    print(f"Key Name: {args.name}")
    print()
    
    # Generate API key
    print("Generating API key...")
    api_key = generate_api_key(args.length)
    print(f"✓ API key generated: {api_key[:8]}...{api_key[-4:]}")
    print()
    
    # Save to DynamoDB
    print("Saving to DynamoDB...")
    success = save_api_key_to_dynamodb(
        api_key=api_key,
        name=args.name,
        table_name=table_name,
        region=args.region
    )
    
    if success:
        print()
        print("=" * 60)
        print("SUCCESS!")
        print("=" * 60)
        print()
        print("Your API key has been created and stored in DynamoDB.")
        print()
        print("IMPORTANT: Save this API key securely!")
        print("This is the only time it will be displayed in full.")
        print()
        print(f"API Key: {api_key}")
        print()
        print("Use this key in the X-API-Key header when making requests:")
        print(f'  curl -H "X-API-Key: {api_key}" https://your-api-url/prices?symbols=BTC')
        print()
        print("=" * 60)
        return 0
    else:
        print()
        print("=" * 60)
        print("FAILED!")
        print("=" * 60)
        print("Failed to save API key to DynamoDB.")
        print("Please check your AWS credentials and table configuration.")
        return 1


if __name__ == '__main__':
    sys.exit(main())
