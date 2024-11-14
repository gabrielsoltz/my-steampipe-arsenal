# my-steampipe-arsenal

My Arsenal of [Steampipe](https://steampipe.io/) queries for AWS Security.

- [Check Route53 Inactive Alias](#check-route53-inactive-alias-subdomain-takeover)
- [Identify Exposed Secrets in AWS](#identify-exposed-secrets-in-aws)
- [Map and Validate AWS External Surface](#map-and-validate-aws-external-surface)
- [Check Security Groups with Unknown private sources](#check-security-groups-with-Unknown-private-sources)
- [Check Security Groups with Unknown public sources](#check-security-groups-with-Unknown-public-sources)

## Check Route53 Inactive Alias (Subdomain Takeover)

This query examines all [Route53 records of type Alias](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-choosing-alias-non-alias.html) to verify that their targets exist within your environment. It retrieves your Alias supported resources like ALB, NLB, CloudFront, S3, API Gateway (v1 and v2), and Elastic Beanstalk and matches their DNS configurations against the Route 53 alias targets. The query filters out any Route 53 entries that point to non-existent resources. Ensuring that all Route 53 aliases point to valid resources is crucial to prevent potential subdomain takeover attacks.

Run: `steampipe query `[check-route53-inactive-alias.sql](check-route53-inactive-alias.sql)

## Identify Exposed Secrets in AWS

The script `identify-exposed-secrets-in-aws.sh`, is a combination of different queries that can be executed to fetch configurations from various AWS services where secrets are commonly exposed. The script gathers information from these services and generates a temporary file, which is then scanned with [TruffleHog](https://github.com/trufflesecurity/trufflehog). TruffleHog analyzes the files to identify verified secrets, so you need to have TruffleHog installed on your system to run this script. Secrets (or long term credentials) are probably the most common cause of security incidents in the cloud. Leaving secrets without the correct protection can lead to unauthorized access to your resources, privilege escalation, lateral movements, and data breaches.
The queries fetch data from the following services:

- EC2 instance user data
- Launch Template user data
- Lambda environment variables
- CloudFormation stack outputs
- SSM Parameters

Run: `./identify-exposed-secrets-in-aws.sh`

See the query in [identify-exposed-secrets-in-aws.sh](identify-exposed-secrets-in-aws.sh)

## Map and Validate AWS External Surface

The script `map-and-validate-aws-external-surface.sh` fetches all possible AWS resources that are exposed to the internet including Route53 Domains type A and CNAME which are public, ELBs (All types) which are internet-facing, Api Gateways, CloudFront Distributions, Lambda Functions with URL, S3 Buckets which are public. You get all this information in a single file under `outputs/input-external-domains.csv`. The list is parsed and organized so then is ingested by [httpx](https://docs.projectdiscovery.io/tools/httpx/overview) to check the status code and response headers of the resources. You get the output of this check in `outputs/validated-external-domains.txt`. This script gives you a non false positive list of resources that are reachable externally. You can scan them or integrate the output with other tools to check for vulnerabilities.

Run: `./map-and-validate-aws-external-surface.sh`

## Check Security Groups with Unknown public sources

This query examines all security groups in your AWS account and identifies security groups that allow traffic from unknown public sources. It retrieves all security groups that allow inbound traffic from public IP hosts and checks all your ENIs to see if the public IP is associated with any of your resources. This query will show you at a glance which security groups are allowing traffic from unknown public sources. This query will exclude `0.0.0.0/0` from the results, as it's not what we are looking for.

Run: `steampipe query ` [check-sgs-unknown-sources-public.sql](check-sgs-unknown-sources-public.sql)

## Check Security Groups with Unknown private sources

This query examines all security groups in your AWS account and identifies security groups that allow traffic from unknown private sources. It retrieves all security groups that allow inbound traffic from private IP ranges that are not part of your VPC CIDR block. This query helps you identify security groups that may have overly permissive inbound rules and could potentially expose your resources to unauthorized access. This query doesn't only match CIDR to CIDR, but instead makes use of Postgres network functions to check if hosts or networks are included in other networks (subnetting). This query will exclude `0.0.0.0/0` from the results, as it's not what we are looking for.

Run: `steampipe query ` [check-sgs-unknown-sources-private.sql](check-sgs-unknown-sources-private.sql)
