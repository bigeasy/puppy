#!/bin/bash

set -e

puppy module <<-usage
    usage: puppy vpc create

    description:
        Create an AWS VPC.
usage

dir=$(mktemp -d -t homeport_append.XXXXXXX)

trap cleanup EXIT SIGTERM SIGINT

function cleanup() {
    [ ! -z "$dir" ] && rm -rf "$dir"
}

declare argv
argv=$(getopt --options +c: --long count: -- "$@") || return
eval "set -- $argv"

instance_count=1

while true; do
    case "$1" in
        --count | -c)
            shift
            instance_count=$1
            shift
            ;;
        --)
            shift
            break
            ;;
    esac
done

if [ ! -e "$puppy_configuration/discovery" ]; then
    curl -s -w "\n" 'https://discovery.etcd.io/new?size=3' > "$puppy_configuration/discovery"
fi

if [ -e "$puppy_configuration/puppy.conf" ]; then
    source "$puppy_configuration/puppy.conf"
fi

if [ -z "$puppy_ssh_key" ]; then
    puppy_ssh_key=$(ssh-add -L | head -n 1 | awk 'NR = 1 { print $3 }')
fi

if [ -z "$puppy_ssh_key" ]; then
    abend "cannot find an ssh key to use."
fi

ssh_key=$(ssh-add -L | awk -v sought="$puppy_ssh_key" '
    function basename(file) {
        sub(".*/", "", file)
        return file
    }
    sought ~ /\// ? $3 == sought : $3 == basename(sought)  { print }
' | head -n 1)

mkdir -p "$dir/ssh"

umask 0077

cat <<EOF > "$dir/cloud-config"
#cloud-config

ssh_authorized_keys:
    - $ssh_key
EOF

cat "$dir/cloud-config"

alphabet=(able baker charlie dog easy fox george how item jig king love mike \
nan oboe peter queen roger sugar tare uncle victor william x-ray yoke zebra)

while read -r id name; do
    delete=($name)
    alphabet=(${alphabet[@]/$delete})
done < <(puppy_exec coreos list)

subnet_id=$(puppy_exec vpc subnet-id)

function tag_instance() {
    local instance=$1 count=$2
    errors=$(aws ec2 create-tags --resources $instance --tags Key=Name,Value=${alphabet[0]} 2>&1)
    if [[ "$errors" = *"The instance ID "*" does not exist" ]]; then
        if [ $count -eq 12 ]; then
            abend "cannot tag instance $instance"
        fi
        sleep 15
        tag_instance $instance $(( count + 1 ))
    else
        alphabet=("${alphabet[@]:1}")
    fi
}

mkdir -p "$puppy_configuration/keys"

while read -r instance; do
    tag_instance $instance 0
done < <(aws ec2 run-instances \
            --count $instance_count \
            --key-name puppy \
            --image-id ami-c5162ef5 \
            --subnet-id $subnet_id \
            --user-data file://"$dir/cloud-config" \
            --instance-type t2.micro | \
                jq -r '.Instances[] | .InstanceId')
