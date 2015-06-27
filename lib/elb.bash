#!/bin/bash

puppy module <<-usage
    usage: puppy elb <command>

    description:
        Create or destroy an AWS ELB for use with Puppy.
usage

[ $# -eq 0 ] && usage

puppy_perpetuate "$@"
