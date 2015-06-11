#!/bin/bash

puppy module vpc <<-usage
    usage: puppy vpc <command>

    description:
        Create or destroy an AWS VPC for use with Puppy.
usage

[ $# -eq 0 ] && usage

puppy_perpetuate "$@"
