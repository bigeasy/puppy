#!/bin/bash

set -e

puppy module <<-usage
    usage: puppy vpc create

    description:
        Create an AWS VPC.
usage

security_group_id=$(aws ec2 create-security-group \
    --region="$puppy_region" \
    --group-name="$puppy_tag-balancer" \
    --vpc-id="$(puppy_exec vpc id)" \
    --description="Security group for $puppy_tag-balancer load balancer." | jq -r '.GroupId')

echo $security_group_id

aws elb create-load-balancer \
    --region="$puppy_region" \
    --load-balancer-name="$puppy_tag-balancer" \
    --security-groups="$security_group_id" \
    --listeners='Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80' \
    --subnets="$(puppy_exec vpc subnet-id)"

aws elb delete-load-balancer-listeners \
    --region="$puppy_region" \
    --load-balancer-name="$puppy_tag-balancer" \
    --load-balancer-ports=80
