"""
Unit tests for health check endpoint.

Tests the health check endpoint functionality including DynamoDB connectivity,
cache age calculation, and status reporting.

Requirements: 5.5
"""

import pytest
import json
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime, timezone, timedelta

from src.shared.models import CryptoPrice
from src.shared.cache import get_cache_age_seconds


class TestHealthCheckLogic:
    """Unit tests for health check logic."""
    
    def test_cache_age_calculation(self):
        """
        Test that cache age is calculated correctly.
        
        Requirements: 5.5
        """
        # Create price data from 2 minutes ago
        two_minutes_ago = datetime.now(timezone.utc) - timedelta(minutes=2)
        
        # Calculate cache age
        age_seconds = get_cache_age_seconds(two_minutes_ago)
        
        # Should be approximately 120 seconds (allow 1 second tolerance)
        assert 119 <= age_seconds <= 121, f"Cache age should be ~120 seconds, got {age_seconds}"
    
    def test_stale_cache_detection(self):
        """
        Test that stale cache (>15 minutes) is detected.
        
        Requirements: 5.5
        """
        # Create price data from 20 minutes ago
        twenty_minutes_ago = datetime.now(timezone.utc) - timedelta(minutes=20)
        
        # Calculate cache age
        age_seconds = get_cache_age_seconds(twenty_minutes_ago)
        
        # Should be greater than 15 minutes (900 seconds)
        assert age_seconds > 900, "Cache older than 15 minutes should be detected as stale"
    
    def test_fresh_cache_detection(self):
        """
        Test that fresh cache (<15 minutes) is detected.
        
        Requirements: 5.5
        """
        # Create price data from 5 minutes ago
        five_minutes_ago = datetime.now(timezone.utc) - timedelta(minutes=5)
        
        # Calculate cache age
        age_seconds = get_cache_age_seconds(five_minutes_ago)
        
        # Should be less than 15 minutes (900 seconds)
        assert age_seconds < 900, "Cache younger than 15 minutes should be detected as fresh"


class TestHealthCheckEndpoint:
    """Unit tests for health check endpoint handler."""
    
    def test_health_check_returns_200_when_system_healthy(self):
        """
        Test that health check returns 200 OK when system is healthy.
        
        Requirements: 5.5
        """
        from src.api.handler import handle_health_check
        
        with patch('src.api.handler.cache_manager') as mock_cache_manager:
            # Mock DynamoDB connectivity - successful
            mock_db_client = Mock()
            mock_price_data = CryptoPrice(
                symbol='BTC',
                name='Bitcoin',
                price=45000.50,
                change24h=2.5,
                market_cap=850000000000,
                last_updated=datetime.now(timezone.utc) - timedelta(minutes=3)
            )
            mock_db_client.get_price_data.return_value = mock_price_data
            mock_cache_manager.db_client = mock_db_client
            
            # Create test event
            event = {
                'path': '/health',
                'httpMethod': 'GET'
            }
            
            # Call health check handler
            response = handle_health_check(event)
            
            # Verify response
            assert response['statusCode'] == 200, "Should return 200 when system is healthy"
            
            # Parse response body
            body = json.loads(response['body'])
            
            # Verify response structure
            assert body['status'] == 'healthy', "Status should be 'healthy'"
            assert 'timestamp' in body, "Response should include timestamp"
            assert 'checks' in body, "Response should include checks"
            assert body['checks']['dynamodb'] == 'ok', "DynamoDB check should be 'ok'"
            assert 'lastPriceUpdate' in body['checks'], "Should include lastPriceUpdate"
            assert 'cacheAge' in body['checks'], "Should include cacheAge"
            
            # Verify cache age is reasonable (< 15 minutes)
            assert body['checks']['cacheAge'] < 900, "Cache age should be less than 15 minutes"
    
    def test_health_check_returns_503_on_dynamodb_failure(self):
        """
        Test that health check returns 503 when DynamoDB connection fails.
        
        Requirements: 5.5
        """
        from src.api.handler import handle_health_check
        
        with patch('src.api.handler.cache_manager') as mock_cache_manager:
            # Mock DynamoDB connectivity - failure
            mock_db_client = Mock()
            mock_db_client.get_price_data.side_effect = Exception('Connection timeout')
            mock_cache_manager.db_client = mock_db_client
            
            # Create test event
            event = {
                'path': '/health',
                'httpMethod': 'GET'
            }
            
            # Call health check handler
            response = handle_health_check(event)
            
            # Verify response
            assert response['statusCode'] == 503, "Should return 503 when DynamoDB fails"
            
            # Parse response body
            body = json.loads(response['body'])
            
            # Verify response structure
            assert body['status'] == 'unhealthy', "Status should be 'unhealthy'"
            assert 'error' in body, "Response should include error message"
            assert 'dynamodb' in body['error'].lower(), "Error should mention DynamoDB"
            assert body['checks']['dynamodb'] == 'error', "DynamoDB check should be 'error'"
    
    def test_health_check_includes_warning_for_stale_cache(self):
        """
        Test that health check includes warning when price update is old.
        
        Requirements: 5.5
        """
        from src.api.handler import handle_health_check
        
        with patch('src.api.handler.cache_manager') as mock_cache_manager:
            # Mock DynamoDB connectivity - successful but with stale data
            mock_db_client = Mock()
            mock_price_data = CryptoPrice(
                symbol='BTC',
                name='Bitcoin',
                price=45000.50,
                change24h=2.5,
                market_cap=850000000000,
                last_updated=datetime.now(timezone.utc) - timedelta(minutes=20)  # 20 minutes old
            )
            mock_db_client.get_price_data.return_value = mock_price_data
            mock_cache_manager.db_client = mock_db_client
            
            # Create test event
            event = {
                'path': '/health',
                'httpMethod': 'GET'
            }
            
            # Call health check handler
            response = handle_health_check(event)
            
            # Verify response
            assert response['statusCode'] == 503, "Should return 503 when cache is stale"
            
            # Parse response body
            body = json.loads(response['body'])
            
            # Verify response structure
            assert body['status'] == 'unhealthy', "Status should be 'unhealthy' for stale cache"
            assert 'error' in body, "Response should include error message"
            assert 'stale' in body['error'].lower(), "Error should mention stale data"
            assert body['checks']['cacheAge'] > 900, "Cache age should be greater than 15 minutes"
    
    def test_health_check_includes_all_status_information(self):
        """
        Test that health check includes all required status information.
        
        Requirements: 5.5
        """
        from src.api.handler import handle_health_check
        
        with patch('src.api.handler.cache_manager') as mock_cache_manager:
            # Mock DynamoDB connectivity - successful
            mock_db_client = Mock()
            mock_price_data = CryptoPrice(
                symbol='BTC',
                name='Bitcoin',
                price=45000.50,
                change24h=2.5,
                market_cap=850000000000,
                last_updated=datetime.now(timezone.utc) - timedelta(minutes=5)
            )
            mock_db_client.get_price_data.return_value = mock_price_data
            mock_cache_manager.db_client = mock_db_client
            
            # Create test event
            event = {
                'path': '/health',
                'httpMethod': 'GET'
            }
            
            # Call health check handler
            response = handle_health_check(event)
            
            # Parse response body
            body = json.loads(response['body'])
            
            # Verify all required fields are present
            required_fields = ['status', 'timestamp', 'checks']
            for field in required_fields:
                assert field in body, f"Response should include {field}"
            
            # Verify checks structure
            required_checks = ['dynamodb', 'lastPriceUpdate', 'cacheAge']
            for check in required_checks:
                assert check in body['checks'], f"Checks should include {check}"
            
            # Verify timestamp format (ISO 8601 with Z)
            assert body['timestamp'].endswith('Z'), "Timestamp should end with 'Z'"
            
            # Verify timestamp is valid
            try:
                datetime.fromisoformat(body['timestamp'].replace('Z', '+00:00'))
            except ValueError:
                pytest.fail("Timestamp should be valid ISO 8601 format")
            
            # Verify lastPriceUpdate format
            assert body['checks']['lastPriceUpdate'].endswith('Z'), "lastPriceUpdate should end with 'Z'"
            
            # Verify cacheAge is a number
            assert isinstance(body['checks']['cacheAge'], int), "cacheAge should be an integer"
    
    def test_health_check_handles_no_price_data(self):
        """
        Test that health check handles case when no price data exists.
        
        Requirements: 5.5
        """
        from src.api.handler import handle_health_check
        
        with patch('src.api.handler.cache_manager') as mock_cache_manager:
            # Mock DynamoDB connectivity - successful but no data
            mock_db_client = Mock()
            mock_db_client.get_price_data.return_value = None
            mock_cache_manager.db_client = mock_db_client
            
            # Create test event
            event = {
                'path': '/health',
                'httpMethod': 'GET'
            }
            
            # Call health check handler
            response = handle_health_check(event)
            
            # Parse response body
            body = json.loads(response['body'])
            
            # Verify response structure
            assert 'checks' in body, "Response should include checks"
            assert body['checks']['dynamodb'] == 'ok', "DynamoDB check should still be 'ok'"
            assert body['checks']['lastPriceUpdate'] is None, "lastPriceUpdate should be None"
            assert body['checks']['cacheAge'] is None, "cacheAge should be None"
    
    def test_health_check_response_has_correct_headers(self):
        """
        Test that health check response has correct headers.
        
        Requirements: 5.5
        """
        from src.api.handler import handle_health_check
        
        with patch('src.api.handler.cache_manager') as mock_cache_manager:
            # Mock DynamoDB connectivity - successful
            mock_db_client = Mock()
            mock_price_data = CryptoPrice(
                symbol='BTC',
                name='Bitcoin',
                price=45000.50,
                change24h=2.5,
                market_cap=850000000000,
                last_updated=datetime.now(timezone.utc) - timedelta(minutes=3)
            )
            mock_db_client.get_price_data.return_value = mock_price_data
            mock_cache_manager.db_client = mock_db_client
            
            # Create test event
            event = {
                'path': '/health',
                'httpMethod': 'GET'
            }
            
            # Call health check handler
            response = handle_health_check(event)
            
            # Verify headers
            assert 'headers' in response, "Response should include headers"
            headers = response['headers']
            assert headers['Content-Type'] == 'application/json', "Content-Type should be application/json"
            assert 'Access-Control-Allow-Origin' in headers, "Should have CORS header"
    
    def test_health_check_checks_multiple_symbols(self):
        """
        Test that health check checks multiple symbols to find most recent update.
        
        Requirements: 5.5
        """
        from src.api.handler import handle_health_check
        
        with patch('src.api.handler.cache_manager') as mock_cache_manager:
            # Mock DynamoDB connectivity - return different timestamps for different symbols
            mock_db_client = Mock()
            
            def get_price_data_side_effect(symbol):
                if symbol == 'BTC':
                    return CryptoPrice(
                        symbol='BTC',
                        name='Bitcoin',
                        price=45000.50,
                        change24h=2.5,
                        market_cap=850000000000,
                        last_updated=datetime.now(timezone.utc) - timedelta(minutes=10)
                    )
                elif symbol == 'ETH':
                    return CryptoPrice(
                        symbol='ETH',
                        name='Ethereum',
                        price=3000.00,
                        change24h=1.5,
                        market_cap=350000000000,
                        last_updated=datetime.now(timezone.utc) - timedelta(minutes=3)  # Most recent
                    )
                elif symbol == 'ADA':
                    return CryptoPrice(
                        symbol='ADA',
                        name='Cardano',
                        price=0.50,
                        change24h=0.5,
                        market_cap=15000000000,
                        last_updated=datetime.now(timezone.utc) - timedelta(minutes=7)
                    )
                return None
            
            mock_db_client.get_price_data.side_effect = get_price_data_side_effect
            mock_cache_manager.db_client = mock_db_client
            
            # Create test event
            event = {
                'path': '/health',
                'httpMethod': 'GET'
            }
            
            # Call health check handler
            response = handle_health_check(event)
            
            # Parse response body
            body = json.loads(response['body'])
            
            # Verify that the most recent update is used (ETH at 3 minutes)
            assert body['checks']['cacheAge'] >= 180, "Should use most recent update"
            assert body['checks']['cacheAge'] < 240, "Cache age should be around 3 minutes"
    
    def test_health_check_handles_partial_dynamodb_failure(self):
        """
        Test that health check handles partial failures when checking symbols.
        
        The health check tries BTC first for connectivity test. If that fails,
        it marks DynamoDB as error even if other symbols might work.
        
        Requirements: 5.5
        """
        from src.api.handler import handle_health_check
        
        with patch('src.api.handler.cache_manager') as mock_cache_manager:
            # Mock DynamoDB connectivity - BTC fails (first check), others succeed
            mock_db_client = Mock()
            
            def get_price_data_side_effect(symbol):
                if symbol == 'BTC':
                    raise Exception('Timeout')
                elif symbol == 'ETH':
                    return CryptoPrice(
                        symbol='ETH',
                        name='Ethereum',
                        price=3000.00,
                        change24h=1.5,
                        market_cap=350000000000,
                        last_updated=datetime.now(timezone.utc) - timedelta(minutes=5)
                    )
                return None
            
            mock_db_client.get_price_data.side_effect = get_price_data_side_effect
            mock_cache_manager.db_client = mock_db_client
            
            # Create test event
            event = {
                'path': '/health',
                'httpMethod': 'GET'
            }
            
            # Call health check handler
            response = handle_health_check(event)
            
            # Parse response body
            body = json.loads(response['body'])
            
            # Since BTC (first check) fails, DynamoDB is marked as error
            assert body['checks']['dynamodb'] == 'error', "DynamoDB check should be 'error' if initial connectivity test fails"
            assert response['statusCode'] == 503, "Should return 503 when DynamoDB connectivity fails"
            assert body['status'] == 'unhealthy', "Status should be 'unhealthy'"

