"""
CloudWatch Metrics Module

Provides utilities for publishing custom metrics to CloudWatch.
Validates: Requirements 5.1, 5.3, 5.4
"""

import os
import boto3
from typing import Dict, List, Optional, Any
from datetime import datetime, timezone
import logging

logger = logging.getLogger(__name__)


class MetricsPublisher:
    """
    Publishes custom metrics to CloudWatch.
    
    Handles batching and error handling for metric publication.
    """
    
    def __init__(self):
        """Initialize CloudWatch client."""
        self.cloudwatch = boto3.client('cloudwatch')
        self.namespace = os.environ.get('METRICS_NAMESPACE', 'CryptoWatch')
        self.environment = os.environ.get('ENVIRONMENT', 'dev')
        
    def put_metric(
        self,
        metric_name: str,
        value: float,
        unit: str = 'None',
        dimensions: Optional[Dict[str, str]] = None
    ) -> None:
        """
        Publish a single metric to CloudWatch.
        
        Args:
            metric_name: Name of the metric
            value: Metric value
            unit: CloudWatch unit (Count, Milliseconds, etc.)
            dimensions: Optional dimensions for the metric
        """
        try:
            metric_data = {
                'MetricName': metric_name,
                'Value': value,
                'Unit': unit,
                'Timestamp': datetime.now(timezone.utc),
                'Dimensions': []
            }
            
            # Add environment dimension
            metric_data['Dimensions'].append({
                'Name': 'Environment',
                'Value': self.environment
            })
            
            # Add custom dimensions
            if dimensions:
                for key, value_str in dimensions.items():
                    metric_data['Dimensions'].append({
                        'Name': key,
                        'Value': value_str
                    })
            
            self.cloudwatch.put_metric_data(
                Namespace=self.namespace,
                MetricData=[metric_data]
            )
            
        except Exception as e:
            # Don't fail the request if metrics fail
            logger.warning(f"Failed to publish metric {metric_name}: {e}")
    
    def put_metrics_batch(self, metrics: List[Dict[str, Any]]) -> None:
        """
        Publish multiple metrics to CloudWatch in a batch.
        
        Args:
            metrics: List of metric dictionaries with keys:
                     metric_name, value, unit, dimensions
        """
        if not metrics:
            return
            
        try:
            metric_data = []
            
            for metric in metrics:
                data = {
                    'MetricName': metric['metric_name'],
                    'Value': metric['value'],
                    'Unit': metric.get('unit', 'None'),
                    'Timestamp': datetime.now(timezone.utc),
                    'Dimensions': []
                }
                
                # Add environment dimension
                data['Dimensions'].append({
                    'Name': 'Environment',
                    'Value': self.environment
                })
                
                # Add custom dimensions
                if 'dimensions' in metric and metric['dimensions']:
                    for key, value_str in metric['dimensions'].items():
                        data['Dimensions'].append({
                            'Name': key,
                            'Value': value_str
                        })
                
                metric_data.append(data)
            
            # CloudWatch allows up to 20 metrics per request
            for i in range(0, len(metric_data), 20):
                batch = metric_data[i:i+20]
                self.cloudwatch.put_metric_data(
                    Namespace=self.namespace,
                    MetricData=batch
                )
                
        except Exception as e:
            # Don't fail the request if metrics fail
            logger.warning(f"Failed to publish metrics batch: {e}")
    
    def record_api_request(
        self,
        endpoint: str,
        status_code: int,
        latency_ms: float
    ) -> None:
        """
        Record API request metrics.
        
        Validates: Requirements 5.3
        
        Args:
            endpoint: API endpoint path
            status_code: HTTP status code
            latency_ms: Request latency in milliseconds
        """
        dimensions = {
            'Endpoint': endpoint,
            'StatusCode': str(status_code)
        }
        
        metrics = [
            {
                'metric_name': 'APIRequestCount',
                'value': 1,
                'unit': 'Count',
                'dimensions': dimensions
            },
            {
                'metric_name': 'APILatency',
                'value': latency_ms,
                'unit': 'Milliseconds',
                'dimensions': {'Endpoint': endpoint}
            }
        ]
        
        # Record error if status code indicates error
        if status_code >= 400:
            error_type = 'ClientError' if status_code < 500 else 'ServerError'
            metrics.append({
                'metric_name': 'APIErrors',
                'value': 1,
                'unit': 'Count',
                'dimensions': {
                    'Endpoint': endpoint,
                    'ErrorType': error_type
                }
            })
        
        self.put_metrics_batch(metrics)
    
    def record_dynamodb_operation(
        self,
        operation: str,
        success: bool,
        latency_ms: float = None
    ) -> None:
        """
        Record DynamoDB operation metrics.
        
        Validates: Requirements 5.4
        
        Args:
            operation: Operation type (read, write, query, etc.)
            success: Whether operation succeeded
            latency_ms: Optional operation latency
        """
        dimensions = {
            'Operation': operation,
            'Status': 'Success' if success else 'Failure'
        }
        
        metrics = [
            {
                'metric_name': 'DynamoDBOperations',
                'value': 1,
                'unit': 'Count',
                'dimensions': dimensions
            }
        ]
        
        if latency_ms is not None:
            metrics.append({
                'metric_name': 'DynamoDBLatency',
                'value': latency_ms,
                'unit': 'Milliseconds',
                'dimensions': {'Operation': operation}
            })
        
        if not success:
            metrics.append({
                'metric_name': 'DynamoDBErrors',
                'value': 1,
                'unit': 'Count',
                'dimensions': {'Operation': operation}
            })
        
        self.put_metrics_batch(metrics)
    
    def record_external_api_call(
        self,
        success: bool,
        latency_ms: float = None,
        retry_count: int = 0
    ) -> None:
        """
        Record external API call metrics.
        
        Args:
            success: Whether call succeeded
            latency_ms: Optional call latency
            retry_count: Number of retries attempted
        """
        metrics = [
            {
                'metric_name': 'ExternalAPICallCount',
                'value': 1,
                'unit': 'Count',
                'dimensions': {'Status': 'Success' if success else 'Failure'}
            }
        ]
        
        if latency_ms is not None:
            metrics.append({
                'metric_name': 'ExternalAPILatency',
                'value': latency_ms,
                'unit': 'Milliseconds',
                'dimensions': {}
            })
        
        if retry_count > 0:
            metrics.append({
                'metric_name': 'ExternalAPIRetries',
                'value': retry_count,
                'unit': 'Count',
                'dimensions': {}
            })
        
        if not success:
            metrics.append({
                'metric_name': 'ExternalAPIErrors',
                'value': 1,
                'unit': 'Count',
                'dimensions': {}
            })
        
        self.put_metrics_batch(metrics)
    
    def record_lambda_invocation(
        self,
        function_name: str,
        duration_ms: float,
        success: bool
    ) -> None:
        """
        Record Lambda function invocation metrics.
        
        Validates: Requirements 5.1
        
        Args:
            function_name: Name of the Lambda function
            duration_ms: Execution duration in milliseconds
            success: Whether invocation succeeded
        """
        dimensions = {
            'FunctionName': function_name,
            'Status': 'Success' if success else 'Failure'
        }
        
        metrics = [
            {
                'metric_name': 'LambdaInvocations',
                'value': 1,
                'unit': 'Count',
                'dimensions': dimensions
            },
            {
                'metric_name': 'LambdaDuration',
                'value': duration_ms,
                'unit': 'Milliseconds',
                'dimensions': {'FunctionName': function_name}
            }
        ]
        
        if not success:
            metrics.append({
                'metric_name': 'LambdaErrors',
                'value': 1,
                'unit': 'Count',
                'dimensions': {'FunctionName': function_name}
            })
        
        self.put_metrics_batch(metrics)


# Global metrics publisher instance
_metrics_publisher = None


def get_metrics_publisher() -> MetricsPublisher:
    """
    Get or create the global metrics publisher instance.
    
    Returns:
        MetricsPublisher instance
    """
    global _metrics_publisher
    if _metrics_publisher is None:
        _metrics_publisher = MetricsPublisher()
    return _metrics_publisher
