#!/bin/bash

set -e

puppy module <<-usage
    usage: puppy vpc create

    description:
        Create an AWS VPC.
usage

{
    echo -e "Name\tPublicIP\tPrivateIP\tInstanceId\tState"
    aws ec2 describe-instances | \
        jq -r '
            .Reservations[].Instances[]
            | select(.ImageId == "ami-c5162ef5")
            | select(.State.Name == "running" or .State.Name == "pending")
            | [
                if .Tags then .Tags[]? | select(.Key == "Name") | .Value else "-" end,
                .PublicIpAddress,
                (.NetworkInterfaces[].PrivateIpAddresses[] | .PrivateIpAddress),
                .InstanceId,
                .State.Name
              ]
            | @tsv
        ' | \
        sort -k 1
} | column -t
           # .Tags[] | select(.Key == "Name") | .Value]
