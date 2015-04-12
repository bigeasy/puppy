#!/bin/bash

puppy module coreos <<-usage
    usage: puppy coreos <command>

    description:
        Create or destroy CoreOS instances.
usage

[ $# -eq 0 ] && usage

puppy_perpetuate "$@"
