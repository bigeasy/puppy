#!/bin/bash

dirname=$(/usr/bin/dirname $0)
. $dirname/functions

count=$(puppy app:list | wc | awk '{ print $1 }')
assert '`app:list` is empty.' 1 $count
