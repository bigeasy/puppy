#!/bin/bash

puppy module vpc <<-usage
    usage: puppy vpc create

    description:
        Create an AWS VPC.
usage

vpc_name=puppy

#vpcId=`aws ec2 create-vpc --cidr-block 10.0.0.0/28 --query 'Vpc.VpcId' --output text`
vpc_id=$(aws ec2 describe-vpcs --region=us-west-2 | \
    jq --arg vpc "$vpc_name" -r '
        .Vpcs[]
        | select(.Tags) | select(.Tags[] | .Key == "Name" and .Value == $vpc)
        | .VpcId')

if [ -z "$vpc_id" ]; then
    abend "VPC \"$vpc_name\" does not exist." 2>&1
fi

aws ec2 delete-vpc --region=us-west-2 --vpc-id "$vpc_id"
