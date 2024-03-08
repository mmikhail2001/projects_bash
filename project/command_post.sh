#!/bin/bash

# watch "sqlite3 ./db/messages.db \"SELECT * FROM messages;\""

DB_FILE="./db/messages.db"
PORT=8080

# TODO: через env нужно
password="sdfr374yry3c4hkcn34ycm3u4cynfecy"
salt="mysalt"

while true; do
    while read encrypted_message; do
        decrypted="$(echo "$encrypted_message" | cut -d '.' -f 1 | base64 -d | openssl enc -aes-256-cbc -d -k $password -pbkdf2)"
        hash="$(echo "$encrypted_message" | cut -d '.' -f 2)"
        # -d decrypt, -k key
        calculated_hash=$(echo -n "$decrypted$salt" | sha256sum | cut -d ' ' -f 1)
        echo "$calculated_hash ===== $hash"
        if [ "$hash" == "$calculated_hash" ]; then
            IFS=',' read -r timestamp system message target_type target_id target_x target_y <<< "$decrypted"
            sqlite3 "$DB_FILE" "INSERT INTO messages VALUES ('$timestamp', '$system', '$message', '$target_type', '$target_id', '$target_x', '$target_y');"
            if [ $? -ne 0 ]; then
                echo "Error inserting message into database."
            fi
            echo "$timestamp $system $message $target_type $target_id"
        else
            echo "Command Post: error: hash sum"
        fi
    done < <(ncat -l --keep-open "$PORT")
done

# Error: stepping, database is locked (5)
# Error inserting message into database.
