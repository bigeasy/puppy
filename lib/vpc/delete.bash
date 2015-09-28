#!/bin/bash

set -e

puppy module vpc <<-usage
    usage: puppy vpc create

    description:
        Create an AWS VPC.
usage

vpc_name="$puppy_tag"

vpc_id=$(aws ec2 describe-vpcs --region="$puppy_region" | \
    jq --arg vpc "$vpc_name" -r '
        .Vpcs[]
        | select(.Tags) | select(.Tags[] | .Key == "Name" and .Value == $vpc)
        | .VpcId')

if [ -z "$vpc_id" ]; then
    abend "VPC \"$vpc_name\" does not exist." 2>&1
fi

while read -r gateway; do
    echo internet_gateway $gateway
    aws ec2 detach-internet-gateway --region="$puppy_region" --internet-gateway-id $gateway --vpc-id $vpc_id
    aws ec2 delete-internet-gateway --region="$puppy_region" --internet-gateway-id $gateway
done < <(aws ec2 describe-internet-gateways --region="$puppy_region" \
    | jq -r --arg vpc $vpc_id '
        .InternetGateways[] | select(.Attachments[] | .VpcId == $vpc) | .InternetGatewayId
    ')

while read -r subnet; do
    echo subnet $subnet
    aws ec2 delete-subnet --region="$puppy_region" --subnet-id $subnet
done < <(aws ec2 describe-subnets --region="$puppy_region" \
    | jq -r --arg vpc $vpc_id '
        .Subnets[] | select(.VpcId == $vpc) | .SubnetId
    ')

while read -r association; do
    aws ec2 disassociate-route-table --region="$puppy_region" --association-id $association
done < <(aws ec2 describe-route-tables --region="$puppy_region" \
    | jq -r --arg vpc $vpc_id '
        .RouteTables[] | select(.VpcId == $vpc) | .Associations[] | select(.Main != true) | .RouteTableAssociationId
    ')

while read -r table; do
    echo route_table $table
    aws ec2 delete-route-table --region="$puppy_region" --route-table-id $table
done < <(aws ec2 describe-route-tables --region="$puppy_region" \
    | jq -r --arg vpc $vpc_id '
        .RouteTables[] | select(.VpcId == $vpc) | select(.Associations | length == 0) | .RouteTableId
    ')

while read -r group; do
    echo security_group $group
    aws ec2 delete-security-group --region="$puppy_region" --group-id $group
done < <(aws ec2 describe-security-groups --region="$puppy_region" \
    | jq -r --arg vpc $vpc_id '.SecurityGroups[] | select(.VpcId == $vpc) | select(.GroupName != "default") .GroupId')

echo vpc $vpc_id
aws ec2 delete-vpc --region="$puppy_region" --vpc-id "$vpc_id"
