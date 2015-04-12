#!/bin/bash

set -e

puppy module vpc <<-usage
    usage: puppy vpc create

    description:
        Create an AWS VPC.
usage

echo -e "#\t""PublicIP"$"\t""PrivateIP"$"\t""InstanceId"
aws ec2 describe-instances | \
    jq -r '
        .Reservations[].Instances[]
        | select(.ImageId == "ami-c5162ef5")
        | select(.State.Name == "running")
        | [.PublicIpAddress,.InstanceId,.NetworkInterfaces[0].PrivateIpAddresses[0].PrivateIpAddress]
        | @tsv
    ' | \
    awk '{ print $1"."$2"\t"$3 }' | \
    sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 | \
    sed 's/\.i/\ti/' | \
    awk '{ print NR "\t" $1 "\t" $3 "\t" $2 }'
