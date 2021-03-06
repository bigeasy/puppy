#!/bin/bash

puppy module <<-usage
    usage: puppy coreos ssh

    description:
        Create an AWS VPC.
usage

listing=$(puppy_exec coreos list | tail -n +2)

declare -a instances

[ $# -ne 1 ] && usage

identifier=$1
while read -r name public private id state; do
    for field in $number $name $public $private $id; do
        if [ "$field" = "$identifier" ]; then
            instance=$id
            ip=$public
            break
        fi
    done
done < <(echo "$listing")

[ -z "ip" ] && abend "cannot find: $instance"

knownfile="$puppy_configuration/known_hosts/$instance"
if [ ! -e "$knownfile" ]; then
    mkdir -p $(dirname "$knownfile")
    console=$(aws ec2 get-console-output --region="$puppy_region" --instance-id $instance | \
        jq -r '.Output' | \
        awk '/^SSH host key/ && /RSA/ { print $4 }')
    ssh-keyscan "$ip" 2> /dev/null > "$knownfile.tmp"
    file=$(ssh-keygen -lf "$knownfile.tmp" | cut -d' ' -f2)
    if [ "$console" = "$file" ]; then
        mv "$knownfile.tmp" "$knownfile"
    else
        abend "cannot find keys (yet)"
    fi
fi

ssh -o UserKnownHostsFile="$puppy_configuration/known_hosts/$instance" \
    -o HostKeyAlgorithms=ssh-rsa-cert-v01@openssh.com,ssh-dss-cert-v01@openssh.com,ssh-rsa-cert-v00@openssh.com,ssh-dss-cert-v00@openssh.com,ssh-rsa,ssh-dss \
    -l core "$ip"
