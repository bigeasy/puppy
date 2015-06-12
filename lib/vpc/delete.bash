#!/bin/bash

set -e

puppy module vpc <<-usage
    usage: puppy vpc create

    description:
        Create an AWS VPC.
usage

vpc_name=puppy

vpc_id=$(aws ec2 describe-vpcs --region=us-west-2 | \
    jq --arg vpc "$vpc_name" -r '
        .Vpcs[]
        | select(.Tags) | select(.Tags[] | .Key == "Name" and .Value == $vpc)
        | .VpcId')

#while read -r association; do
#    aws ec2 disassociate-route-table --association-id $association
#done < <(aws ec2 describe-route-tables | jq -r --arg vpc vpc-2a05914f '
#            .RouteTables[] | select(.VpcId == $vpc) | .Associations[] | .RouteTableAssociationId
#        ')

while read -r gateway; do
    aws ec2 detach-internet-gateway --internet-gateway-id $gateway --vpc-id $vpc_id
    aws ec2 delete-internet-gateway --internet-gateway-id $gateway
done < <(aws ec2 describe-internet-gateways | jq -r --arg vpc $vpc_id '
            .InternetGateways[] | select(.Attachments[] | .VpcId == $vpc) | .InternetGatewayId
        ')

while read -r subnet; do
    aws ec2 delete-subnet --subnet-id $subnet
done < <(aws ec2 describe-subnets | jq -r --arg vpc $vpc_id '
            .Subnets[] | select(.VpcId == $vpc) | .SubnetId
        ')



if [ -z "$vpc_id" ]; then
    abend "VPC \"$vpc_name\" does not exist." 2>&1
fi

aws ec2 delete-vpc --region=us-west-2 --vpc-id "$vpc_id"
