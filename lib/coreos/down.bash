#!/bin/bash

set -e

puppy module <<-usage
    usage: puppy coreos down

    description:
        Create an AWS VPC.
usage

listing=$(puppy_exec coreos list | tail -n +2)

declare -a instances

while [ $# -ne 0 ]; do
    identifier=$1
    shift
    while read -r number name public private id; do
        for field in $number $name $public $private $id; do
            if [ "$field" = "$identifier" ]; then
                instances+=($id)
                break
            fi
        done
    done < <(echo "$listing")
done

aws ec2 terminate-instances --instance-ids "${instances[@]}" | jq -r '
    .TerminatingInstances[] | .InstanceId
'
