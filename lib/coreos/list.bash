#!/bin/bash

set -e

puppy module <<-usage
    usage: puppy vpc create

    description:
        Create an AWS VPC.
usage

{
    echo -e "#\tName\tPublicIP"$"\t""PrivateIP"$"\t""InstanceId"
    aws ec2 describe-instances | \
        jq -r '
            .Reservations[].Instances[]
            | select(.ImageId == "ami-c5162ef5")
            | select(.State.Name == "running" or .State.Name == "pending")
            | { PublicIpAddress,
                InstanceId,
                PrivateIpAddress: .NetworkInterfaces[].PrivateIpAddresses[] | .PrivateIpAddress,
                Name: .Tags[] | select(.Key == "Name") | .Value }
            | [.PublicIpAddress,.InstanceId,.PrivateIpAddress,.Name]
            | @tsv
        ' | \
        awk '{ print $1 "." $2 "\t" $3 "\t" $4 }' | \
        sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 | \
        sed 's/\.i/\ti/' | \
        awk '{ print NR "\t" $4 "\t" $1 "\t" $3 "\t" $2 }'
} | column -t
           # .Tags[] | select(.Key == "Name") | .Value]
