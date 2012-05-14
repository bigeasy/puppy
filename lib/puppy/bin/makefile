#!/bin/bash -e

puppify module <<-usage
  usage: puppify makefile
usage

echo 'VPATH=lib/puppy/bin:share/service' > Makefile

previous=""
for service in ntp sudoers rsyslog backup unbound initializer postfix sshd shorewall stunnel haproxy
do
  echo "" >> Makefile
  target="made/$service:$previous install-$service"
  if [ -e share/service/$service ]; then
    for file in $(cd share/service && find $service ! -type d); do
      target+=" $file"
    done
  fi
  echo "$target" >> Makefile
  echo -e "\tbin/puppify install $service" >> Makefile
  echo -e "\ttouch \$@" >> Makefile
  previous=" made/$service"
done

echo "" >> Makefile
echo "all: made/$service" >> Makefile
