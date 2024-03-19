#!/bin/bash

set -u

DB_FILE="./db/messages.db"
LISTEN_PORT=8081
PING_PONG_TIME_INTERVAL=20

source .env

SYSTEM_PIDS_FILE="./temp/system_pids_file"
# Содержание файла (pid, system, status), где status = pong ("ответил") или ping ("отправили запрос")
# 2130350,PRO1,pong
# 2130356,ZRDN2,ping // не отвечает
# 2130352,ZRDN1,pong

touch "$SYSTEM_PIDS_FILE"

handle_special_messages() {
    local system="$1"
    local message="$2"
    local text_message=$(echo "$message" | cut -d ':' -f 1) 

    case "$text_message" in
        "registration")
            # регистрация системы в файле SYSTEM_PIDS_FILE
            local pid=$(echo "$message" | cut -d ':' -f 2)  
            
            # проверяем, существует ли уже система в файле (могла восстановить работу)
            if grep -q "^$system," "$SYSTEM_PIDS_FILE"; then
                # обновляем pid
                sed -i "s/^.*$system.*/$pid,$system,pong/" "$SYSTEM_PIDS_FILE"
            else
                # регистрация новой системы
                echo "$pid,$system,pong" >> "$SYSTEM_PIDS_FILE"
            fi

            sqlite3 "$DB_FILE" "INSERT INTO messages VALUES ('$(date +"%Y.%m.%d %H.%M.%S")', '$system', 'registration request:$pid', '', '', '', '');"
            echo 0
            ;;
        "pong")
            # pong пришел, изменяем состояние на pong = "система ответила на ping
            # чтобы в асинхронной задачи рассылки пингов понять, кто ответил на предыдущий, кто - нет
            sed -i "/$system/s/ping/pong/" "$SYSTEM_PIDS_FILE"
            sqlite3 "$DB_FILE" "INSERT INTO messages VALUES ('$(date +"%Y.%m.%d %H.%M.%S")', '$system', 'pong received', '', '', '', '');"
            echo 0
            ;;
        "shot is not possible on target")
            local pid=$(grep "$system" "$SYSTEM_PIDS_FILE" | cut -d',' -f1)
            kill -SIGUSR2 "$pid" &
            echo 1
            ;;
        *)
            echo 1
            ;;
    esac
}

# раз в 20 секунд проходимся по всем системам в SYSTEM_PIDS_FILE
# отправляем ping всем, кто ответил на предыдущий (т.е. тем, у кого состояние = pong)
async_ping_task() {
    while true; do
        cat "$SYSTEM_PIDS_FILE" | while IFS=',' read -r pid system status; do
            if [[ "$status" == "pong" ]]; then
                sed -i "/$system/s/pong/ping/" "$SYSTEM_PIDS_FILE"
                kill -SIGUSR1 "$pid"
            else
                sqlite3 "$DB_FILE" "INSERT INTO messages VALUES ('`date +"%Y.%m.%d %H.%M.%S"`', '$system', 'pong not received', '', '', '', '');"
                # система из массива не удаляется, система получает пинги всегда
                kill -SIGUSR1 "$pid"
            fi
        done
        sleep $PING_PONG_TIME_INTERVAL
    done
}

async_ping_task &

while true; do
    while read encrypted_message; do
        # расшифровка сообщения: encrypted_message = "{encrypted_content}.{hash}"
        decrypted=$(echo "$encrypted_message" | cut -d '.' -f 1 | base64 -d | openssl enc -aes-256-cbc -d -k "$password" -pbkdf2)
        hash=$(echo "$encrypted_message" | cut -d '.' -f 2)
        calculated_hash=$(echo -n "$decrypted$salt" | sha256sum | cut -d ' ' -f 1)
        # проверка hash суммы
        if [ "$hash" == "$calculated_hash" ]; then
            IFS=',' read -r timestamp system message target_type target_id target_x target_y <<< "$decrypted"
            # сообщения типа pong или registration_message обрабатываем отдельно 
            if [ "$(handle_special_messages "$system" "$message")" -ne 0 ]; then
                sqlite3 "$DB_FILE" "INSERT INTO messages VALUES ('$timestamp', '$system', '$message', '$target_type', '$target_id', '$target_x', '$target_y');"
                if [ $? -ne 0 ]; then
                    echo "Error inserting message into database."
                fi
            fi
        else
            sqlite3 "$DB_FILE" "INSERT INTO messages VALUES ('`date +"%Y.%m.%d %H.%M.%S"`', '', 'message hash sum is incorrect', '', '', '', '');"
        fi
    done < <(ncat -l --keep-open "$LISTEN_PORT")
done
