#!/bin/bash

puppy module coreos <<-usage
    usage: puppy instance <command>

    description:
        Create or destroy AWS instances.
usage

[ $# -eq 0 ] && usage

puppy_perpetuate "$@"
