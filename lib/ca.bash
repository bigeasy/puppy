#!/bin/bash

puppy module <<-usage
    usage: puppy ca <command>

    description:
        Manage a Certificate Authority for use with Puppy.
usage

[ $# -eq 0 ] && usage

puppy_perpetuate "$@"
