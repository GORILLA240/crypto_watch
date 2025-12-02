"""
Response optimization utilities.

Handles response formatting, compression, and payload reduction.
"""

import gzip
import json
from typing import Dict, Any, List


def should_compress_response(headers: Dict[str, Any]) -> bool:
    """
    Check if the client supports gzip compression based on Accept-Encoding header.
    
    Args:
        headers: Request headers dictionary
        
    Returns:
        True if client supports gzip compression, False otherwise
    """
    if not headers:
        return False
    
    # Headers can be case-insensitive in API Gateway
    # Check both lowercase and original case
    accept_encoding = None
    
    for key, value in headers.items():
        if key.lower() == 'accept-encoding':
            accept_encoding = value
            break
    
    if not accept_encoding:
        return False
    
    # Check if gzip is in the Accept-Encoding header
    return 'gzip' in accept_encoding.lower()


def compress_response(body: str) -> bytes:
    """
    Compress response body using gzip.
    
    Args:
        body: JSON string to compress
        
    Returns:
        Compressed bytes
    """
    return gzip.compress(body.encode('utf-8'))


def format_optimized_response(
    price_data_list: List[Any],
    timestamp: str,
    headers: Dict[str, Any] = None
) -> Dict[str, Any]:
    """
    Format and optimize API response with optional compression.
    
    This function:
    - Formats price data with only essential fields
    - Applies numeric precision limits (price: 2 decimals, change24h: 1 decimal)
    - Compresses response if client supports gzip
    
    Args:
        price_data_list: List of CryptoPrice objects
        timestamp: ISO timestamp string
        headers: Request headers (to check for compression support)
        
    Returns:
        Dictionary with statusCode, headers, and body (string or bytes)
    """
    # Format response data
    response_data = {
        'data': [price.to_dict() for price in price_data_list],
        'timestamp': timestamp
    }
    
    # Convert to JSON string
    body_json = json.dumps(response_data)
    
    # Prepare response headers
    response_headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
    }
    
    # Check if compression is supported
    if headers and should_compress_response(headers):
        # Compress the response
        compressed_body = compress_response(body_json)
        
        # Add Content-Encoding header
        response_headers['Content-Encoding'] = 'gzip'
        
        # Return compressed response
        # Note: API Gateway expects base64-encoded binary data
        import base64
        return {
            'statusCode': 200,
            'headers': response_headers,
            'body': base64.b64encode(compressed_body).decode('utf-8'),
            'isBase64Encoded': True
        }
    else:
        # Return uncompressed response
        return {
            'statusCode': 200,
            'headers': response_headers,
            'body': body_json
        }
