#!/bin/bash

puppy module vpc <<-usage
    usage: puppy vpc create

    description:
        Create an AWS VPC.
usage

vpc_name=puppy

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
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-hostnames "{\"Value\":true}"

internet_gateway_id=$(aws ec2 create-internet-gateway | \
                      jq -r '.InternetGateway.InternetGatewayId')
aws ec2 create-tags \
    --region=us-west-2 --resources "$internet_gateway_id" \
    --tags 'Key=Name,Value='"$vpc_name gateway"

subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.0.0/28 | \
            jq -r '.Subnet.SubnetId')
aws ec2 create-tags \
    --region=us-west-2 --resources "$subnet_id" \
    --tags 'Key=Name,Value='"$vpc_name subnet"

route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id | \
                 jq -r '.RouteTable.RouteTableId')
aws ec2 attach-internet-gateway \
    --internet-gateway-id $internet_gateway_id \
    --vpc-id $vpc_id
aws ec2 associate-route-table \
    --route-table-id $route_table_id  \
    --subnet-id $subnet_id
aws ec2 create-route \
    --route-table-id $route_table_id \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $internet_gateway_id
