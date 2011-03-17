#!/bin/bash

dirname=$(/usr/bin/dirname $0)
. $dirname/functions

# Test `puppy account:register` validation.
out=$(puppy account:register)
assert '`puppy account:register` with no parameters.' 1 $?
message=$(error_message "$out")
assert '`puppy account:register` no parameters message.' 'Required parameters missing. See usage.' "$message"
out=$(puppy account:register alan@prettyrobots.com)
assert '`puppy account:register` with one parameter.' 1 $?
message=$(error_message "$out")
assert '`puppy account:register` one parameter message.' 'Required parameters missing. See usage.' "$message"
out=$(puppy account:register alan ~/.ssh/identity.pub)
assert '`puppy account:register` with bad email.' 1 $?
message=$(error_message "$out")
assert '`puppy account:register` invalid email message.' 'Invalid email address.' "$message"
