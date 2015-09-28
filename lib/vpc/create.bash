#!/bin/bash

set -e

puppy module vpc <<-usage
    usage: puppy vpc create

    description:
        Create an AWS VPC.
usage

vpc_name="$puppy_tag"

exists=$(aws ec2 describe-vpcs --region="$puppy_region" | \
    jq --arg vpc "$vpc_name" -r '
        .Vpcs[]
        | select(.Tags) | select(.Tags[] | .Key == "Name" and .Value == $vpc)
        | .VpcId')

if [ ! -z "$exists" ]; then
    abend "VPC \"$vpc_name\" already exists." 2>&1
fi

aws_create_tag() {
    resource_id=$1 key=$2 value=$3
    aws ec2 create-tags --region="$puppy_region" --resources "$resource_id" \
        --tags "Key=$key,Value=\"$value\"" > /dev/null
}

vpc_id=$(aws ec2 create-vpc --region="$puppy_region" --cidr-block 10.0.0.0/24 | jq -r '.Vpc.VpcId')
echo vpc $vpc_id

aws_create_tag "$vpc_id" "Name" "$vpc_name"
aws_create_tag "$vpc_id" "Puppfied" "true"
aws ec2 modify-vpc-attribute --region="$puppy_region" \
    --vpc-id $vpc_id --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --region="$puppy_region" \
    --vpc-id $vpc_id --enable-dns-hostnames "{\"Value\":true}"

internet_gateway_id=$(aws ec2 create-internet-gateway --region="$puppy_region" \
    | jq -r '.InternetGateway.InternetGatewayId')
aws ec2 create-tags \
    --region="$puppy_region" --resources "$internet_gateway_id" \
    --tags 'Key=Name,Value='"$vpc_name gateway" > /dev/null
echo internet_gateway $internet_gateway

subnet_id=$(aws ec2 create-subnet --region="$puppy_region" \
    --vpc-id $vpc_id --cidr-block 10.0.0.0/24 | jq -r '.Subnet.SubnetId')
aws ec2 create-tags --region="$puppy_region" \
    --resources "$subnet_id" --tags 'Key=Name,Value='"$vpc_name subnet" > /dev/null
aws ec2 modify-subnet-attribute --region="$puppy_region" \
    --subnet-id $subnet_id --map-public-ip-on-launch > /dev/null
echo subnet $subnet_id

route_table_id=$(aws ec2 create-route-table --region="$puppy_region" \
    --vpc-id $vpc_id | jq -r '.RouteTable.RouteTableId')
aws ec2 create-tags --region="$puppy_region" \
    --resources "$route_table_id" --tags 'Key=Name,Value='"$vpc_name outbound route table" > /dev/null
echo route_table $route_table_id

aws ec2 attach-internet-gateway --region="$puppy_region" \
    --internet-gateway-id $internet_gateway_id \
    --vpc-id $vpc_id > /dev/null
aws ec2 associate-route-table --region="$puppy_region" \
    --route-table-id $route_table_id  \
    --subnet-id $subnet_id > /dev/null
aws ec2 create-route --region="$puppy_region" \
    --route-table-id $route_table_id \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $internet_gateway_id > /dev/null

security_group_id=$(aws ec2 describe-security-groups --region="$puppy_region" \
    | jq -r --arg vpc $vpc_id '.SecurityGroups[] | select(.VpcId == $vpc) | select(.GroupName == "default") | .GroupId')
aws ec2 create-tags --region="$puppy_region" \
    --region="$puppy_region" --resources $security_group_id \
    --tags 'Key=Name,Value='"$vpc_name security group" > /dev/null
echo security_group $security_group_id

aws ec2 authorize-security-group-ingress --region="$puppy_region" \
    --group-id $security_group_id --protocol tcp --port 22 --cidr 0.0.0.0/0 > /dev/null
