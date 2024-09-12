#!/usr/bin/env bash
#***********************************
#  This script is used to scan for secrets in AWS resources using Trufflehog and Steampipe.
#  Author: Gabriel Soltz (https://github.com/gabrielsoltz)
#************************************

# Trufflehog options
export TRUFFLEHOG_OPTIONS="--fail --no-update --only-verified"

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
steampipe --output json query "select instance_id, user_data from aws_ec2_instance" > /tmp/ec2-user-data.json

# Get Launch Template user data
echo "Fetching EC2 Launch Templates user data..."
steampipe --output json query "select title, user_data from aws_ec2_launch_template_version" > /tmp/ec2-launch-template-user-data.json

# Get Lambda environment variables
echo "Fetching Lambda environment variables..."
steampipe --output json query "select name, environment_variables from aws_lambda_function" > /tmp/lambda-env-vars.json

# Get CloudFormation stack outputs
echo "Fetching CloudFormation stack outputs..."
steampipe --output json query "select name, outputs from aws_cloudformation_stack" > /tmp/cloudformation-outputs.json

# Get SSM Parameters
echo "Fetching SSM Parameters..."
steampipe --output json query "select name, value from aws_ssm_parameter" > /tmp/ssm-parameters.json

# Run Trufflehog
echo "Running Trufflehog for Secrets..."
trufflehog filesystem /tmp/ec2-user-data.json /tmp/ec2-launch-template-user-data.json /tmp/lambda-env-vars.json /tmp/cloudformation-outputs.json /tmp/ssm-parameters.json $TRUFFLEHOG_OPTIONS
