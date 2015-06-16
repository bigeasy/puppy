#!/bin/bash

set -e

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
    --tags 'Key=Name,Value='"$vpc_name gateway" > /dev/null

subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.0.0/28 | \
            jq -r '.Subnet.SubnetId')
aws ec2 create-tags \
    --region=us-west-2 --resources "$subnet_id" \
    --tags 'Key=Name,Value='"$vpc_name subnet" > /dev/null
aws ec2 modify-subnet-attribute --subnet-id $subnet_id --map-public-ip-on-launch > /dev/null

route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id | \
                 jq -r '.RouteTable.RouteTableId')
aws ec2 create-tags \
    --region=us-west-2 --resources "$route_table_id" \
    --tags 'Key=Name,Value='"$vpc_name outbound route table" > /dev/null

aws ec2 attach-internet-gateway \
    --internet-gateway-id $internet_gateway_id \
    --vpc-id $vpc_id > /dev/null
aws ec2 associate-route-table \
    --route-table-id $route_table_id  \
    --subnet-id $subnet_id > /dev/null
aws ec2 create-route \
    --route-table-id $route_table_id \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $internet_gateway_id > /dev/null

security_group_id=$(aws ec2 describe-security-groups | jq -r --arg vpc $vpc_id '.SecurityGroups[] | select(.VpcId == $vpc) | select(.GroupName == "default") | .GroupId')
aws ec2 create-tags \
    --region=us-west-2 --resources $security_group_id \
    --tags 'Key=Name,Value='"$vpc_name security group" > /dev/null

aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port 22 --cidr 0.0.0.0/0 > /dev/null
