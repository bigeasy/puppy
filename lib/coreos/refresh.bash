#!/bin/bash

set -e

puppy module <<-usage
    usage: puppy vpc create

    description:
        Create an AWS VPC.
usage

puppy_instances="$puppy_configuration/$puppy_region/instances.json"

rm -f "$puppy_instances"
