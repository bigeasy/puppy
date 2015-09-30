#!/bin/bash

set -e

puppy module <<-usage
    usage: puppy coreos id

    description:
        Create an AWS VPC.
usage

trap cleanup EXIT SIGTERM SIGINT

function cleanup() {
    local pids=$(jobs -pr)
    [ -n "$pids" ] && kill $pids
    [ ! -z "$dir" ] && rm -rf "$dir"
}

dir=$(mktemp -d -t puppy_coreos_key.XXXXXXX)

identifier=$1
shift
while read -r name public private id state; do
    for field in $number $name $public $private $id; do
        if [ "$field" = "$identifier" ]; then
            puppy_id=$id
            puppy_ip=$public
            break
        fi
    done
done < <(puppy_exec coreos list | tail -n +2)

declare -A fingerprints

while read -r type fingerprint; do
    type=ssh-${type,,}
    fingerprints[$type]=$fingerprint
done < <(aws ec2 get-console-output --region="$puppy_region" --instance-id="$puppy_id" | \
    jq -r '.Output' | tr -d '\r' | \
    grep '^SSH host key: [^ ]* ([^)]*)' | \
    sed 's/^SSH host key: \([^ ]*\) (\([^)]*\))/\2 \1/')

ssh-keyscan -t rsa,ecdsa,ed25519 $puppy_ip >"$dir/known_hosts" 2>/dev/null

declare -A validated

while read -r ip type fingerprint; do
    type="ssh-${type,,}"
    if [ "$ip" = "$puppy_ip" -a "${fingerprints[$type]}" = "$fingerprint" ]; then
        validated[$type]=1
    fi
done < <(ssh-keygen -l -f "$dir/known_hosts" | \
    sed 's/^[0-9]* \([^ ]*\) \([^ ]*\) (\([^)]*\))/\2 \3 \1/')

while read -r ip type key; do
    if [ "${validated[$type]}" = "1" ]; then
        echo $ip $type $key
    fi
done < "$dir/known_hosts"
