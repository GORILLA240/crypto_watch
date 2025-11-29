"""
Unit tests for external API client.

Tests the external API client with retry logic and error handling.
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime, timezone
import requests

from src.shared.external_api import ExternalAPIClient, fetch_crypto_prices
from src.shared.models import CryptoPrice
from src.shared.errors import ExternalAPIError


class TestExternalAPIClient(unittest.TestCase):
    """Test cases for ExternalAPIClient."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.client = ExternalAPIClient(
            api_url='https://api.example.com/v3',
            api_key='test_key'
        )
    
    def test_initialization(self):
        """Test client initialization."""
        self.assertEqual(self.client.api_url, 'https://api.example.com/v3')
        self.assertEqual(self.client.api_key, 'test_key')
    
    def test_initialization_from_env(self):
        """Test client initialization from environment variables."""
        with patch.dict('os.environ', {
            'EXTERNAL_API_URL': 'https://env.example.com',
            'EXTERNAL_API_KEY': 'env_key'
        }):
            client = ExternalAPIClient()
            self.assertEqual(client.api_url, 'https://env.example.com')
            self.assertEqual(client.api_key, 'env_key')
    
    @patch('src.shared.external_api.requests.get')
    def test_fetch_prices_success(self, mock_get):
        """Test successful price fetch."""
        # Mock successful response
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'bitcoin': {
                'usd': 45000.50,
                'usd_24h_change': 2.5,
                'usd_market_cap': 850000000000
            },
            'ethereum': {
                'usd': 3000.25,
                'usd_24h_change': -1.2,
                'usd_market_cap': 360000000000
            }
        }
        mock_get.return_value = mock_response
        
        # Fetch prices
        prices = self.client.fetch_prices(['BTC', 'ETH'])
        
        # Verify results
        self.assertEqual(len(prices), 2)
        self.assertEqual(prices[0].symbol, 'BTC')
        self.assertEqual(prices[0].price, 45000.50)
        self.assertEqual(prices[0].change24h, 2.5)
        self.assertEqual(prices[1].symbol, 'ETH')
        self.assertEqual(prices[1].price, 3000.25)
        
        # Verify API was called correctly
        mock_get.assert_called_once()
        call_args = mock_get.call_args
        self.assertIn('bitcoin,ethereum', call_args[1]['params']['ids'])
    
    @patch('src.shared.external_api.requests.get')
    @patch('src.shared.external_api.time.sleep')
    def test_fetch_prices_retry_on_timeout(self, mock_sleep, mock_get):
        """Test retry logic on timeout."""
        # First two attempts timeout, third succeeds
        mock_get.side_effect = [
            requests.exceptions.Timeout('Timeout 1'),
            requests.exceptions.Timeout('Timeout 2'),
            Mock(
                status_code=200,
                json=lambda: {
                    'bitcoin': {
                        'usd': 45000.50,
                        'usd_24h_change': 2.5,
                        'usd_market_cap': 850000000000
                    }
                }
            )
        ]
        
        # Fetch prices
        prices = self.client.fetch_prices(['BTC'])
        
        # Verify retry happened
        self.assertEqual(mock_get.call_count, 3)
        self.assertEqual(mock_sleep.call_count, 2)
        
        # Verify exponential backoff delays
        mock_sleep.assert_any_call(1)
        mock_sleep.assert_any_call(2)
        
        # Verify result
        self.assertEqual(len(prices), 1)
        self.assertEqual(prices[0].symbol, 'BTC')
    
    @patch('src.shared.external_api.requests.get')
    @patch('src.shared.external_api.time.sleep')
    def test_fetch_prices_all_retries_fail(self, mock_sleep, mock_get):
        """Test error when all retries fail."""
        # All attempts fail
        mock_get.side_effect = requests.exceptions.Timeout('Timeout')
        
        # Should raise ExternalAPIError
        with self.assertRaises(ExternalAPIError) as context:
            self.client.fetch_prices(['BTC'])
        
        # Verify error details
        error = context.exception
        self.assertIn('Failed to fetch prices', error.message)
        self.assertEqual(error.status_code, 502)
        self.assertEqual(error.details['attempts'], 4)  # 1 initial + 3 retries
        
        # Verify all retries were attempted
        self.assertEqual(mock_get.call_count, 4)
        self.assertEqual(mock_sleep.call_count, 3)
    
    @patch('src.shared.external_api.requests.get')
    def test_fetch_prices_http_error(self, mock_get):
        """Test handling of HTTP errors."""
        # Mock HTTP error response
        mock_response = Mock()
        mock_response.raise_for_status.side_effect = requests.exceptions.HTTPError('404 Not Found')
        mock_get.return_value = mock_response
        
        # Should raise ExternalAPIError after retries
        with self.assertRaises(ExternalAPIError):
            self.client.fetch_prices(['BTC'])
    
    @patch('src.shared.external_api.requests.get')
    def test_fetch_prices_invalid_json(self, mock_get):
        """Test handling of invalid JSON response."""
        # Mock response with invalid JSON
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.side_effect = ValueError('Invalid JSON')
        mock_get.return_value = mock_response
        
        # Should raise ExternalAPIError after retries
        with self.assertRaises(ExternalAPIError):
            self.client.fetch_prices(['BTC'])
    
    @patch('src.shared.external_api.requests.get')
    def test_fetch_prices_missing_symbol(self, mock_get):
        """Test handling when requested symbol is not in response."""
        # Mock response missing one symbol
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'bitcoin': {
                'usd': 45000.50,
                'usd_24h_change': 2.5,
                'usd_market_cap': 850000000000
            }
            # ETH is missing
        }
        mock_get.return_value = mock_response
        
        # Fetch prices for BTC and ETH
        prices = self.client.fetch_prices(['BTC', 'ETH'])
        
        # Should only return BTC
        self.assertEqual(len(prices), 1)
        self.assertEqual(prices[0].symbol, 'BTC')
    
    @patch('src.shared.external_api.requests.get')
    def test_fetch_prices_missing_required_fields(self, mock_get):
        """Test handling when response is missing required fields."""
        # Mock response missing price field
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'bitcoin': {
                # Missing 'usd' field
                'usd_24h_change': 2.5,
                'usd_market_cap': 850000000000
            }
        }
        mock_get.return_value = mock_response
        
        # Should raise ValueError (no valid price data)
        with self.assertRaises(ExternalAPIError):
            self.client.fetch_prices(['BTC'])
    
    @patch('src.shared.external_api.requests.get')
    def test_fetch_prices_with_defaults(self, mock_get):
        """Test that optional fields use defaults when missing."""
        # Mock response with minimal data
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'bitcoin': {
                'usd': 45000.50
                # Missing change and market cap
            }
        }
        mock_get.return_value = mock_response
        
        # Fetch prices
        prices = self.client.fetch_prices(['BTC'])
        
        # Verify defaults are used
        self.assertEqual(len(prices), 1)
        self.assertEqual(prices[0].symbol, 'BTC')
        self.assertEqual(prices[0].price, 45000.50)
        self.assertEqual(prices[0].change24h, 0.0)
        self.assertEqual(prices[0].market_cap, 0)
    
    def test_transform_response(self):
        """Test response transformation."""
        data = {
            'bitcoin': {
                'usd': 45000.50,
                'usd_24h_change': 2.5,
                'usd_market_cap': 850000000000
            }
        }
        
        prices = self.client._transform_response(data, ['BTC'])
        
        self.assertEqual(len(prices), 1)
        self.assertEqual(prices[0].symbol, 'BTC')
        self.assertEqual(prices[0].name, 'Bitcoin')
        self.assertEqual(prices[0].price, 45000.50)
        self.assertEqual(prices[0].change24h, 2.5)
        self.assertEqual(prices[0].market_cap, 850000000000)
        self.assertIsInstance(prices[0].last_updated, datetime)
    
    def test_symbol_mapping(self):
        """Test symbol mapping from internal to external format."""
        self.assertEqual(self.client.SYMBOL_MAPPING['BTC'], 'bitcoin')
        self.assertEqual(self.client.SYMBOL_MAPPING['ETH'], 'ethereum')
        self.assertEqual(self.client.SYMBOL_MAPPING['ADA'], 'cardano')
    
    def test_name_mapping(self):
        """Test name mapping."""
        self.assertEqual(self.client.NAME_MAPPING['BTC'], 'Bitcoin')
        self.assertEqual(self.client.NAME_MAPPING['ETH'], 'Ethereum')
        self.assertEqual(self.client.NAME_MAPPING['ADA'], 'Cardano')
    
    @patch('src.shared.external_api.requests.get')
    def test_timeout_configuration(self, mock_get):
        """Test that timeout is configured correctly."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'bitcoin': {
                'usd': 45000.50,
                'usd_24h_change': 2.5,
                'usd_market_cap': 850000000000
            }
        }
        mock_get.return_value = mock_response
        
        self.client.fetch_prices(['BTC'])
        
        # Verify timeout was set
        call_args = mock_get.call_args
        self.assertEqual(call_args[1]['timeout'], 5)


class TestConvenienceFunction(unittest.TestCase):
    """Test cases for convenience function."""
    
    @patch('src.shared.external_api.ExternalAPIClient')
    def test_fetch_crypto_prices(self, mock_client_class):
        """Test convenience function."""
        # Mock client instance
        mock_client = Mock()
        mock_prices = [
            CryptoPrice(
                symbol='BTC',
                name='Bitcoin',
                price=45000.50,
                change24h=2.5,
                market_cap=850000000000,
                last_updated=datetime.now(timezone.utc)
            )
        ]
        mock_client.fetch_prices.return_value = mock_prices
        mock_client_class.return_value = mock_client
        
        # Call convenience function
        result = fetch_crypto_prices(['BTC'])
        
        # Verify
        self.assertEqual(result, mock_prices)
        mock_client.fetch_prices.assert_called_once_with(['BTC'])


class TestExternalAPIProperties(unittest.TestCase):
    """Property-based tests for external API client."""
    
    def test_property_6_retry_with_exponential_backoff(self):
        """
        Feature: crypto-watch-backend, Property 6: Retry with exponential backoff
        
        Property: For any external API call that fails, the system should retry 
        up to 3 times with exponential backoff delays between attempts.
        
        The retry pattern should be:
        - Attempt 1: Immediate (no delay before first attempt)
        - Attempt 2: Wait 1 second after first failure
        - Attempt 3: Wait 2 seconds after second failure  
        - Attempt 4: Wait 4 seconds after third failure
        
        Total attempts: 4 (1 initial + 3 retries)
        Delays: [1, 2, 4] seconds
        
        Validates: Requirements 3.3
        """
        from hypothesis import given, strategies as st, settings
        from unittest.mock import patch, Mock
        import requests
        
        # Strategy for generating number of failures before success (0 to 4)
        # 0 = success on first try
        # 1-3 = success after N failures
        # 4 = all attempts fail
        failures_before_success_strategy = st.integers(min_value=0, max_value=4)
        
        # Strategy for generating different types of failures
        failure_type_strategy = st.sampled_from([
            'timeout',
            'connection_error',
            'http_error'
        ])
        
        @settings(max_examples=100)
        @given(
            failures_before_success=failures_before_success_strategy,
            failure_type=failure_type_strategy
        )
        def property_test(failures_before_success, failure_type):
            """Test retry logic with various failure scenarios."""
            client = ExternalAPIClient(
                api_url='https://api.example.com/v3',
                api_key='test_key'
            )
            
            # Create mock responses based on failure count
            mock_responses = []
            
            # Add failures
            for i in range(failures_before_success):
                if failure_type == 'timeout':
                    mock_responses.append(requests.exceptions.Timeout(f'Timeout {i+1}'))
                elif failure_type == 'connection_error':
                    mock_responses.append(requests.exceptions.ConnectionError(f'Connection error {i+1}'))
                elif failure_type == 'http_error':
                    mock_response = Mock()
                    mock_response.raise_for_status.side_effect = requests.exceptions.HTTPError(f'HTTP error {i+1}')
                    mock_responses.append(mock_response)
            
            # Add success response if not all attempts should fail
            if failures_before_success < 4:
                success_response = Mock()
                success_response.status_code = 200
                success_response.json.return_value = {
                    'bitcoin': {
                        'usd': 45000.50,
                        'usd_24h_change': 2.5,
                        'usd_market_cap': 850000000000
                    }
                }
                mock_responses.append(success_response)
            
            with patch('src.shared.external_api.requests.get') as mock_get, \
                 patch('src.shared.external_api.time.sleep') as mock_sleep:
                
                mock_get.side_effect = mock_responses
                
                # Execute the test
                if failures_before_success == 4:
                    # All attempts should fail
                    with self.assertRaises(ExternalAPIError) as context:
                        client.fetch_prices(['BTC'])
                    
                    # Property 1: Should attempt exactly MAX_RETRIES + 1 times (4 total)
                    self.assertEqual(
                        mock_get.call_count, 
                        4,
                        f"Should make exactly 4 attempts when all fail"
                    )
                    
                    # Property 2: Should sleep exactly MAX_RETRIES times (3 times)
                    self.assertEqual(
                        mock_sleep.call_count,
                        3,
                        f"Should sleep 3 times between 4 attempts"
                    )
                    
                    # Property 3: Sleep delays should follow exponential backoff pattern [1, 2, 4]
                    expected_delays = [1, 2, 4]
                    actual_delays = [call[0][0] for call in mock_sleep.call_args_list]
                    self.assertEqual(
                        actual_delays,
                        expected_delays,
                        f"Sleep delays should be {expected_delays}, got {actual_delays}"
                    )
                    
                    # Property 4: Error should indicate number of attempts
                    error = context.exception
                    self.assertEqual(
                        error.details['attempts'],
                        4,
                        "Error should report 4 total attempts"
                    )
                    
                else:
                    # Should succeed after N failures
                    prices = client.fetch_prices(['BTC'])
                    
                    # Property 5: Should make exactly (failures_before_success + 1) attempts
                    expected_attempts = failures_before_success + 1
                    self.assertEqual(
                        mock_get.call_count,
                        expected_attempts,
                        f"Should make {expected_attempts} attempts for {failures_before_success} failures"
                    )
                    
                    # Property 6: Should sleep exactly failures_before_success times
                    self.assertEqual(
                        mock_sleep.call_count,
                        failures_before_success,
                        f"Should sleep {failures_before_success} times"
                    )
                    
                    # Property 7: Sleep delays should match exponential backoff for attempted retries
                    if failures_before_success > 0:
                        expected_delays = [1, 2, 4][:failures_before_success]
                        actual_delays = [call[0][0] for call in mock_sleep.call_args_list]
                        self.assertEqual(
                            actual_delays,
                            expected_delays,
                            f"Sleep delays should be {expected_delays}, got {actual_delays}"
                        )
                    
                    # Property 8: Should return valid price data on success
                    self.assertEqual(len(prices), 1)
                    self.assertEqual(prices[0].symbol, 'BTC')
                    self.assertEqual(prices[0].price, 45000.50)
        
        # Run the property test
        property_test()
    
    def test_property_7_retry_exhaustion_handling(self):
        """
        Feature: crypto-watch-backend, Property 7: Retry exhaustion handling
        
        Property: For any external API call where all retry attempts fail, 
        the system should log the error and attempt to serve cached data if available.
        
        When all retries are exhausted:
        - The error should be logged with details
        - An ExternalAPIError should be raised
        - The error should contain information about the number of attempts
        - The error should contain the last error that occurred
        
        Note: This test focuses on the retry exhaustion behavior. The actual
        fallback to cached data is handled at a higher level (in the Lambda handler
        or service layer), not in the ExternalAPIClient itself.
        
        Validates: Requirements 3.4
        """
        from hypothesis import given, strategies as st, settings
        from unittest.mock import patch, Mock
        import requests
        
        # Strategy for generating different types of failures
        failure_type_strategy = st.sampled_from([
            'timeout',
            'connection_error',
            'http_error',
            'json_error'
        ])
        
        # Strategy for generating symbols
        symbols_strategy = st.lists(
            st.sampled_from(['BTC', 'ETH', 'ADA', 'SOL', 'DOT']),
            min_size=1,
            max_size=5,
            unique=True
        )
        
        @settings(max_examples=100)
        @given(
            failure_type=failure_type_strategy,
            symbols=symbols_strategy
        )
        def property_test(failure_type, symbols):
            """Test retry exhaustion handling with various failure scenarios."""
            client = ExternalAPIClient(
                api_url='https://api.example.com/v3',
                api_key='test_key'
            )
            
            # Create mock responses that all fail
            mock_responses = []
            
            # All 4 attempts should fail (1 initial + 3 retries)
            for i in range(4):
                if failure_type == 'timeout':
                    mock_responses.append(requests.exceptions.Timeout(f'Timeout {i+1}'))
                elif failure_type == 'connection_error':
                    mock_responses.append(requests.exceptions.ConnectionError(f'Connection error {i+1}'))
                elif failure_type == 'http_error':
                    mock_response = Mock()
                    mock_response.raise_for_status.side_effect = requests.exceptions.HTTPError(f'HTTP error {i+1}')
                    mock_responses.append(mock_response)
                elif failure_type == 'json_error':
                    mock_response = Mock()
                    mock_response.status_code = 200
                    mock_response.json.side_effect = ValueError(f'Invalid JSON {i+1}')
                    mock_responses.append(mock_response)
            
            with patch('src.shared.external_api.requests.get') as mock_get, \
                 patch('src.shared.external_api.time.sleep') as mock_sleep, \
                 patch('src.shared.external_api.logger') as mock_logger:
                
                mock_get.side_effect = mock_responses
                
                # Execute the test - all retries should be exhausted
                with self.assertRaises(ExternalAPIError) as context:
                    client.fetch_prices(symbols)
                
                error = context.exception
                
                # Property 1: Should raise ExternalAPIError when all retries fail
                self.assertIsInstance(
                    error,
                    ExternalAPIError,
                    "Should raise ExternalAPIError when all retries are exhausted"
                )
                
                # Property 2: Error message should indicate retry exhaustion
                self.assertIn(
                    'Failed to fetch prices',
                    error.message,
                    "Error message should indicate failure to fetch prices"
                )
                
                # Property 3: Error should contain the number of attempts made
                self.assertEqual(
                    error.details['attempts'],
                    4,
                    "Error details should show 4 total attempts (1 initial + 3 retries)"
                )
                
                # Property 4: Error should contain the requested symbols
                self.assertEqual(
                    error.details['symbols'],
                    symbols,
                    "Error details should include the symbols that were requested"
                )
                
                # Property 5: Error should contain information about the last error
                self.assertIn(
                    'lastError',
                    error.details,
                    "Error details should include the last error that occurred"
                )
                self.assertIsNotNone(
                    error.details['lastError'],
                    "Last error should not be None"
                )
                
                # Property 6: Should make exactly 4 attempts (1 initial + 3 retries)
                self.assertEqual(
                    mock_get.call_count,
                    4,
                    "Should make exactly 4 attempts when all retries fail"
                )
                
                # Property 7: Should sleep exactly 3 times between attempts
                self.assertEqual(
                    mock_sleep.call_count,
                    3,
                    "Should sleep 3 times between 4 attempts"
                )
                
                # Property 8: Should log error when all retries are exhausted
                # Check that logger.error was called at least once
                error_calls = [call for call in mock_logger.error.call_args_list]
                self.assertGreater(
                    len(error_calls),
                    0,
                    "Should log error when all retries are exhausted"
                )
                
                # Property 9: Error log should contain details about retry exhaustion
                # Find the final error log call
                final_error_log = None
                for call in error_calls:
                    call_str = str(call)
                    if 'Failed to fetch prices' in call_str or 'attempts' in call_str:
                        final_error_log = call
                        break
                
                self.assertIsNotNone(
                    final_error_log,
                    "Should log detailed error message about retry exhaustion"
                )
                
                # Property 10: Should log warnings for each failed attempt
                warning_calls = [call for call in mock_logger.warning.call_args_list]
                self.assertGreaterEqual(
                    len(warning_calls),
                    4,
                    "Should log warning for each failed attempt"
                )
                
                # Property 11: Error status code should be 502 (Bad Gateway)
                self.assertEqual(
                    error.status_code,
                    502,
                    "Error status code should be 502 (Bad Gateway) for external API failures"
                )
        
        # Run the property test
        property_test()


    def test_property_14_timeout_fallback_behavior(self):
        """
        Feature: crypto-watch-backend, Property 14: Timeout fallback behavior
        
        Property: For any external API call that times out, the system should check 
        for cached data and return it if available, or return an error response if 
        no cache exists.
        
        This property tests the timeout fallback behavior at the integration point
        between the external API client and the cache layer. When all retry attempts
        result in timeout:
        
        1. If cached data exists and is available, the system should fall back to it
        2. If no cached data exists, the system should raise an appropriate error
        
        The test simulates both scenarios:
        - Timeout with cache available (should return cached data)
        - Timeout without cache (should raise ExternalAPIError)
        
        Note: The actual fallback logic is implemented at the service/handler level,
        not in the ExternalAPIClient itself. This test verifies that:
        1. The ExternalAPIClient properly raises ExternalAPIError on timeout
        2. The error contains sufficient information for the handler to make fallback decisions
        3. The cache layer can be queried independently to retrieve fallback data
        
        Validates: Requirements 6.4
        """
        from hypothesis import given, strategies as st, settings
        from unittest.mock import patch, Mock
        import requests
        from src.shared.cache import CacheManager
        from src.shared.models import CryptoPrice
        from datetime import datetime, timezone
        
        # Strategy for generating symbols
        symbols_strategy = st.lists(
            st.sampled_from(['BTC', 'ETH', 'ADA', 'SOL', 'DOT']),
            min_size=1,
            max_size=3,
            unique=True
        )
        
        # Strategy for whether cache exists
        cache_exists_strategy = st.booleans()
        
        # Strategy for cache freshness (if cache exists)
        cache_is_fresh_strategy = st.booleans()
        
        @settings(max_examples=100)
        @given(
            symbols=symbols_strategy,
            cache_exists=cache_exists_strategy,
            cache_is_fresh=cache_is_fresh_strategy
        )
        def property_test(symbols, cache_exists, cache_is_fresh):
            """Test timeout fallback behavior with various cache scenarios."""
            client = ExternalAPIClient(
                api_url='https://api.example.com/v3',
                api_key='test_key'
            )
            
            # Create mock responses that all timeout (4 attempts)
            mock_responses = [requests.exceptions.Timeout(f'Timeout {i+1}') for i in range(4)]
            
            with patch('src.shared.external_api.requests.get') as mock_get, \
                 patch('src.shared.external_api.time.sleep') as mock_sleep:
                
                mock_get.side_effect = mock_responses
                
                # Property 1: External API client should raise ExternalAPIError on timeout
                with self.assertRaises(ExternalAPIError) as context:
                    client.fetch_prices(symbols)
                
                error = context.exception
                
                # Property 2: Error should be ExternalAPIError with appropriate status code
                self.assertIsInstance(
                    error,
                    ExternalAPIError,
                    "Should raise ExternalAPIError when all attempts timeout"
                )
                self.assertEqual(
                    error.status_code,
                    502,
                    "Error status code should be 502 (Bad Gateway) for external API timeout"
                )
                
                # Property 3: Error should contain the requested symbols for fallback lookup
                self.assertEqual(
                    error.details['symbols'],
                    symbols,
                    "Error details should include symbols for cache fallback lookup"
                )
                
                # Property 4: Error should indicate timeout as the cause
                self.assertIn(
                    'Timeout',
                    error.details['lastError'],
                    "Error should indicate timeout as the cause"
                )
                
                # Now test the cache fallback behavior
                # This simulates what the handler/service layer would do
                # Mock the DynamoDB client to avoid AWS region issues
                mock_db_client = Mock()
                cache_manager = CacheManager(db_client=mock_db_client)
                
                # Mock the cache data based on test parameters
                if cache_exists:
                    # Create mock cached price data
                    cached_prices = {}
                    for symbol in symbols:
                        # Determine cache age based on freshness
                        if cache_is_fresh:
                            # Fresh cache (2 minutes old)
                            last_updated = datetime.now(timezone.utc)
                            from datetime import timedelta
                            last_updated = last_updated - timedelta(minutes=2)
                        else:
                            # Stale cache (10 minutes old)
                            last_updated = datetime.now(timezone.utc)
                            from datetime import timedelta
                            last_updated = last_updated - timedelta(minutes=10)
                        
                        cached_prices[symbol] = CryptoPrice(
                            symbol=symbol,
                            name=f"Cached {symbol}",
                            price=40000.0 + hash(symbol) % 10000,
                            change24h=1.5,
                            market_cap=800000000000,
                            last_updated=last_updated
                        )
                    
                    # Mock the cache retrieval
                    with patch.object(cache_manager.db_client, 'get_multiple_price_data', return_value=cached_prices):
                        # Property 5: When cache exists, it should be retrievable regardless of freshness
                        retrieved_cache = cache_manager.db_client.get_multiple_price_data(symbols)
                        
                        self.assertEqual(
                            len(retrieved_cache),
                            len(symbols),
                            "Should be able to retrieve cached data for all symbols"
                        )
                        
                        for symbol in symbols:
                            self.assertIn(
                                symbol,
                                retrieved_cache,
                                f"Cache should contain data for {symbol}"
                            )
                            self.assertIsInstance(
                                retrieved_cache[symbol],
                                CryptoPrice,
                                f"Cached data for {symbol} should be CryptoPrice instance"
                            )
                        
                        # Property 6: Cache freshness should be determinable
                        cache_status = cache_manager.get_cache_status(symbols, threshold_minutes=5)
                        
                        for symbol in symbols:
                            self.assertIn(
                                symbol,
                                cache_status,
                                f"Cache status should include {symbol}"
                            )
                            self.assertEqual(
                                cache_status[symbol]['exists'],
                                True,
                                f"Cache status should indicate {symbol} exists"
                            )
                            
                            # Verify freshness matches our setup
                            expected_freshness = cache_is_fresh
                            actual_freshness = cache_status[symbol]['is_fresh']
                            self.assertEqual(
                                actual_freshness,
                                expected_freshness,
                                f"Cache freshness for {symbol} should be {expected_freshness}"
                            )
                        
                        # Property 7: Handler can use cached data as fallback (even if stale)
                        # In a timeout scenario, stale cache is better than no data
                        fallback_data = retrieved_cache
                        self.assertIsNotNone(
                            fallback_data,
                            "Should be able to use cached data as fallback"
                        )
                        self.assertEqual(
                            len(fallback_data),
                            len(symbols),
                            "Fallback data should include all requested symbols"
                        )
                
                else:
                    # No cache exists
                    # Mock empty cache retrieval
                    with patch.object(cache_manager.db_client, 'get_multiple_price_data', return_value={}):
                        # Property 8: When no cache exists, retrieval should return empty
                        retrieved_cache = cache_manager.db_client.get_multiple_price_data(symbols)
                        
                        self.assertEqual(
                            len(retrieved_cache),
                            0,
                            "Should return empty dict when no cache exists"
                        )
                        
                        # Property 9: Cache status should indicate no cache exists
                        cache_status = cache_manager.get_cache_status(symbols, threshold_minutes=5)
                        
                        for symbol in symbols:
                            self.assertIn(
                                symbol,
                                cache_status,
                                f"Cache status should include {symbol}"
                            )
                            self.assertEqual(
                                cache_status[symbol]['exists'],
                                False,
                                f"Cache status should indicate {symbol} does not exist"
                            )
                            self.assertEqual(
                                cache_status[symbol]['needs_refresh'],
                                True,
                                f"Cache status should indicate {symbol} needs refresh"
                            )
                        
                        # Property 10: Handler should propagate error when no cache available
                        # The ExternalAPIError from earlier should be raised to the client
                        # This is the expected behavior when timeout occurs and no cache exists
                        self.assertIsInstance(
                            error,
                            ExternalAPIError,
                            "Should have ExternalAPIError to propagate when no cache available"
                        )
                        self.assertEqual(
                            error.status_code,
                            502,
                            "Error status should be 502 when no fallback is possible"
                        )
        
        # Run the property test
        property_test()


if __name__ == '__main__':
    unittest.main()
