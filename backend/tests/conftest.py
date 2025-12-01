"""
Pytest configuration and shared fixtures.
"""

import pytest
import os
import sys
from pathlib import Path

# Add src directory to Python path for imports
src_path = Path(__file__).parent.parent / 'src'
if str(src_path) not in sys.path:
    sys.path.insert(0, str(src_path))


@pytest.fixture(scope='session')
def aws_credentials():
    """Mock AWS credentials for testing."""
    os.environ['AWS_ACCESS_KEY_ID'] = 'testing'
    os.environ['AWS_SECRET_ACCESS_KEY'] = 'testing'
    os.environ['AWS_SECURITY_TOKEN'] = 'testing'
    os.environ['AWS_SESSION_TOKEN'] = 'testing'
    os.environ['AWS_DEFAULT_REGION'] = 'us-east-1'


@pytest.fixture(scope='session')
def environment_variables():
    """Set up test environment variables."""
    os.environ['ENVIRONMENT'] = 'test'
    os.environ['DYNAMODB_TABLE_NAME'] = 'crypto-watch-data-test'
    os.environ['RATE_LIMIT_PER_MINUTE'] = '100'
    os.environ['CACHE_TTL_SECONDS'] = '300'
    os.environ['LOG_LEVEL'] = 'DEBUG'
