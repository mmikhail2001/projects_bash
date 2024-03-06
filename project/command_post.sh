#!/bin/bash

# watch "sqlite3 ./db/messages.db \"SELECT * FROM messages;\""

DB_FILE="./db/messages.db"
PORT=8080


while true; do
    while read message; do
        IFS=',' read -r timestamp system message target_type target_id target_x target_y <<< "$message"
        sqlite3 "$DB_FILE" "INSERT INTO messages VALUES ('$timestamp', '$system', '$message', '$target_type', '$target_id', '$target_x', '$target_y');"
        if [ $? -ne 0 ]; then
            echo "Error inserting message into database."
        fi
        echo "$timestamp $system $message $target_type $target_id"
    done < <(ncat -l --keep-open "$PORT")
done

# Error: stepping, database is locked (5)
# Error inserting message into database.
