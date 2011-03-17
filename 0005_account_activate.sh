#!/bin/bash

dirname=$(/usr/bin/dirname $0)
. $dirname/functions

count=0
ret=1
while [ $ret -ne 0 ]; do
    sleep 1
    count=$(($count + 1))
    if [ $count -eq 60 ]; then
        assert "Email received within 60 seconds." 0 1
    fi
    code=$($dirname/imap.rb)
    ret=$?
done

out=$(puppy account:activate $code)
assert "Activate account." 0 $?

count=0
ret=1
while [ $ret -ne 0 ]; do
    sleep 1
    count=$(($count + 1))
    if [ $count -eq 60 ]; then
        assert "Account ready within 60 seconds." 0 1
    fi
    puppy account:ready
    ret=$?
done

puppy account:ready
assert "Account ready." 0 $?
