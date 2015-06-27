#!/bin/bash

set -e

puppy module <<-usage
    usage: puppy vpc create

    description:
        Create an AWS VPC.
usage

dir=$(mktemp -d -t homeport_append.XXXXXXX)

trap cleanup EXIT SIGTERM SIGINT

function cleanup() {
    [ ! -z "$dir" ] && rm -rf "$dir"
}

aws elb delete-load-balancer \
    --load-balancer-name 'puppy-balancer'
