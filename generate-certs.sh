#!/bin/bash
# Generate certificates for your Bitwarden configuration

CERTS_DN="${CERTS_DN:-/C=FR/ST=IDF/L=PARIS/O=EXAMPLE}"   # Edit here and in opensearch.yml

# Root CA
openssl genrsa -out ssl/ca.key 2048
openssl req -new -x509 -sha256 -days 1095 -subj "$CERTS_DN/CN=CA" -key ssl/ca.key -out ./ssl/ca.crt

# Bitwarden certs
openssl genrsa -out ./ssl/bitwarden-temp.key 2048
openssl pkcs8 -inform PEM -outform PEM -in ./ssl/bitwarden-temp.key -topk8 -nocrypt -v1 PBE-SHA1-3DES -out ./ssl/bitwarden.key
openssl req -new -subj "$CERTS_DN/CN=bitwarden" -key ./ssl/bitwarden.key -out ./ssl/bitwarden.csr
openssl x509 -req -in ./ssl/bitwarden.csr -CA ./ssl/ca.crt -CAkey ssl/ca.key -CAcreateserial -sha256 -out ./ssl/bitwarden.crt
rm ./ssl/bitwarden-temp.key ./ssl/bitwarden.csr

openssl pkcs12 -export -out ./identity/identity.pfx -inkey ./ssl/bitwarden.key -in ./ssl/ca.crt -in ./ssl/bitwarden.crt -password pass:IDENTITY_CERT_PASSWORD
