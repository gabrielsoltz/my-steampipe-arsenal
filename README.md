# my-steampipe-arsenal

My Arsenal of Steampipe Queries

# Queries

- [Check Route53 Inactive Alias](#check-route53-inactive-alias-subdomain-takeover)

## Check Route53 Inactive Alias (Subdomain Takeover)

This query examines all [Route53 records of type Alias](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-choosing-alias-non-alias.html) to verify that their targets exist within your environment. It retrieves your Alias supported resources like ALB, NLB, CloudFront, S3, API Gateway (v1 and v2), and Elastic Beanstalk and matches their DNS configurations against the Route 53 alias targets. The query filters out any Route 53 entries that point to non-existent resources. Ensuring that all Route 53 aliases point to valid resources is crucial to prevent potential subdomain takeover attacks.

See the query in [check-route53-inactive-alias.sql](check-route53-inactive-alias.sql)