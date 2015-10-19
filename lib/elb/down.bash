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

aws elb delete-security-group \
    --region="$puppy_region" \
    --group-id="$(puppy_exec elb group)"

aws elb delete-load-balancer \
    --region="$puppy_region" \
    --load-balancer-name="$puppy_tag-balancer"
