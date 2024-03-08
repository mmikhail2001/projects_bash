#!/bin/bash

message="34f,34f43,f5,f5,f,54,54,,f54,g,54,f54,f.sdf.sdf.sd.f.sdf,sdf,sdf,sd,f,sdf,sd,fsd,f"
mypassword="password123"
salt="mysalt"

# encrypted=$(echo "$message" | openssl enc -aes-256-cbc -e -k $mypassword)
encrypted=$(echo -n "$message" | openssl enc -aes-256-cbc -e -k $mypassword | base64 -w 0)
encrypted="$encrypted"$'\n'


# hash=$(echo -n "$message$salt" | sha256sum | cut -d ' ' -f 1)
# encoded="$encrypted.$hash"

echo -n "$encrypted"

echo -n "$encrypted" | nc 127.0.0.1 -N 8081
