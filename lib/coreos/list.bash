#!/bin/bash

set -e

puppy module <<-usage
    usage: puppy vpc create

    description:
        Create an AWS VPC.
usage

puppy_instances="$puppy_configuration/$puppy_region/instances.json"

if [ ! -e "$puppy_instances" ]; then
    mkdir -p "${puppy_instances%/*}"
    aws ec2 describe-instances --region="$puppy_region" > "$puppy_instances"
fi

{
    echo -e "Name\tPublicIP\tPrivateIP\tInstanceId\tState"
    jq -r '
        .Reservations[].Instances[]
        | select(.Tags | length > 0)
        | select(.Tags[] | select(.Key == "Puppified" and .Value == "true"))
        | select(.State.Name == "running" or .State.Name == "pending")
        | [
            if .Tags then .Tags[]? | select(.Key == "Name") | .Value else "-" end,
            .PublicIpAddress,
            (.NetworkInterfaces[].PrivateIpAddresses[] | .PrivateIpAddress),
            .InstanceId,
            .State.Name
          ]
        | @tsv
    ' "$puppy_instances" | sort -k 1
} | column -t
