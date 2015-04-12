#!/bin/bash

set -e

puppy module <<-usage
    usage: puppy vpc create

    description:
        Create an AWS VPC.
usage

declare argv
argv=$(getopt --options +c: --long count: -- "$@") || return
eval "set -- $argv"

instance_count=1

while true; do
    case "$1" in
        --count | -c)
            shift
            instance_count=$1
            shift
            ;;
        --)
            shift
            break
            ;;
    esac
done

alphabet=(Able Baker Charlie Dog Easy Fox George How Item Jig King Love Mike \
Nan Oboe Peter Queen Roger Sugar Tare uncle Victor William X-ray Yoke Zebra)

while read -r id name; do
    delete=($name)
    alphabet=(${alphabet[@]/$delete})
done < <(puppy_exec coreos list)

subnet_id=$(puppy_exec vpc subnet-id)

while read -r instance; do
    aws ec2 create-tags --resources $instance --tags Key=Name,Value=${alphabet[0]}
    alphabet=("${alphabet[@]:1}")
done < <(aws ec2 run-instances \
            --count $instance_count \
            --image-id ami-c5162ef5 \
            --subnet-id $subnet_id \
            --instance-type t2.micro | \
                jq -r '.Instances[] | .InstanceId')
