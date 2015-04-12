#!/bin/bash

vpc_id=$(puppy_exec vpc id)

[ -z "$vpc_id" ] && exit 1

aws ec2 describe-subnets | jq -r --arg vpc $vpc_id '.Subnets[] | select(.VpcId == $vpc) | .SubnetId'
