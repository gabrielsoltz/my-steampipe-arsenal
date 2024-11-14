#!/usr/bin/env bash
#***********************************
#  This script is used to scan for secrets in AWS resources using Trufflehog and Steampipe.
#  Author: Gabriel Soltz (https://github.com/gabrielsoltz)
#************************************

# Trufflehog options
export TRUFFLEHOG_OPTIONS="--fail --no-update --only-verified --json"
D=$(date '+%Y-%m-%d-%H-%M-%S')
export FILE_DATA_TO_SCAN="outputs/aws-outputs-$D.json"
export FILE_OUTPUT="outputs/aws-trufflehog-output-$D.json"

echo "Scanning for exposed secrets in AWS services..."

# Check if Trufflehog is installed
if ! command -v trufflehog &> /dev/null
then
    echo "Trufflehog could not be found. Please install: https://github.com/trufflesecurity/trufflehog."
    exit
fi

# Check if Steampipe is installed
if ! command -v steampipe &> /dev/null
then
    echo "Steampipe could not be found. Please install: https://steampipe.io/downloads."
    exit
fi

# Get EC2 Instances user data
echo "Fetching EC2 Instances user data..."
steampipe --output json query "select 'ec2_instance_user_data' AS source, instance_id, user_data from aws_ec2_instance" >> "$FILE_DATA_TO_SCAN"

# Get Launch Template user data
echo "Fetching EC2 Launch Templates user data..."
steampipe --output json query "select 'ec2_launch_template_user_data' AS source, title, user_data from aws_ec2_launch_template_version" >> "$FILE_DATA_TO_SCAN"

# Get Lambda environment variables
echo "Fetching Lambda environment variables..."
steampipe --output json query "select 'lambda_function_env_var' AS source, name, environment_variables from aws_lambda_function" >> "$FILE_DATA_TO_SCAN"

# Get CloudFormation stack outputs
echo "Fetching CloudFormation stack outputs..."
steampipe --output json query "select 'cloudformation_stack_output' AS source, name, outputs from aws_cloudformation_stack" >> "$FILE_DATA_TO_SCAN"

# Get SSM Parameters
echo "Fetching SSM Parameters..."
steampipe --output json query "select 'ssm_parameter' AS source, name, value from aws_ssm_parameter" >> "$FILE_DATA_TO_SCAN"

# ECS Task Definitions
echo "Fetching ECS Task Definitions..."
steampipe --output json query "select 'ecs_task_definition' AS source, family, container_definitions from aws_ecs_task_definition" >> "$FILE_DATA_TO_SCAN"

# Run Trufflehog
echo "Running Trufflehog for Secrets..."
trufflehog filesystem "$FILE_DATA_TO_SCAN $TRUFFLEHOG_OPTIONS" > "$FILE_OUTPUT"

echo "Script finished. Results saved in $FILE_OUTPUT."
