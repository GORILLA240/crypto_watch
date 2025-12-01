# Automatic Rollback Verification

## Overview

The crypto-watch-backend implements automatic rollback functionality using AWS CodeDeploy and CloudWatch Alarms. This document describes how to verify and test the rollback mechanism.

## Rollback Architecture

### Components

1. **Lambda Alias**: `live` alias for traffic management
2. **CodeDeploy**: Manages gradual traffic shifting
3. **CloudWatch Alarms**: Monitor deployment health
4. **SNS Topics**: Send notifications on rollback events

### Traffic Shifting Strategy

- **Type**: Linear10PercentEvery1Minute
- **Duration**: 10 minutes for full deployment
- **Monitoring**: Continuous during traffic shift

## CloudWatch Alarms Configuration

### Alarm 1: Lambda Errors

```yaml
LambdaErrorAlarm:
  Type: AWS::CloudWatch::Alarm
  Properties:
    AlarmName: !Sub "${AWS::StackName}-LambdaErrors"
    AlarmDescription: Lambda error rate exceeds threshold
    MetricName: Errors
    Namespace: AWS/Lambda
    Statistic: Sum
    Period: 60
    EvaluationPeriods: 2
    Threshold: 5
    ComparisonOperator: GreaterThanThreshold
    TreatMissingData: notBreaching
```

**Trigger**: More than 5 errors in 2 consecutive minutes

### Alarm 2: API Gateway 5xx Errors

```yaml
ApiGateway5xxAlarm:
  Type: AWS::CloudWatch::Alarm
  Properties:
    AlarmName: !Sub "${AWS::StackName}-ApiGateway5xx"
    AlarmDescription: API Gateway 5xx error rate exceeds threshold
    MetricName: 5XXError
    Namespace: AWS/ApiGateway
    Statistic: Average
    Period: 60
    EvaluationPeriods: 2
    Threshold: 0.1  # 10%
    ComparisonOperator: GreaterThanThreshold
```

**Trigger**: More than 10% 5xx errors in 2 consecutive minutes

### Alarm 3: Lambda Throttles

```yaml
LambdaThrottleAlarm:
  Type: AWS::CloudWatch::Alarm
  Properties:
    AlarmName: !Sub "${AWS::StackName}-LambdaThrottles"
    AlarmDescription: Lambda throttle count exceeds threshold
    MetricName: Throttles
    Namespace: AWS/Lambda
    Statistic: Sum
    Period: 60
    EvaluationPeriods: 1
    Threshold: 10
    ComparisonOperator: GreaterThanThreshold
```

**Trigger**: More than 10 throttles in 1 minute

## Verification Steps

### 1. Verify Alarm Configuration

```bash
# List all alarms for the stack
aws cloudwatch describe-alarms \
  --alarm-name-prefix "crypto-watch-backend-prod" \
  --query 'MetricAlarms[*].[AlarmName,StateValue,MetricName]' \
  --output table

# Check alarm details
aws cloudwatch describe-alarms \
  --alarm-names "crypto-watch-backend-prod-LambdaErrors" \
  --output json
```

### 2. Verify CodeDeploy Configuration

```bash
# Get deployment configuration
aws deploy get-deployment-config \
  --deployment-config-name CodeDeployDefault.LambdaLinear10PercentEvery1Minute

# List deployments
aws deploy list-deployments \
  --application-name ServerlessDeploymentApplication \
  --deployment-group-name crypto-watch-backend-prod-DeploymentGroup
```

### 3. Verify Alarm-Deployment Integration

Check SAM template for DeploymentPreference:

```yaml
DeploymentPreference:
  Type: Linear10PercentEvery1Minute
  Alarms:
    - !Ref LambdaErrorAlarm
    - !Ref ApiGateway5xxAlarm
    - !Ref LambdaThrottleAlarm
  Hooks:
    PreTraffic: !Ref PreTrafficHook  # Optional
    PostTraffic: !Ref PostTrafficHook  # Optional
```

## Testing Rollback

### Scenario 1: Simulate Lambda Errors

1. Deploy a version with intentional errors
2. Monitor CloudWatch Alarms
3. Verify automatic rollback

```python
# Example: Deploy version that always fails
def lambda_handler(event, context):
    raise Exception("Intentional error for rollback test")
```

### Scenario 2: Simulate High Error Rate

1. Deploy version with conditional errors
2. Generate traffic to trigger alarm
3. Verify rollback

```python
import random

def lambda_handler(event, context):
    if random.random() < 0.15:  # 15% error rate
        raise Exception("Simulated error")
    return {"statusCode": 200, "body": "OK"}
```

### Scenario 3: Monitor Real Deployment

```bash
# Watch deployment progress
watch -n 10 'aws deploy get-deployment \
  --deployment-id <deployment-id> \
  --query "deploymentInfo.status"'

# Monitor alarms during deployment
watch -n 10 'aws cloudwatch describe-alarms \
  --alarm-names \
    crypto-watch-backend-prod-LambdaErrors \
    crypto-watch-backend-prod-ApiGateway5xx \
  --query "MetricAlarms[*].[AlarmName,StateValue]" \
  --output table'
```

## Rollback Notification Setup

### SNS Topic Configuration

```yaml
RollbackNotificationTopic:
  Type: AWS::SNS::Topic
  Properties:
    TopicName: !Sub "${AWS::StackName}-rollback-notifications"
    DisplayName: Rollback Notifications
    Subscription:
      - Endpoint: !Ref AlertEmail
        Protocol: email
      - Endpoint: !Ref SlackWebhookUrl
        Protocol: https
```

### Slack Integration

1. Create Slack Incoming Webhook
2. Add webhook URL to SNS subscription
3. Configure message format

```json
{
  "text": "🚨 Automatic Rollback Triggered",
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Deployment Rollback*\n\nStack: crypto-watch-backend-prod\nReason: Lambda error rate exceeded threshold\nTime: 2024-01-15 10:30:00 UTC"
      }
    }
  ]
}
```

### Email Notification

Configure SNS email subscription:

```bash
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:123456789012:crypto-watch-backend-prod-rollback \
  --protocol email \
  --notification-endpoint ops-team@example.com
```

## Incident Report Generation

### Automatic Report Script

```python
#!/usr/bin/env python3
"""
Generate incident report for rollback events.
"""

import boto3
from datetime import datetime, timedelta

def generate_incident_report(deployment_id, stack_name):
    """Generate incident report for a rollback."""
    
    # Initialize AWS clients
    logs = boto3.client('logs')
    cloudwatch = boto3.client('cloudwatch')
    deploy = boto3.client('deploy')
    
    # Get deployment details
    deployment = deploy.get_deployment(deploymentId=deployment_id)
    
    # Get error logs from CloudWatch
    log_group = f'/aws/lambda/{stack_name}-ApiFunction'
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(hours=1)
    
    logs_response = logs.filter_log_events(
        logGroupName=log_group,
        startTime=int(start_time.timestamp() * 1000),
        endTime=int(end_time.timestamp() * 1000),
        filterPattern='ERROR'
    )
    
    # Get metrics snapshot
    metrics = cloudwatch.get_metric_statistics(
        Namespace='AWS/Lambda',
        MetricName='Errors',
        Dimensions=[{'Name': 'FunctionName', 'Value': f'{stack_name}-ApiFunction'}],
        StartTime=start_time,
        EndTime=end_time,
        Period=300,
        Statistics=['Sum', 'Average']
    )
    
    # Generate report
    report = {
        'timestamp': datetime.utcnow().isoformat(),
        'deployment_id': deployment_id,
        'stack_name': stack_name,
        'status': deployment['deploymentInfo']['status'],
        'error_logs': logs_response['events'][:10],  # First 10 errors
        'metrics': metrics['Datapoints'],
        'timeline': generate_timeline(deployment)
    }
    
    return report

def generate_timeline(deployment):
    """Generate deployment timeline."""
    info = deployment['deploymentInfo']
    timeline = []
    
    if 'createTime' in info:
        timeline.append({
            'time': info['createTime'].isoformat(),
            'event': 'Deployment Started'
        })
    
    if 'completeTime' in info:
        timeline.append({
            'time': info['completeTime'].isoformat(),
            'event': 'Deployment Completed/Rolled Back'
        })
    
    return timeline

if __name__ == '__main__':
    import sys
    if len(sys.argv) < 3:
        print("Usage: python generate_incident_report.py <deployment-id> <stack-name>")
        sys.exit(1)
    
    report = generate_incident_report(sys.argv[1], sys.argv[2])
    
    # Save report
    with open(f'incident_report_{sys.argv[1]}.json', 'w') as f:
        import json
        json.dump(report, f, indent=2, default=str)
    
    print(f"Incident report generated: incident_report_{sys.argv[1]}.json")
```

## Rollback Verification Checklist

- [ ] CloudWatch Alarms are configured correctly
- [ ] Alarms are linked to DeploymentPreference in SAM template
- [ ] SNS Topic is created for notifications
- [ ] Email subscriptions are confirmed
- [ ] Slack webhook is configured (if using)
- [ ] Test deployment with intentional errors
- [ ] Verify automatic rollback occurs
- [ ] Verify notifications are sent
- [ ] Verify incident report generation
- [ ] Document rollback procedures
- [ ] Train team on rollback response

## Troubleshooting

### Rollback Not Triggered

1. Check alarm state:
   ```bash
   aws cloudwatch describe-alarm-history \
     --alarm-name crypto-watch-backend-prod-LambdaErrors \
     --max-records 10
   ```

2. Verify alarm thresholds are appropriate
3. Check if alarms are linked to deployment

### False Positive Rollbacks

1. Review alarm thresholds
2. Adjust evaluation periods
3. Consider using composite alarms

### Notifications Not Received

1. Verify SNS subscription status
2. Check email spam folder
3. Test SNS topic manually:
   ```bash
   aws sns publish \
     --topic-arn <topic-arn> \
     --message "Test notification"
   ```

## Best Practices

1. **Test Regularly**: Run rollback tests quarterly
2. **Monitor Metrics**: Review alarm metrics weekly
3. **Adjust Thresholds**: Fine-tune based on actual traffic
4. **Document Incidents**: Keep records of all rollbacks
5. **Review Process**: Update procedures based on lessons learned
6. **Train Team**: Ensure all team members understand rollback process

## References

- [AWS CodeDeploy Documentation](https://docs.aws.amazon.com/codedeploy/)
- [CloudWatch Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)
- [SAM Deployment Preferences](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/automating-updates-to-serverless-apps.html)
