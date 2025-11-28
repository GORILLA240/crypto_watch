#!/usr/bin/env python3
"""
Script to generate and store API keys in DynamoDB.

Usage:
    python scripts/setup-api-key.py --environment dev --name "Test App"
"""

import argparse
import secrets
import boto3
from datetime import datetime


def generate_api_key(length: int = 32) -> str:
    """Generate a cryptographically secure API key."""
    return secrets.token_urlsafe(length)


def store_api_key(table_name: str, key_id: str, name: str) -> None:
    """Store API key in DynamoDB."""
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(table_name)
    
    item = {
        'PK': f'APIKEY#{key_id}',
        'SK': 'METADATA',
        'keyId': key_id,
        'name': name,
        'createdAt': datetime.utcnow().isoformat() + 'Z',
        'enabled': True
    }
    
    table.put_item(Item=item)
    print(f"API key stored successfully in table: {table_name}")


def main():
    parser = argparse.ArgumentParser(description='Generate and store API key')
    parser.add_argument('--environment', required=True, choices=['dev', 'staging', 'prod'],
                        help='Deployment environment')
    parser.add_argument('--name', required=True, help='Name/description for the API key')
    parser.add_argument('--length', type=int, default=32, help='Length of API key (default: 32)')
    
    args = parser.parse_args()
    
    # Generate API key
    api_key = generate_api_key(args.length)
    
    # Table name
    table_name = f'crypto-watch-data-{args.environment}'
    
    # Store in DynamoDB
    try:
        store_api_key(table_name, api_key, args.name)
        
        print("\n" + "="*60)
        print("API Key Generated Successfully!")
        print("="*60)
        print(f"\nAPI Key: {api_key}")
        print(f"Name: {args.name}")
        print(f"Environment: {args.environment}")
        print("\nIMPORTANT: Save this API key securely. It will not be shown again.")
        print("="*60 + "\n")
        
    except Exception as e:
        print(f"Error storing API key: {e}")
        print(f"\nGenerated API Key (not stored): {api_key}")
        print("You can manually add it to DynamoDB if needed.")


if __name__ == '__main__':
    main()
