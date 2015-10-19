#!/bin/bash

puppy module vpc <<-usage
    usage: puppy vpc security-group-id

    description:
        Get current security group id.
usage

vpc_id=$(puppy_exec vpc id)

[ -z "$vpc_id" ] && exit 1

aws ec2 describe-security-groups --region="$puppy_region" | \
    jq -r --arg tag $puppy_tag --arg vpc $vpc_id '.SecurityGroups[] | select(.VpcId == $vpc) | select(.GroupName == $tag + "-balancer") .GroupId'
