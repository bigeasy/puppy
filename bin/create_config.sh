#!/bin/bash

if [ $(whoami) != "root" ]; then
    echo "Must run as root." 1>&2
    exit 1
fi

name=$1
address=$2
if [ -z $name ] || [ -z $address ]
then
    echo "usage: create_host.sh <machine_name> <ip_address>" 1>&2
    exit 1
fi


/bin/mkdir -p /config/$name.runpup.com/etc/ssh

KEYGEN=/usr/bin/ssh-keygen
RSA_KEY=/config/$name.runpup.com/etc/ssh/ssh_host_rsa_key
if [ ! -s $RSA_KEY ]; then
    rm -f $RSA_KEY
    if test ! -f $RSA_KEY && $KEYGEN -q -t rsa -f $RSA_KEY -C '' -N '' >&/dev/null; then
        chmod 600 $RSA_KEY
        chmod 644 $RSA_KEY.pub
        if [ -x /sbin/restorecon ]; then
            /sbin/restorecon $RSA_KEY.pub
        fi
        echo
    else
        echo
        exit 1
    fi
fi

function append_unless()
{
    local line=$1
    grep "$line" /home/alan/dns/runpup.com.zone 
    if [ $? -ne 0 ]
    then
        echo "$line"
        echo "$line" >> /home/alan/dns/runpup.com.zone
    fi
}

mkdir -p /config/$name.runpup.com/etc/sysconfig
cat <<HERE > /config/$name.runpup.com/etc/sysconfig/network
NETWORKING=yes
NETWORKING_IPV6=no
HOSTNAME=$name.runpup.com
HERE

append_unless "$(ssh-keygen -r $name -f $RSA_KEY)"
append_unless "$name             IN      A       $address"

chown -R janitor:janitor /config
