#!/bin/bash
# --------------------------------
# Set some error-handling options
# -e:          script is killed on error
# -u:          script is killed on unset variables
# -o pipefail: script is killed on pipefail 
# --------------------------------
# --------------------------------
# This script will:
# 
# Create Root CA
# Create Intermediate CA
# Create a handful of certificates 
# --------------------------------
set -euo pipefail;
ROOT_DIRECTORY="myscript_tmp/root";
ROOT_KEY="$ROOT_DIRECTORY/private/ca.key.pem";
ROOT_CERT="$ROOT_DIRECTORY/certs/ca.cert.pem";

function createDirs {
    echo "----------";
    echo "createDirs";
    echo "----------";
    mkdir -p $ROOT_DIRECTORY;
    mkdir -p $ROOT_DIRECTORY/{certs,crl,newcerts,private}
    # Change permissions on private subfolder
    chmod 700 $ROOT_DIRECTORY/private;
    # Create empty index.txt
    touch $ROOT_DIRECTORY/index.txt;
    # Create a file called 'serial' with '1000' as contents
    echo 1000 > $ROOT_DIRECTORY/serial;
}

function getConfig {
    echo "----------";
    echo "getConfig";
    echo "----------";
    URL="https://jamielinux.com/docs/openssl-certificate-authority/_downloads/root-config.txt";
    curl $URL -o root-config.txt;
    cp root-config.txt root-config2.txt;
    mv root-config.txt $ROOT_DIRECTORY/openssl.cnf;
    MYDIR="\/home\/ryannapp\/HW2\/myscript_tmp\/root";
    REGEX="s/\/root\/ca/$MYDIR/";
    sed -i $REGEX $ROOT_DIRECTORY/openssl.cnf;
}

function createRootKey {
    echo "----------";
    echo "createRootKey";
    echo "----------";
    openssl genrsa -aes256 -out $ROOT_KEY 4096
    chmod 400 $ROOT_KEY 
}

function createRootCertificate {
    echo "createRootCertificate";
    openssl req -config $ROOT_DIRECTORY/openssl.cnf -key $ROOT_KEY -new -x509 -days 7300 -sha256 -extensions v3_ca -out $ROOT_CERT ;
    chmod 444 $ROOT_CERT ;
}

function verifyRootCertificate {
    echo "----------";
    echo "verifyRootCertificate";
    echo "----------";
    openssl x509 -noout -text -in $ROOT_CERT; 
}

function createIntermediateDirs {
    echo "----------";
    echo "createIntermediateDirs";
    echo "----------";
    mkdir -p $ROOT_DIRECTORY/intermediate/{certs,crl,csr,newcerts,private};
    chmod 700 $ROOT_DIRECTORY/intermediate/private; 
    touch $ROOT_DIRECTORY/intermediate/index.txt;
    echo 1000 > $ROOT_DIRECTORY/intermediate/serial;
    echo 1000 > $ROOT_DIRECTORY/intermediate/crlnumber;
}


function getIntermediateConfig {
    echo "----------";
    echo "getIntermediateConfig";
    echo "----------";
    mv root-config2.txt $ROOT_DIRECTORY/intermediate/openssl.cnf; 
    MYDIR="\/home\/ryannapp\/HW2\/myscript_tmp\/root\/intermediate";
    MYOPENSSL="$ROOT_DIRECTORY/intermediate/openssl.cnf";
    REGEX="s/\/root\/ca/$MYDIR/";
    sed -i $REGEX $MYOPENSSL;
    REGEX2="s/\$dir\/private\/ca\.key\.pem/\$dir\/private\/intermediate\.key\.pem/";
    sed -i $REGEX2 $MYOPENSSL;
    REGEX3="s/\$dir\/certs\/ca\.cert\.pem/\$dir\/certs\/intermediate\.cert\.pem/";
    sed -i $REGEX3 $MYOPENSSL;
    REGEX4="s/\$dir\/crl\/ca\.crl\.pem/\$dir\/crl\/intermediate\.crl\.pem/";
    sed -i $REGEX4 $MYOPENSSL;
    REGEX5="s/policy_strict$/policy_loose/";
    sed -i $REGEX5 $MYOPENSSL;
}


function createIntermediateKey {
    echo "----------";
    echo "createIntermediateKey";
    echo "----------";
    openssl genrsa -aes256 -out $ROOT_DIRECTORY/intermediate/private/intermediate.key.pem 4096;
     chmod 400 $ROOT_DIRECTORY/intermediate/private/intermediate.key.pem;
}

function createIntermediateCertificate {
    echo "----------";
    echo "createIntermediateCertificate";
    echo "----------";
    # create certificate signing request (CSR)
    openssl req -config $ROOT_DIRECTORY/intermediate/openssl.cnf -new -sha256 -key $ROOT_DIRECTORY/intermediate/private/intermediate.key.pem -out $ROOT_DIRECTORY/intermediate/csr/intermediate.csr.pem;

    # create certificate
    openssl ca -config $ROOT_DIRECTORY/openssl.cnf -extensions v3_intermediate_ca -days 3650 -notext -md sha256 -in $ROOT_DIRECTORY/intermediate/csr/intermediate.csr.pem -out $ROOT_DIRECTORY/intermediate/certs/intermediate.cert.pem;

    chmod 444 $ROOT_DIRECTORY/intermediate/certs/intermediate.cert.pem;
}


function verifyIntermediateCertificate {
    echo "----------";
    echo "verifyIntermediateCertificate";
    echo "----------";
    openssl x509 -noout -text -in $ROOT_DIRECTORY/intermediate/certs/intermediate.cert.pem;
    openssl verify -CAfile $ROOT_DIRECTORY/certs/ca.cert.pem $ROOT_DIRECTORY/intermediate/certs/intermediate.cert.pem;
}


function createCertChain {
    echo "----------";
    echo "createCertChain";
    echo "----------";
    cat $ROOT_DIRECTORY/intermediate/certs/intermediate.cert.pem $ROOT_DIRECTORY/certs/ca.cert.pem > $ROOT_DIRECTORY/intermediate/certs/ca-chain.cert.pem;
    chmod 444 $ROOT_DIRECTORY/intermediate/certs/ca-chain.cert.pem;
}



function createServerKey {
    echo "----------";
    echo "createServerKey";
    echo "----------";
    SUBDOMAIN=$1;
    openssl genrsa -aes256 -out $ROOT_DIRECTORY/intermediate/private/$SUBDOMAIN.key.pem 2048;
    chmod 400 $ROOT_DIRECTORY/intermediate/private/$SUBDOMAIN.key.pem;
}



function createServerCertificate {
    echo "----------";
    echo "createServerCertificate";
    echo "----------";
    SUBDOMAIN=$1;
    # create server csr
    openssl req -config $ROOT_DIRECTORY/intermediate/openssl.cnf -key $ROOT_DIRECTORY/intermediate/private/$SUBDOMAIN.key.pem -new -sha256 -out $ROOT_DIRECTORY/intermediate/csr/$SUBDOMAIN.csr.pem;
    # create usr csr
    openssl req -config $ROOT_DIRECTORY/intermediate/openssl.cnf -key $ROOT_DIRECTORY/intermediate/private/$SUBDOMAIN.key.pem -new -sha256 -out $ROOT_DIRECTORY/intermediate/csr/$SUBDOMAIN.usr.csr.pem;

    echo "----------";
    echo "create server certificate";
    echo "----------";
    # create servercert
    openssl ca -config $ROOT_DIRECTORY/intermediate/openssl.cnf -extensions server_cert -days 375 -notext -md sha256 -in $ROOT_DIRECTORY/intermediate/csr/$SUBDOMAIN.csr.pem -out $ROOT_DIRECTORY/intermediate/certs/$SUBDOMAIN.cert.pem
    chmod 444 $ROOT_DIRECTORY/intermediate/certs/$SUBDOMAIN.cert.pem;


    echo "----------";
    echo "create user certificate";
    echo "----------";
    # create user cert
    openssl ca -config $ROOT_DIRECTORY/intermediate/openssl.cnf -extensions usr_cert -days 375 -notext -md sha256 -in $ROOT_DIRECTORY/intermediate/csr/$SUBDOMAIN.usr.csr.pem -out $ROOT_DIRECTORY/intermediate/certs/$SUBDOMAIN.usr.cert.pem
    chmod 444 $ROOT_DIRECTORY/intermediate/certs/$SUBDOMAIN.usr.cert.pem;
}


function verifyServerCertificate {
    echo "----------";
    echo "verifyServerCertificate";
    echo "----------";
    SUBDOMAIN=$1;
    openssl x509 -noout -text -in $ROOT_DIRECTORY/intermediate/certs/$SUBDOMAIN.cert.pem;
    openssl x509 -noout -text -in $ROOT_DIRECTORY/intermediate/certs/$SUBDOMAIN.usr.cert.pem;

    echo "----------";
    echo "verify with chain file";
    echo "----------";
    openssl verify -CAfile $ROOT_DIRECTORY/intermediate/certs/ca-chain.cert.pem $ROOT_DIRECTORY/intermediate/certs/$SUBDOMAIN.cert.pem;
    openssl verify -CAfile $ROOT_DIRECTORY/intermediate/certs/ca-chain.cert.pem $ROOT_DIRECTORY/intermediate/certs/$SUBDOMAIN.usr.cert.pem;
}


#######################################

function launchSSLServer {
    KEYPATH="$ROOT_DIRECTORY/intermediate/private/$SUBDOMAIN.key.pem";
    CERTPATH="$ROOT_DIRECTORY/intermediate/certs/$SUBDOMAIN.cert.pem";
    PORT="443";
    openssl s_server -key $KEYPATH -cert $CERTPATH -accept $PORT -www;
}


function connectToServer {
    PORT="";
    curl -kv https://localhost:$PORT;
}


# ----------
# end new
# ----------

function main {

    if [ $1 == "" ]; then
        echo "Need to specify name of subdomain for generating server cert, exiting";
        exit -1;
    fi

    SUBDOMAIN=$1;

    createDirs;
    getConfig;
    createRootKey;
    createRootCertificate;
    verifyRootCertificate;
    createIntermediateDirs; 
    getIntermediateConfig;

    createIntermediateKey;
    createIntermediateCertificate;
    verifyIntermediateCertificate;
    createCertChain;
    createServerKey $SUBDOMAIN;
    createServerCertificate $SUBDOMAIN;
    verifyServerCertificate $SUBDOMAIN;

    launchSSLServer;
}


main $1;