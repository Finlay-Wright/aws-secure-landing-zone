"""
Auto-tagging remediation Lambda function.

Triggered by AWS Config compliance changes. When a resource is flagged for missing
required tags, this attempts to apply sensible defaults based on resource metadata.

For resources that can't be auto-tagged, logs a warning for manual follow-up.
"""

import json
import logging
import os
from datetime import datetime
from typing import Dict, List, Optional

import boto3
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS clients
config_client = boto3.client('config')
tagging_client = boto3.client('resourcegroupstaggingapi')
ssm_client = boto3.client('ssm')
sns_client = boto3.client('sns')

# Environment variables
DEFAULT_TAGS_PARAMETER = os.environ.get('DEFAULT_TAGS_SSM_PARAMETER', '/baseline/default-tags')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN', '')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'unknown')

# Resources that support tagging via Resource Groups Tagging API
TAGGABLE_RESOURCES = {
    'AWS::EC2::Instance',
    'AWS::EC2::Volume',
    'AWS::EC2::Snapshot',
    'AWS::EC2::VPC',
    'AWS::EC2::Subnet',
    'AWS::EC2::SecurityGroup',
    'AWS::RDS::DBInstance',
    'AWS::RDS::DBCluster',
    'AWS::S3::Bucket',
    'AWS::Lambda::Function',
    'AWS::DynamoDB::Table',
    'AWS::ECS::Cluster',
    'AWS::ECS::Service',
    'AWS::EKS::Cluster',
    'AWS::EFS::FileSystem',
}


def lambda_handler(event, context):
    """
    Main Lambda handler triggered by Config compliance changes.

    Event structure from Config:
    {
        "configRuleName": "required-tag-environment",
        "configRuleARN": "arn:aws:config:...",
        "configRuleId": "...",
        "accountId": "123456789012",
        "newEvaluationResult": {
            "complianceType": "NON_COMPLIANT",
            "evaluationResultIdentifier": {
                "evaluationResultQualifier": {
                    "configRuleName": "required-tag-environment",
                    "resourceType": "AWS::EC2::Instance",
                    "resourceId": "i-1234567890abcdef0"
                }
            }
        }
    }
    """
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        # Parse Config event
        if 'detail' in event:
            # EventBridge format
            detail = event['detail']
            new_result = detail.get('newEvaluationResult', {})
        else:
            # Direct Config notification
            new_result = event.get('newEvaluationResult', {})

        compliance_type = new_result.get('complianceType')

        # Only process NON_COMPLIANT resources
        if compliance_type != 'NON_COMPLIANT':
            logger.info(f"Resource is {compliance_type}, no action needed")
            return {'statusCode': 200, 'body': 'Resource compliant'}

        # Extract resource details
        result_id = new_result.get('evaluationResultIdentifier', {})
        qualifier = result_id.get('evaluationResultQualifier', {})

        resource_type = qualifier.get('resourceType')
        resource_id = qualifier.get('resourceId')
        config_rule_name = qualifier.get('configRuleName')

        if not resource_type or not resource_id:
            logger.error("Missing resource type or ID in event")
            return {'statusCode': 400, 'body': 'Invalid event'}

        logger.info(f"Processing non-compliant resource: {resource_type}/{resource_id}")

        # Check if resource type supports auto-tagging
        if resource_type not in TAGGABLE_RESOURCES:
            msg = f"Resource type {resource_type} does not support auto-tagging"
            logger.warning(msg)
            send_notification(resource_type, resource_id, msg)
            return {'statusCode': 200, 'body': 'Resource type not supported'}

        # Get resource ARN
        resource_arn = get_resource_arn(resource_type, resource_id)
        if not resource_arn:
            logger.error(f"Could not determine ARN for {resource_type}/{resource_id}")
            return {'statusCode': 500, 'body': 'Could not determine resource ARN'}

        # Get current tags
        current_tags = get_resource_tags(resource_arn)

        # Determine which tag is missing based on config rule name
        missing_tag = extract_missing_tag_from_rule_name(config_rule_name)

        # Generate default tags
        default_tags = generate_default_tags(resource_type, resource_id, missing_tag)

        # Merge with current tags (don't overwrite existing)
        tags_to_apply = {k: v for k, v in default_tags.items() if k not in current_tags}

        if not tags_to_apply:
            logger.info("No new tags to apply")
            return {'statusCode': 200, 'body': 'No tags needed'}

        # Apply tags
        success = apply_tags(resource_arn, tags_to_apply)

        if success:
            logger.info(f"Successfully applied tags {tags_to_apply} to {resource_arn}")
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Tags applied successfully',
                    'resource': resource_arn,
                    'tags': tags_to_apply
                })
            }
        else:
            logger.error(f"Failed to apply tags to {resource_arn}")
            send_notification(resource_type, resource_id, f"Failed to auto-tag. Manual intervention required.")
            return {'statusCode': 500, 'body': 'Failed to apply tags'}

    except Exception as e:
        logger.exception(f"Error processing event: {str(e)}")
        return {'statusCode': 500, 'body': f'Error: {str(e)}'}


def get_resource_arn(resource_type: str, resource_id: str) -> Optional[str]:
    """Construct ARN from resource type and ID."""
    try:
        # Get account and region info
        sts = boto3.client('sts')
        account_id = sts.get_caller_identity()['Account']
        region = os.environ.get('AWS_REGION', 'eu-west-2')

        # Map resource types to ARN patterns
        arn_patterns = {
            'AWS::EC2::Instance': f'arn:aws:ec2:{region}:{account_id}:instance/{resource_id}',
            'AWS::EC2::Volume': f'arn:aws:ec2:{region}:{account_id}:volume/{resource_id}',
            'AWS::EC2::Snapshot': f'arn:aws:ec2:{region}:{account_id}:snapshot/{resource_id}',
            'AWS::EC2::VPC': f'arn:aws:ec2:{region}:{account_id}:vpc/{resource_id}',
            'AWS::EC2::Subnet': f'arn:aws:ec2:{region}:{account_id}:subnet/{resource_id}',
            'AWS::EC2::SecurityGroup': f'arn:aws:ec2:{region}:{account_id}:security-group/{resource_id}',
            'AWS::RDS::DBInstance': f'arn:aws:rds:{region}:{account_id}:db:{resource_id}',
            'AWS::RDS::DBCluster': f'arn:aws:rds:{region}:{account_id}:cluster:{resource_id}',
            'AWS::S3::Bucket': f'arn:aws:s3:::{resource_id}',
            'AWS::Lambda::Function': f'arn:aws:lambda:{region}:{account_id}:function:{resource_id}',
            'AWS::DynamoDB::Table': f'arn:aws:dynamodb:{region}:{account_id}:table/{resource_id}',
            'AWS::ECS::Cluster': f'arn:aws:ecs:{region}:{account_id}:cluster/{resource_id}',
            'AWS::EKS::Cluster': f'arn:aws:eks:{region}:{account_id}:cluster/{resource_id}',
            'AWS::EFS::FileSystem': f'arn:aws:elasticfilesystem:{region}:{account_id}:file-system/{resource_id}',
        }

        return arn_patterns.get(resource_type)

    except Exception as e:
        logger.error(f"Error constructing ARN: {str(e)}")
        return None


def get_resource_tags(resource_arn: str) -> Dict[str, str]:
    """Get current tags for a resource."""
    try:
        response = tagging_client.get_resources(
            ResourceARNList=[resource_arn]
        )

        if response['ResourceTagMappingList']:
            tags = response['ResourceTagMappingList'][0].get('Tags', [])
            return {tag['Key']: tag['Value'] for tag in tags}

        return {}

    except ClientError as e:
        logger.error(f"Error getting tags for {resource_arn}: {str(e)}")
        return {}


def extract_missing_tag_from_rule_name(rule_name: str) -> str:
    """
    Extract the tag key from config rule name.
    Example: 'required-tag-environment' -> 'Environment'
    """
    if not rule_name or not rule_name.startswith('required-tag-'):
        return ''

    # Remove 'required-tag-' prefix and capitalize
    tag_key = rule_name.replace('required-tag-', '')
    return tag_key.capitalize()


def generate_default_tags(resource_type: str, resource_id: str, missing_tag: str) -> Dict[str, str]:
    """
    Generate sensible default tags based on resource metadata.

    Priority:
    1. Retrieve defaults from SSM Parameter Store
    2. Use environment-based defaults
    3. Use hardcoded fallbacks
    """
    tags = {}

    # Try to get account-level defaults from SSM
    try:
        response = ssm_client.get_parameter(Name=DEFAULT_TAGS_PARAMETER)
        ssm_tags = json.loads(response['Parameter']['Value'])
        tags.update(ssm_tags)
    except Exception as e:
        logger.warning(f"Could not retrieve default tags from SSM: {str(e)}")

    # Environment tag
    if 'Environment' not in tags:
        tags['Environment'] = ENVIRONMENT

    # Owner tag - use a default for now
    if 'Owner' not in tags:
        tags['Owner'] = 'platform-team'

    # CostCenter tag
    if 'CostCenter' not in tags:
        tags['CostCenter'] = 'engineering'

    # DataClassification tag - default to internal
    if 'DataClassification' not in tags:
        tags['DataClassification'] = 'internal'

    # Add remediation metadata
    tags['AutoTaggedBy'] = 'baseline-remediation'
    tags['AutoTaggedDate'] = datetime.utcnow().strftime('%Y-%m-%d')

    return tags


def apply_tags(resource_arn: str, tags: Dict[str, str]) -> bool:
    """Apply tags to a resource."""
    try:
        tag_list = [{'Key': k, 'Value': v} for k, v in tags.items()]

        tagging_client.tag_resources(
            ResourceARNList=[resource_arn],
            Tags=tags
        )

        logger.info(f"Applied tags to {resource_arn}: {tags}")
        return True

    except ClientError as e:
        logger.error(f"Error applying tags to {resource_arn}: {str(e)}")
        return False


def send_notification(resource_type: str, resource_id: str, message: str):
    """Send SNS notification for resources that need manual tagging."""
    if not SNS_TOPIC_ARN:
        logger.info("No SNS topic configured, skipping notification")
        return

    try:
        subject = f"Manual Tagging Required: {resource_type}"
        body = f"""
Resource requires manual tagging:

Resource Type: {resource_type}
Resource ID: {resource_id}
Reason: {message}

Please add the required tags manually via the AWS Console or CLI.
        """

        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=body
        )

        logger.info(f"Sent notification for {resource_type}/{resource_id}")

    except Exception as e:
        logger.error(f"Error sending SNS notification: {str(e)}")
