#!/bin/bash

set -e

puppy module <<-usage
    usage: puppy hello
usage

trap cleanup EXIT SIGTERM SIGINT

function cleanup() {
    local pids=$(jobs -pr)
    [ -n "$pids" ] && kill $pids
}

echo "hello"
