#!/bin/bash

set -e

puppy module vpc <<-usage
    usage: puppy vpc id

    description:
        Get the puppy vpc id.
usage

vpc_name="$puppy_tag"

aws ec2 describe-vpcs --region=us-west-2 | \
    jq --arg vpc "$vpc_name" -r '.Vpcs[] | select(.Tags) | select(.Tags[] | .Key == "Name" and .Value == $vpc) | .VpcId'
