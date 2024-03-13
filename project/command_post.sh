#!/bin/bash

set -u

DB_FILE="./db/messages.db"
PORT=8081

password="sdfr374yry3c4hkcn34ycm3u4cynfecy"
salt="mysalt"

SYSTEM_PIDS_FILE="./temp/system_pids_file"
touch "$SYSTEM_PIDS_FILE"

handle_pong_or_registration_message() {
    local system="$1"
    local message="$2"
    if [[ $message == "registration"* ]]; then
        local pid=$(echo "$message" | cut -d ':' -f 2)  
        echo "$pid,$system,pong" >> "$SYSTEM_PIDS_FILE"
        sqlite3 "$DB_FILE" "INSERT INTO messages VALUES ('`date +"%Y.%m.%d %H.%M.%S"`', '$system', 'registration request:$pid', '', '', '', '');"
        echo 1
    elif [[ $message == "pong" ]]; then
        sed -i "/$system/s/ping/pong/" "$SYSTEM_PIDS_FILE"
        sqlite3 "$DB_FILE" "INSERT INTO messages VALUES ('`date +"%Y.%m.%d %H.%M.%S"`', '$system', 'pong received', '', '', '', '');"
        echo 1
    fi
    echo 0
}

async_ping_task() {
    while true; do
        cat "$SYSTEM_PIDS_FILE" | while IFS=',' read -r pid system status; do
            if [[ "$status" == "pong" ]]; then
                sed -i "/$system/s/pong/ping/" "$SYSTEM_PIDS_FILE"
                kill -SIGUSR1 "$pid"
            else
                local timestamp=$(date +"%Y.%m.%d %H.%M.%S")
                sqlite3 "$DB_FILE" "INSERT INTO messages VALUES ('$timestamp', '$system', 'pong not received', '', '', '', '');"
            fi
        done
        sleep 20
    done
}

async_ping_task &

while true; do
    while read encrypted_message; do
        decrypted=$(echo "$encrypted_message" | cut -d '.' -f 1 | base64 -d | openssl enc -aes-256-cbc -d -k "$password" -pbkdf2)
        hash=$(echo "$encrypted_message" | cut -d '.' -f 2)
        calculated_hash=$(echo -n "$decrypted$salt" | sha256sum | cut -d ' ' -f 1)
        if [ "$hash" == "$calculated_hash" ]; then
            IFS=',' read -r timestamp system message target_type target_id target_x target_y <<< "$decrypted"
            if [ "$(handle_pong_or_registration_message "$system" "$message")" -eq 0 ]; then
                sqlite3 "$DB_FILE" "INSERT INTO messages VALUES ('$timestamp', '$system', '$message', '$target_type', '$target_id', '$target_x', '$target_y');"
                if [ $? -ne 0 ]; then
                    echo "Error inserting message into database."
                fi
            fi
        else
            sqlite3 "$DB_FILE" "INSERT INTO messages VALUES ('`date +"%Y.%m.%d %H.%M.%S"`', '', 'message hash sum is incorrect', '', '', '', '');"
            # из массива не удаляется, система получает пинги всегда
        fi
    done < <(ncat -l --keep-open "$PORT")
done
