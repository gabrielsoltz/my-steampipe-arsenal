#!/usr/bin/env bash
#***********************************
#  This script list all external domains hosted in AWS Route 53 and validates them using httpx to get a non false positive list of your public domains. You can use this list for scanning with Nuclei or other tools.
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

# Check if Nuclei is installed
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

STEAMPIPE_QUERY="
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
) select url from route_53_records;
"

# Execute Query and save results to files
echo "Executing Steampipe query to list all external domains hosted in AWS Route 53..."
steampipe query "$STEAMPIPE_QUERY" --header=false --output csv > "$INPUT_FILE_DNS"

# Validate with httpx
echo "Validating external domains using Httpx..."
httpx -silent -l "$INPUT_FILE_DNS" -title -status-code -content-length -o "$OUTPUT_FILE"

echo "Script finished. Results saved in $OUTPUT_FILE."
