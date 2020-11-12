#!/bin/sh

createSslConfigFile() {
  rm -f ssl.config
  echo "[ req ]
  prompt = no
  distinguished_name = req_distinguished_name
  req_extensions     = req_ext

  [ req_distinguished_name ]
  countryName        = ES
  localityName       = BCN
  organizationName   = TEST
  commonName         = $1

  [ req_ext ]
  subjectAltName = @alt_names

  [alt_names]
  DNS.1	= localhost
  IP.1	= 127.0.0.1" >> ssl.config
}

# Only for Windows (workaround for GIT issue)
export MSYS_NO_PATHCONV=1

# Variables to be updated
CA_NAME="DevCA"

# Client certificate and Server Truststore password
TRUSTSTORE_PASSWORD="svn4ever"
# Server keystore password
KEYSTORE_PASSWORD="svn4ever"

# CN separator character
IFS=","
# Include all clients(comma separated), certificate will be created for each client
ALL_CLIENT_CN="server,client"

# Creating directory for storing certificates and keys
mkdir dev-certificates
cd dev-certificates || exit
mkdir -p CA
mkdir -p client

################## CA ##################
# Created CA Private Key
openssl ecparam -genkey -name prime256v1 -out CA/rootCA.key

# Create ssl.config file with provided CN
createSslConfigFile $CA_NAME

# Create CA Certificate
openssl req -new -x509 -days 3650 -key CA/rootCA.key -out CA/rootCA.crt -config ssl.config

# Generating P12 from crt and key (import in browser UI)
openssl pkcs12 -password pass:$KEYSTORE_PASSWORD -export -in CA/rootCA.crt -inkey CA/rootCA.key -out CA/root-ca.p12 -name $CA_NAME

# Create pem file from a p12 file
openssl pkcs12 -in CA/root-ca.p12 -out CA/root-ca.pem -nokeys -passin pass:$KEYSTORE_PASSWORD -passout pass:$KEYSTORE_PASSWORD

# Create truststore with CA certificate (common truststore for all services)
keytool -noprompt -keystore client/truststore.jks -importcert -file CA/root-ca.pem -alias root-ca -storepass $TRUSTSTORE_PASSWORD

echo "\e[1m CA Certificate and CA based truststore created \e[0m"

################## CLIENT ##################
for CLIENT_CN in $ALL_CLIENT_CN
do
	mkdir -p client/$CLIENT_CN

  # Create ssl.config file with provided CN
  createSslConfigFile "localhost"

	# Create the Client Private Key
	openssl ecparam -genkey -name prime256v1 -out client/$CLIENT_CN/client-$CLIENT_CN.key
	# Create the client certificate request with client role
	openssl req -new -key client/$CLIENT_CN/client-$CLIENT_CN.key -out client/$CLIENT_CN/client-$CLIENT_CN.csr -config ssl.config

	# Sign the client’s certificate using the CA private key file and public certificate
	openssl x509 -req -in client/$CLIENT_CN/client-$CLIENT_CN.csr -days 3650 -sha1 -CAcreateserial -CA CA/rootCA.crt -CAkey CA/rootCA.key -out client/$CLIENT_CN/client-$CLIENT_CN.crt -extensions req_ext -extfile ssl.config

	# Add certificate to client keystore P12 (can be used by browser, better to use CA P12 file)
	openssl pkcs12 -password pass:$KEYSTORE_PASSWORD -export -in client/$CLIENT_CN/client-$CLIENT_CN.crt -inkey client/$CLIENT_CN/client-$CLIENT_CN.key -out client/$CLIENT_CN/keystore.p12 -name $CLIENT_CN

	# Add all certificate (above keystore) to common keystore JKS (common keystore for all services)
	keytool -noprompt -importkeystore -deststorepass $KEYSTORE_PASSWORD -destkeypass $KEYSTORE_PASSWORD -destkeystore client/keystore.jks -srckeystore client/$CLIENT_CN/keystore.p12 -srcstoretype PKCS12 -srcstorepass $KEYSTORE_PASSWORD -alias $CLIENT_CN

	# This is not needed anymore
	rm client/$CLIENT_CN/keystore.p12
	echo "\e[1m Client certificate created and added to keystore for: [$CLIENT_CN] \e[0m"
done
rm -f ssl.config