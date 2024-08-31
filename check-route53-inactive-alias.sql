/***********************************
**  Steampipe Query to check for inactive Route53 Alias records.
**  Author: Gabriel Soltz (https://github.com/gabrielsoltz)
************************************/

WITH route53_alias AS (
  SELECT
    r53.name as record_name,
    r53.type as record_type,
    r53.zone_id as zone_id,
    r53.account_id as account_id,
    LEFT(r53.alias_target ->> 'DNSName', LENGTH(r53.alias_target ->> 'DNSName') - 1) AS alias_target_dns_name
  FROM
    aws_route53_record r53
  WHERE
    r53.alias_target IS NOT NULL
)
SELECT
  t.record_name,
  t.record_type,
  t.zone_id,
  t.account_id,
  t.alias_target_dns_name
FROM
  route53_alias t
LEFT JOIN
  aws_ec2_application_load_balancer alb
  ON t.alias_target_dns_name = alb.dns_name
LEFT JOIN
  aws_ec2_network_load_balancer nlb
  ON t.alias_target_dns_name = nlb.dns_name
LEFT JOIN
  aws_cloudfront_distribution cfd
  ON t.alias_target_dns_name = cfd.domain_name
LEFT JOIN
  aws_api_gateway_domain_name agw
  ON t.alias_target_dns_name = agw.regional_domain_name
LEFT JOIN
  aws_api_gatewayv2_domain_name agw2
  ON t.alias_target_dns_name = agw2.domain_name_configurations -> 0 ->> 'ApiGatewayDomainName'
LEFT JOIN
  aws_elastic_beanstalk_environment ebse
  ON t.alias_target_dns_name = ebse.cname
WHERE
    alb.dns_name IS NULL
    AND nlb.dns_name IS NULL
    AND cfd.domain_name IS NULL
    AND agw.regional_domain_name IS NULL
    AND agw2.domain_name_configurations IS NULL
    AND ebse.cname IS NULL
ORDER BY
    t.account_id,
    t.record_name;