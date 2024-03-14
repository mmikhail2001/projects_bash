#!/bin/bash

# Бал. блок
BM=1
# Самолет
PL=2
# Крылатая ракета
CM=3

# задержка между итерациями основного цикла
CLOCK_LOOP=0.8
# для рассчета скорости между двумя засечками (distance / 1 sec)
CLOCK_MOVE_TARGETS=1
# количество целей, которые за раз читаем из директории, в которой они генерируются
COUNT_TARGETS=60

function send_to_command_post {
    local message="$1"
    local target_id="$2"
    local target_type="$3"
    local target_x="$4"
    local target_y="$5"
    local timestamp=$(date +"%Y.%m.%d %H.%M.%S")
    local message="$timestamp,${TYPE_SYSTEM}$SYSTEM_NUM,$message,$target_type,$target_id,$target_x,$target_y"

    # -w 0 - кодирование в одну строку
    encrypted=$(echo "$message" | openssl enc -aes-256-cbc -e -k $password -pbkdf2 | base64 -w 0)
    hash=$(echo -n "$message$salt" | sha256sum | cut -d ' ' -f 1)
    encoded="$encrypted.$hash"
    # -N чтобы при закрытии клиента сервер не закрывал сокет
    echo "$encoded" | nc -N $COMMAND_POST_HOST $COMMAND_POST_PORT
}

function calculate_distance {
    local x1=$1
    local y1=$2
    local x2=$3
    local y2=$4
    echo "sqrt((${x1}-${x2})^2 + (${y1}-${y2})^2)" | bc -l
}

function determine_target_type {
    local speed=$1
    isBM=$(echo "$speed >= 8000 && $speed <= 10000" | bc)
    isCM=$(echo "$speed >= 250 && $speed <= 1000" | bc)
    isPL=$(echo "$speed >= 50 && $speed <= 249" | bc)
    
    
    if [ "$isBM" -eq 1 ]; then
        echo $BM
    elif [ "$isCM" -eq 1 ]; then
        echo $CM
    elif [ "$isPL" -eq 1 ]; then
        echo $PL
    else
        echo "Unknown"
    fi
}
