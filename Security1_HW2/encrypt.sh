#!/bin/bash

openssl rsaut1 -encrypt -pubin -inkey public.key -in $1 -out $2;