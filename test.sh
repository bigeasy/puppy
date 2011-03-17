#!/bin/bash

start=$1
if [ "$start"x == "x" ]; then
    start=0
fi

for test in $(ls 0*.sh | sort)
do
    value=$(echo $test | /usr/bin/sed 's/^0*\([1-9][0-9]*\)_.*$/\1/')
    if [ $value -gt $start ] || [ $value -eq $start ]; then
        ./$test
    fi
done
