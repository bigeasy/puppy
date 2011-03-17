#!/bin/bash

dirname=$(/usr/bin/dirname $0)
. $dirname/functions

# Test `puppy account:register` duplicate registration.
out=$(puppy account:register client@prettyrobots.com ~/.ssh/identity.pub)
assert "Register duplicate." "The email address client@prettyrobots.com is already registered." "$out"
