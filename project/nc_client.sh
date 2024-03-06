#!/bin/bash

host="localhost"
port=8081
count=0

while true; do
  echo "++ hello $count" | nc -N 0.0.0.0 8080
#   echo "hello $count from client `date`" | nc $host $port
  ((count=count+1))
  echo $count
done
