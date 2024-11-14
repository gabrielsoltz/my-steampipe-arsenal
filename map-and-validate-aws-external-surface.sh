#!/usr/bin/env bash
#***********************************
#  Map and Validate AWS External Surface
#  Author: Gabriel Soltz (https://github.com/gabrielsoltz)
#************************************
# Requirements:
# - Steampipe (https://steampipe.io/downloads)
# - httpx (https://docs.projectdiscovery.io/tools/httpx/install)

echo "Starting script to validate external domains hosted in AWS Route 53..."

# Files
DATE=$(date '+%Y-%m-%d-%H-%M-%S')
INPUT_FILE_DNS="outputs/input-external-domains-$DATE.csv"
OUTPUT_FILE="outputs/validated-external-domains-$DATE.txt"

# Check if httpx is installed
if ! command -v httpx &> /dev/null
then
    echo "Httpx could not be found. Please install: https://docs.projectdiscovery.io/tools/httpx/install."
    exit
fi

# Check if Steampipe is installed
if ! command -v steampipe &> /dev/null
then
    echo "Steampipe could not be found. Please install: https://steampipe.io/downloads."
    exit
fi

# Steampipe queries

ROUTE53_QUERY="""
with route_53_records as (
  select
    r.name as url,
    type,
    jsonb_array_elements_text(records) as resource_record
  from
    aws_route53_zone as z,
    aws_route53_record as r
  where r.zone_id = z.id
    and (type LIKE 'A' OR type LIKE 'CNAME')
    and z.private_zone=false
    and jsonb_pretty(records) not like '%dkim%'
    and jsonb_pretty(records) not like '%acm-validations.aws.%'
) select
  url,
  'route_53_domain' as type
from route_53_records;
"""

ELB_QUERY="""
select
  lower(l.protocol) || '://' || lb.dns_name || ':' || l.port as url,
  'application_load_balancer' as type
from
  aws_ec2_application_load_balancer as lb,
  aws_ec2_load_balancer_listener as l
where
  lb.scheme LIKE 'internet-facing'
  and lb.state_code LIKE 'active'
  and l.load_balancer_arn = lb.arn;
"""

APIGW_QUERY="""
select
  'https://' || api_id || '.execute-api.' || region || '.amazonaws.com/' || stage_name as url,
  'api_gateway' as type
from aws_api_gatewayv2_stage;
"""

CLOUDFRONT_QUERY="""
select
  'https://' || domain_name as url,
  'cloudfront_distribution' as type
from
  aws_cloudfront_distribution
UNION ALL
select
  'https://' || jsonb_array_elements_text(aliases -> 'Items') as url,
  'cloudfront_distribution_alias' as type
from
  aws_cloudfront_distribution;
"""

LAMBDA_QUERY="""
select
  url_config ->> 'FunctionUrl' as url,
  'lambda_url' as type
from aws_lambda_function
where url_config is not Null;
"""

S3_QUERY="""
select
  'https://' || name || '.s3.' || region || '.amazonaws.com/' as url,
  's3_bucket_url' as type
from
  aws_s3_bucket
where
  bucket_policy_is_public is True;
"""

# Execute Query and save results to files
echo "Executing Steampipe queries..."

echo "Querying Route 53 records..."
steampipe query "$ROUTE53_QUERY" --header=false --output csv >> "$INPUT_FILE_DNS"

echo "Querying Elastic Load Balancers..."
steampipe query "$ELB_QUERY" --header=false --output csv >> "$INPUT_FILE_DNS"

echo "Querying API Gateway..."
steampipe query "$APIGW_QUERY" --header=false --output csv >> "$INPUT_FILE_DNS"

echo "Querying Cloudfront..."
steampipe query "$CLOUDFRONT_QUERY" --header=false --output csv >> "$INPUT_FILE_DNS"

echo "Querying Lambda functions..."
steampipe query "$LAMBDA_QUERY" --header=false --output csv >> "$INPUT_FILE_DNS"

echo "Querying S3 buckets..."
steampipe query "$S3_QUERY" --header=false --output csv >> "$INPUT_FILE_DNS"

# Validate with httpx
echo "Validating external domains using Httpx..."
cut -d',' -f1 "$INPUT_FILE_DNS" > "$INPUT_FILE_DNS"-urls
httpx -silent -title -status-code -content-length -o "$OUTPUT_FILE" -l "$INPUT_FILE_DNS"-urls

echo "Script finished. Results saved in $OUTPUT_FILE."
