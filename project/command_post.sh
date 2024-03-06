#!/bin/bash

PORT=8080

while true; do
  while read message; do
    sqlite3 ./db/messages.db "INSERT INTO messages (message) VALUES ('$message');"
  done < <(ncat -l --keep-open $PORT)
done
