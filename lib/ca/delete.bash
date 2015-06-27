#!/bin/bash

set -e

puppy module <<-usage
    usage: puppy ca deletel

    description:
        Delete the Puppy CA.
usage

directory="$puppy_configuration/ca"

rm -rf "$directory"
