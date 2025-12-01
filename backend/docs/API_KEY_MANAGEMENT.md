# API Key Management

## Overview

The crypto-watch-backend uses API keys for authentication. This document describes how to generate, manage, and rotate API keys.

## Generating API Keys

### Using the Setup Script

The easiest way to generate an API key is using the provided setup script:

```bash
# For development environment
python scripts/setup-api-key.py --name "Development Key" --environment dev

# For staging environment
python scripts/setup-api-key.py --name "Staging Test Key" --environment staging

# For production environment
python scripts/setup-api-key.py --name "Production App" --environment prod
```

### Script Options

- `--name`: Descriptive name for the API key (required)
- `--environment`: Environment (dev, staging, prod) - default: dev
- `--table-name`: Override the default DynamoDB table name
- `--region`: AWS region - default: us-east-1
- `--length`: API key length - default: 32

### Example Output

```
============================================================
Crypto Watch Backend - API Key Setup
============================================================
Environment: dev
Table Name: crypto-watch-data-dev
Region: us-east-1
Key Name: Development Key

Generating API key...
✓ API key generated: AbCdEfGh...XyZ1

Saving to DynamoDB...
✓ API key saved to DynamoDB table: crypto-watch-data-dev

============================================================
SUCCESS!
============================================================

Your API key has been created and stored in DynamoDB.

IMPORTANT: Save this API key securely!
This is the only time it will be displayed in full.

API Key: AbCdEfGhIjKlMnOpQrStUvWxYz0123456789

Use this key in the X-API-Key header when making requests:
  curl -H "X-API-Key: AbCdEfGhIjKlMnOpQrStUvWxYz0123456789" https://your-api-url/prices?symbols=BTC

============================================================
```

## API Key Storage

API keys are stored in DynamoDB with the following structure:

```json
{
  "PK": "APIKEY#<key_id>",
  "SK": "METADATA",
  "keyId": "<key_id>",
  "name": "Development Key",
  "createdAt": "2024-01-15T10:30:00Z",
  "enabled": true,
  "lastUsedAt": "2024-01-15T12:45:00Z"  // Optional, updated on use
}
```

## Using API Keys

### In API Requests

Include the API key in the `X-API-Key` header:

```bash
curl -H "X-API-Key: YOUR_API_KEY" \
     https://api.example.com/prices?symbols=BTC,ETH
```

### Rate Limiting

Each API key is subject to rate limiting:
- **Default limit**: 100 requests per minute
- **Enforcement**: Per-minute window
- **Response**: 429 Too Many Requests when exceeded

## API Key Lifecycle

### 1. Creation
- Generate using the setup script
- Store securely (password manager, secrets vault)
- Document the purpose and owner

### 2. Active Use
- Monitor usage through CloudWatch metrics
- Track `lastUsedAt` timestamp
- Review access patterns regularly

### 3. Rotation
API keys should be rotated periodically (recommended: every 90 days)

**Rotation Process:**
1. Generate a new API key
2. Update client applications with the new key
3. Allow a transition period (e.g., 30 days) where both keys work
4. Disable the old key
5. Monitor for any failed authentication attempts
6. Delete the old key after confirmation

### 4. Revocation
Immediately revoke a key if:
- Suspected compromise or leak
- No longer needed
- Security incident

**Revocation Steps:**
1. Disable the key in DynamoDB (set `enabled: false`)
2. Monitor for authentication failures
3. Investigate any suspicious activity
4. Delete the key after investigation

## Manual API Key Management

### Disabling an API Key

```python
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('crypto-watch-data-prod')

table.update_item(
    Key={
        'PK': 'APIKEY#your-api-key',
        'SK': 'METADATA'
    },
    UpdateExpression='SET enabled = :val',
    ExpressionAttributeValues={
        ':val': False
    }
)
```

### Enabling an API Key

```python
table.update_item(
    Key={
        'PK': 'APIKEY#your-api-key',
        'SK': 'METADATA'
    },
    UpdateExpression='SET enabled = :val',
    ExpressionAttributeValues={
        ':val': True
    }
)
```

### Deleting an API Key

```python
table.delete_item(
    Key={
        'PK': 'APIKEY#your-api-key',
        'SK': 'METADATA'
    }
)
```

### Listing All API Keys

```python
response = table.query(
    IndexName='GSI1',  # If configured
    KeyConditionExpression='begins_with(PK, :pk)',
    ExpressionAttributeValues={
        ':pk': 'APIKEY#'
    }
)

for item in response['Items']:
    print(f"Key: {item['keyId']}, Name: {item['name']}, Enabled: {item['enabled']}")
```

## Security Best Practices

### Storage
- ✅ Store API keys in secure password managers
- ✅ Use environment variables or secrets managers in applications
- ✅ Never commit API keys to version control
- ✅ Use AWS Secrets Manager or Parameter Store for production

### Transmission
- ✅ Always use HTTPS for API requests
- ✅ Never log full API keys (mask in logs: `key_abc***`)
- ✅ Never include API keys in URLs or query parameters

### Monitoring
- ✅ Monitor API key usage patterns
- ✅ Set up alerts for unusual activity
- ✅ Review unused keys regularly (90+ days inactive)
- ✅ Track authentication failures

### Rotation
- ✅ Rotate keys every 90 days
- ✅ Rotate immediately if compromise suspected
- ✅ Use transition periods for smooth rotation
- ✅ Document rotation schedule

## Troubleshooting

### "Invalid API key" Error
- Verify the key is correct (no extra spaces)
- Check if the key is enabled in DynamoDB
- Confirm you're using the correct environment

### "Rate limit exceeded" Error
- Wait 60 seconds for the rate limit window to reset
- Check if multiple clients are using the same key
- Consider requesting a higher rate limit

### Key Not Working After Creation
- Verify the key was saved to the correct DynamoDB table
- Check AWS credentials have DynamoDB read permissions
- Confirm the API Gateway is configured correctly

## Future Enhancements

Planned improvements for API key management:

1. **Automatic Rotation**: Scheduled key rotation with notifications
2. **Usage Dashboard**: Web UI for viewing key usage and metrics
3. **Scoped Permissions**: Different permission levels per key
4. **Multi-Tenant Support**: Associate keys with specific users/organizations
5. **Audit Logging**: Detailed logs of all key operations

## Support

For issues or questions about API key management:
- Check CloudWatch Logs for authentication errors
- Review DynamoDB table for key status
- Contact the development team for assistance
