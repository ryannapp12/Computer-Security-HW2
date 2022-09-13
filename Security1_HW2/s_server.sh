#!/bin/bash

openssl s_server -key myscript_tmp/root/intermediate/private/www.ryannapp.com.key.pem -cert myscript_tmp/root/intermediate/certs/www.ryannapp.com.cert.pem localhost:443