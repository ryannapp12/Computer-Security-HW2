#!/bin/bash

openssl rsaut1 -decrypt -inkey private.key -in $1 -out $2;