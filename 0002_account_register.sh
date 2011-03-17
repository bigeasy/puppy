#!/bin/bash

dirname=$(/usr/bin/dirname $0)
. $dirname/functions

puppy account:register client@prettyrobots.com ~/.ssh/identity.pub
assert "Register account." 0 $?
