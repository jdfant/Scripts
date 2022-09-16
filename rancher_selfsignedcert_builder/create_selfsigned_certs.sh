#!/bin/bash

# Based on https://jamielinux.com/docs/openssl-certificate-authority

ROOT_CA="/home/jd/GIT/rancher_selfsignedcert_builder/ROOT_CA"
DOMAIN="rancher.home.lan"

# Root pair
echo -e "\nSetting up directory structure\n"
mkdir -p "$ROOT_CA"/{certs,crl,newcerts,private,intermediate/{certs,crl,csr,newcerts,private}}/
cp ./root_ca_openssl.cnf "$ROOT_CA"/openssl.cnf
cp ./intermediate_openssl.cnf "$ROOT_CA"/intermediate/openssl.cnf
chmod 700 "$ROOT_CA"/private
chmod 700 "$ROOT_CA"/intermediate/private
touch "$ROOT_CA"/index.txt
echo 1000 > "$ROOT_CA"/serial

# Generate Root CA
echo -e "\nGenerating Root CA\n"
openssl genrsa -aes256 -out "$ROOT_CA"/private/ca.key.pem 4096
chmod 400 "$ROOT_CA"/private/ca.key.pem

openssl req -config "$ROOT_CA"/openssl.cnf \
      -key "$ROOT_CA"/private/ca.key.pem \
      -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -out "$ROOT_CA"/certs/ca.cert.pem

chmod 444 "$ROOT_CA"/certs/ca.cert.pem

# Generate Intermediate keys & certs
echo -e "\Generating Intermediate keys & certs\n"
touch "$ROOT_CA"/intermediate/index.txt
echo 1000 > "$ROOT_CA"/intermediate/serial
echo 1000 > "$ROOT_CA"/intermediate/crlnumber

openssl genrsa -aes256 \
      -out "$ROOT_CA"/intermediate/private/intermediate.key.pem 4096
chmod 400 "$ROOT_CA"/intermediate/private/intermediate.key.pem

openssl req -config "$ROOT_CA"/intermediate/openssl.cnf -new -sha256 \
      -key "$ROOT_CA"/intermediate/private/intermediate.key.pem \
      -out "$ROOT_CA"/intermediate/csr/intermediate.csr.pem

openssl ca -config "$ROOT_CA"/openssl.cnf -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 \
      -in "$ROOT_CA"/intermediate/csr/intermediate.csr.pem \
      -out "$ROOT_CA"/intermediate/certs/intermediate.cert.pem

chmod 444 "$ROOT_CA"/intermediate/certs/intermediate.cert.pem

cat "$ROOT_CA"/intermediate/certs/intermediate.cert.pem \
      "$ROOT_CA"/certs/ca.cert.pem > "$ROOT_CA"/intermediate/certs/ca-chain.cert.pem
chmod 444 "$ROOT_CA"/intermediate/certs/ca-chain.cert.pem

openssl genrsa -aes256 \
      -out "$ROOT_CA"/intermediate/private/$DOMAIN.key.pem 2048
chmod 400 "$ROOT_CA"/intermediate/private/$DOMAIN.key.pem

openssl req -config "$ROOT_CA"/intermediate/openssl.cnf \
      -key "$ROOT_CA"/intermediate/private/$DOMAIN.key.pem \
      -new -sha256 -out "$ROOT_CA"/intermediate/csr/$DOMAIN.csr.pem

openssl ca -config "$ROOT_CA"/intermediate/openssl.cnf \
      -extensions server_cert -days 375 -notext -md sha256 \
      -in "$ROOT_CA"/intermediate/csr/$DOMAIN.csr.pem \
      -out "$ROOT_CA"/intermediate/certs/$DOMAIN.cert.pem
chmod 444 "$ROOT_CA"/intermediate/certs/$DOMAIN.cert.pem

# Organize certs for Rancher
echo -e "\nRancherizing Certs :)\n"
mkdir -p "$ROOT_CA"/rancher/base64
cp "$ROOT_CA"/certs/ca.cert.pem "$ROOT_CA"/rancher/cacerts.pem
cat "$ROOT_CA"/intermediate/certs/$DOMAIN.cert.pem "$ROOT_CA"/intermediate/certs/intermediate.cert.pem > "$ROOT_CA"/rancher/cert.pem

# Removing passphrase from Rancher certificate key
echo -e "\nRemoving passphrase from Rancher certificate key\n"
openssl rsa -in "$ROOT_CA"/intermediate/private/$DOMAIN.key.pem -out "$ROOT_CA"/rancher/key.pem
< "$ROOT_CA"/rancher/cacerts.pem base64 -w0 > "$ROOT_CA"/rancher/base64/cacerts.base64
< "$ROOT_CA"/rancher/cert.pem base64 -w0 > "$ROOT_CA"/rancher/base64/cert.base64
< "$ROOT_CA"/rancher/key.pem base64 -w0 > "$ROOT_CA"/rancher/base64/key.base64

# Verify certificates
echo -e "\nVerify certificates\n"
openssl verify -CAfile "$ROOT_CA"/certs/ca.cert.pem \
      "$ROOT_CA"/intermediate/certs/intermediate.cert.pem
openssl verify -CAfile "$ROOT_CA"/intermediate/certs/ca-chain.cert.pem \
      "$ROOT_CA"/intermediate/certs/$DOMAIN.cert.pem
