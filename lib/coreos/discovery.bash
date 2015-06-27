#!/bin/bash

set -e

puppy module <<-usage
    usage: puppy coreos discovery

    description:
        Create an \`etcd\` discovery URL.
usage
