#!/bin/bash

set -e

puppy module <<-usage
    usage: puppy coreos id

    description:
        Create an AWS VPC.
usage

instance=$1 key=$2
puppy_id=$(puppy_exec coreos id "$@")

aws ec2 describe-tags --region="$puppy_region" \
    --filters "Name=resource-id,Values=$puppy_id" | \
    jq --arg key "$key" -r '.Tags[] | select(.Key == $key) | .Value'
