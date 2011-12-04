#!/bin/bash

hostname=$(curl -s http://169.254.169.254/latest/user-data)
[ -z $hostname ] && exit 1

/usr/bin/s3cmd -c /root/.s3cfg --skip-existing get s3://runpup/system/config.img /root/

device=$(/bin/mount | awk '$3 == "/mnt/config" { print $1 }')
if [ -z "$device" ]
then
    /sbin/losetup --show /dev/loop7 /root/config.img 2>&1 > /dev/null
    if [ $? -ne 0 ]
    then
        /sbin/losetup /dev/loop7 /root/config.img
    fi
    /bin/mkdir -p /mnt/config
    /bin/mount /dev/loop7 /mnt/config
fi

/usr/bin/rsync -av "/mnt/config/var/common/" "/"
/usr/bin/rsync -av "/mnt/config/var/$hostname/" "/"

/bin/hostname $hostname
/etc/init.d/motd start

service sshd restart > /dev/null
