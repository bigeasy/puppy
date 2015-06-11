#!/bin/bash

puppy module vpc <<-usage
    usage: puppy vpc create

    description:
        Create an AWS VPC.
usage

vpc_name=puppy

#vpcId=`aws ec2 create-vpc --cidr-block 10.0.0.0/28 --query 'Vpc.VpcId' --output text`
exists=$(aws ec2 describe-vpcs --region=us-west-2 | \
    jq --arg vpc "$vpc_name" -r '
        .Vpcs[]
        | select(.Tags) | select(.Tags[] | .Key == "Name" and .Value == $vpc)
        | .VpcId')

if [ ! -z "$exists" ]; then
    abend "VPC \"$vpc_name\" already exists." 2>&1
fi

vpc_id=$(aws ec2 create-vpc --region=us-west-2 --cidr-block 10.0.0.0/28 | jq -r '.Vpc.VpcId')

aws ec2 create-tags --region=us-west-2 --resources "$vpc_id" --tags 'Key=Name,Value='$vpc_name
