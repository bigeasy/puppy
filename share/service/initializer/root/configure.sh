#!/bin/bash

hostname=$(curl -s http://169.254.169.254/latest/user-data)
[ -z $hostname ] && exit 0

/usr/bin/s3cmd -c /root/.s3cfg --skip-existing get s3://puppy.io/system/config.img /root/

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

type=$(echo $hostname | /bin/sed 's/[^.]\+\.\([^.]\+\).*/\1/')

/usr/bin/rsync -av "/mnt/config/var/common/" "/"
/usr/bin/rsync -av "/mnt/config/var/$(/bin/uname -m)/" "/"
/usr/bin/rsync -av "/mnt/config/var/$type/" "/"
/usr/bin/rsync -av "/mnt/config/var/$hostname/" "/"

/bin/hostname $hostname
/etc/init.d/motd start

for name in common $(/bin/uname -m) $type host
do
  if [ -x "/root/bootstrap/$name" ]
  then
    "/root/bootstrap/$name"
  fi
done

service sshd restart > /dev/null
