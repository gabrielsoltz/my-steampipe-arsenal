# my-steampipe-arsenal

My Arsenal of Steampipe Queries

- [Check Route53 Inactive Alias](#check-route53-inactive-alias-subdomain-takeover)

## Check Route53 Inactive Alias (Subdomain Takeover)

This query examines all [Route53 records of type Alias](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-choosing-alias-non-alias.html) to verify that their targets exist within your environment. It retrieves your Alias supported resources like ALB, NLB, CloudFront, S3, API Gateway (v1 and v2), and Elastic Beanstalk and matches their DNS configurations against the Route 53 alias targets. The query filters out any Route 53 entries that point to non-existent resources. Ensuring that all Route 53 aliases point to valid resources is crucial to prevent potential subdomain takeover attacks.

See the query in [check-route53-inactive-alias.sql](check-route53-inactive-alias.sql)

## Check Security Groups with Unkown private sources

This query examines all security groups in your AWS account and identifies security groups that allow traffic from unknown private sources. It retrieves all security groups that allow inbound traffic from private IP ranges that are not part of your VPC CIDR block. This query helps you identify security groups that may have overly permissive inbound rules and could potentially expose your resources to unauthorized access. This query takes doesn't only matches CIDR to CIDR, but instead makes uses of Postgres network functions to check if hosts or networks are included in other networks (subnetting). This query will exclude `0.0.0.0/0` from the results, as it's not what we are looking for.

See the query in [check-sgs-unknown-sources-private.sql](check-sgs-unknown-sources-private.sql)

## Check Security Groups with Unkown public sources

This query examines all security groups in your AWS account and identifies security groups that allow traffic from unknown public sources. It retrieves all security groups that allow inbound traffic from public IP hosts and checks all your ENIs to see if the public IP is associated with any of your resources. This query will show you at a glance which security groups are allowing traffic from unknown public sources. This query will exclude `0.0.0.0/0` from the results, as it's not what we are looking for.

See the query in [check-sgs-unknown-sources-public.sql](check-sgs-unknown-sources-public.sql)