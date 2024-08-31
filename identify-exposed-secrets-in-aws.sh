# Description: This script is used to scan for secrets in AWS resources using Trufflehog and Steampipe.

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
echo "Scanning for secrets in EC2 Instances user data..."
steampipe --output json query "select instance_id, user_data from aws_ec2_instance" > /tmp/ec2-user-data.json
trufflehog filesystem /tmp/ec2-user-data.json $TRUFFLEHOG_OPTIONS

# Get Launch Template user data
echo "Scanning for secrets in EC2 Launch Templates user data..."
steampipe --output json query "select title, user_data from aws_ec2_launch_template_version" > /tmp/ec2-launch-template-user-data.json
trufflehog filesystem /tmp/ec2-launch-template-user-data.json $TRUFFLEHOG_OPTIONS

# Get Lambda environment variables
echo "Scanning for secrets in Lambda environment variables..."
steampipe --output json query "select name, environment_variables from aws_lambda_function" > /tmp/lambda-env-vars.json
trufflehog filesystem /tmp/lambda-env-vars.json $TRUFFLEHOG_OPTIONS

# Get CloudFormation stack outputs
echo "Scanning for secrets in CloudFormation stack outputs..."
steampipe --output json query "select name, outputs from aws_cloudformation_stack" > /tmp/cloudformation-outputs.json
trufflehog filesystem /tmp/cloudformation-outputs.json $TRUFFLEHOG_OPTIONS  