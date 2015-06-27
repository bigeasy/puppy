#!/bin/bash

set -e

puppy module <<-usage
    usage: puppy ca create

    description:
        Create the Puppy CA.
usage

directory="$puppy_configuration/ca"

if [ -d "$directory" ]; then
    abend "certificate authority already exists"
fi

mkdir -p "$directory"

#output_password        = password
read -r -d '' config <<'EOF' && true
[ req ]
default_bits           = 2048
days                   = 365
distinguished_name     = req_distinguished_name
prompt                 = no

[ req_distinguished_name ]
C                      = US
ST                     = LA
L                      = New Orleans
O                      = Puppy
OU                     = Puppy Certificate Authority
CN                     = bigeasy.github.io
emailAddress           = info@dev.null
EOF

echo openssl req -new -x509 -days 365 -config <(echo "$config") \
    -keyout "$directory/ca-key.pem" -out "$directory/ca-cert.pem"
openssl req -nodes -new -x509 -days 365 -config <(echo "$config") \
    -keyout "$directory/ca-key.pem" -out "$directory/ca-cert.pem"
exit
openssl req -new -x509 -days 365 -config <(echo "$config") \
    -keyout "$directory/$serial-key.pem" -out "$directory/$serial-cert.pem"
