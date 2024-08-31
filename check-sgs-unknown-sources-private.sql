/***********************************
**  Steampipe Query to check for Security Group rules that allow traffic from unknown private sources.
**  Author: Gabriel Soltz (https://github.com/gabrielsoltz)
************************************/

WITH vpc_subnets AS (
    SELECT
        s.subnet_id,
        s.vpc_id,
        s.cidr_block,
        s.account_id,
        s.region
    FROM
        aws_vpc_subnet s
    ORDER BY
        s.cidr_block
),
security_group_rules AS (
    SELECT
        r.security_group_rule_id,
        r.ip_protocol,
        r.from_port,
        r.to_port,
        r.cidr_ipv4,
        r.account_id,
        r.region,
        r.is_egress,
        host(r.cidr_ipv4) AS ip_address,
        masklen(r.cidr_ipv4) AS subnet_mask,
        r.group_id,
        sg.group_name,
        sg.vpc_id
    FROM
        aws_vpc_security_group_rule AS r
    JOIN
        aws_vpc_security_group AS sg
    ON
        r.group_id = sg.group_id
)
SELECT 
    r.group_id,
    r.group_name,
    r.ip_protocol,
    r.from_port,
    r.to_port,
    r.cidr_ipv4,
    r.is_egress,
    r.vpc_id,
    r.account_id,
    r.region
FROM 
    security_group_rules AS r
WHERE
    -- Check if the rule is an ingress rule
    r.is_egress = FALSE
    -- Exclude rules that allow all traffic
    AND r.cidr_ipv4 != '0.0.0.0/0'
    -- Exclude rules that are not IP based
    AND r.cidr_ipv4 IS NOT NULL
    AND (
        -- Exclude public CIDR ranges, and leaves only private CIDR ranges
        r.cidr_ipv4::cidr <<= '10.0.0.0/8'::cidr
        OR r.cidr_ipv4::cidr <<= '172.16.0.0/12'::cidr
        OR r.cidr_ipv4::cidr <<= '192.168.0.0/16'::cidr
    )
    AND NOT EXISTS (
        SELECT 1
        FROM vpc_subnets AS s
        WHERE r.cidr_ipv4::cidr <<= s.cidr_block::cidr
    );
