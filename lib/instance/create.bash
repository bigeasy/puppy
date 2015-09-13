#!/bin/bash

set -e

puppy module <<-usage
    usage: puppy instance create

    options:
        --image, -i <string>
            AMI of AWS image, defaults to most recent Ubuntu LTS.

        --type, -t <string>
            Intance type, defaults to "t2.micro".

        --count, -c <count>
            Number of instances to start, defaults to 1.

        --user, -u <string>
            The user name of the default user or $USER by default.

        --key, -k <string>
            Path to the public SSH key for the default user, or else a name of a
            key listed in \`ssh-add -L\`.

        --help, -h
            Display this message.

    description:
        Create an Ubuntu instance.
usage

dir=$(mktemp -d -t puppy.XXXXXXX)

trap cleanup EXIT SIGTERM SIGINT

function cleanup() {
    [ ! -z "$dir" ] && rm -rf "$dir"
}

declare argv
argv=$(getopt --options +c:i:t:u:k:h --long count:,image:,type:,user:,key:,help -- "$@") || return
eval "set -- $argv"

instance_count=1
instance_image=ami-5189a661
instance_type=t2.micro
instance_user="$USER"

while true; do
    case "$1" in
        --user | -u)
            shift
            instance_user=$1
            shift
            ;;
        --key | -k)
            shift
            instance_key=$1
            shift
            ;;
        --count | -c)
            shift
            instance_count=$1
            shift
            ;;
        --image | -i)
            shift
            instance_image=$1
            shift
            ;;
        --type | -t)
            shift
            instance_type=$1
            shift
            ;;
        --)
            shift
            break
            ;;
    esac
done

if [ -e "$puppy_configuration/puppy.conf" ]; then
    source "$puppy_configuration/puppy.conf"
fi

key_missing() {
    echo 'error: specify a key file or choose a key from your ssh-agent' 1>&2
    local keys=$(ssh-add -L | awk 'NR = 1 { print $3 }')
    if [ -z "$keys" ]; then
        echo '  your ssh-agent has no keys'
    else
        echo '  ssh-agent keys:' 1>&2
        { ssh-add -l | sed 's/^/    /g'; } 1>&2
    fi
    exit 1
}

if [ -z "$instance_key" ]; then
    key_missing
fi

instance_key_number=$(ssh-add -l | awk -v sought="$instance_key" '
    function basename(file) {
        sub(".*/", "", file)
        return file
    }
    sought ~ /\// ? $3 == sought : sought ~ /:/ ? $2 == sought : basename($3) == sought  { print NR }
')

instance_public_key=$(ssh-add -L | awk -v sought="$instance_key_number" '
    FNR == sought { print $1 " " $2 }
')

mkdir -p "$dir/ssh"

umask 0077

cat <<EOF > "$dir/cloud-config"
#cloud-config

system_info:
  default_user:
    name: $USER

ssh_authorized_keys:
    - $instance_public_key
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
        aws ec2 create-tags --resources $instance --tags Key=Puppified,Value=true 2>&1
        alphabet=("${alphabet[@]:1}")
    fi
}

mkdir -p "$puppy_configuration/keys"

while read -r instance; do
    tag_instance $instance 0
done < <(aws ec2 run-instances \
            --count $instance_count \
            --key-name puppy \
            --image-id "$instance_image" \
            --subnet-id $subnet_id \
            --user-data file://"$dir/cloud-config" \
            --instance-type "$instance_type" | \
                jq -r '.Instances[] | .InstanceId')
