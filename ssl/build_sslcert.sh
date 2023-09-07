#!/bin/bash
#--------------------------------------------------------------------------
# Program     : build_sslcert
# Version     : v1.0
# Description : Dirty script to create an SSL certificate.
# Syntax      : build_sslcert.sh
# Author      : Andrew (andrew@devnull.uk)
#--------------------------------------------------------------------------

#set -x
workdir=$PWD
fqdn=localhost

# Directory structure

function build_env()
{
	mkdir -p $PWD/certs/{server,ca,tmp}

	cat << EOF >> $PWD/certs/x509v3.ext
subjectAltName = @alt_names
[alt_names]
DNS.1 = localhost
DNS.2 = 127.0.0.1
EOF
}

function build_rca()
{
	# Create RCA
	openssl genrsa \
	  -out $PWD/certs/ca/rca.key 2048

	openssl req \
	  -x509 \
	  -new \
	  -nodes \
	  -key $PWD/certs/ca/rca.key \
	  -days 666 \
	  -out $PWD/certs/ca/rca.crt \
	  -subj "/C=US/ST=Nowhere/L=NYB/O=E-Corp/CN=${fqdn}"
}

function build_server()
{
	# Generate Server Key

	openssl genrsa \
	  -out $PWD/certs/server/server.key 2048

	# Generate CSR for RCA

	openssl req \
	  -new \
	  -key $PWD/certs/server/server.key \
	  -out $PWD/certs/tmp/server.csr \
	  -subj "/C=US/ST=Nowhere/L=NYB/O=E-Corp/CN=${fqdn}"

	# Sign the request from RCA

	openssl x509 \
	  -req -in $PWD/certs/tmp/server.csr \
	  -CA $PWD/certs/ca/rca.crt \
	  -CAkey $PWD/certs/ca/rca.key \
	  -CAcreateserial \
	  -out $PWD/certs/server/server.crt \
	  -extfile $PWD/certs/x509v3.ext \
	  -days 666
}

function cleanup()
{
	# Cleanup

	rm -rf $PWD/certs/tmp
	rm -rf $PWD/certs/x509v3.ext
	rm -rf $PWD/certs/ca
}

main() {
	build_env
	build_rca
	build_server
	cleanup
}

main "$@"
