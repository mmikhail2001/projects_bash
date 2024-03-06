#!/bin/bash

if [ $# -ne 4 ]; then
    echo "usage: $0 <radius> <x> <y> <number>"
    exit 1
fi

CLOCK=1

RADIUS=$1
PRO_X=$2
PRO_Y=$3
PRO_NUM=$4

BM=1
PL=2
CM=3

COUNT_SHOOTS=20

FILE_STAGE1="./temp/pro${PRO_NUM}_state1.log"
FILE_STAGE2="./temp/pro${PRO_NUM}_state2.log"
FILE_STAGE3="./temp/pro${PRO_NUM}_state3.log"
FILE_LOG="./temp/pro${PRO_NUM}.log"
DIR_TARGETS="/tmp/GenTargets/Targets"
DIR_DESTROY="/tmp/GenTargets/Destroy"

COMMAND_POST_HOST="0.0.0.0"
COMMAND_POST_PORT="8080"

function send_to_command_post {
    echo "$1" | nc -N $COMMAND_POST_HOST $COMMAND_POST_PORT
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
    isPL=$(echo "$speed >= 50 && $speed <= 250" | bc)
    
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

while true; do
    TARGET_FILES=$(ls -t $DIR_TARGETS | head -n 30)

    for target_file in $TARGET_FILES; do
        target_id=${target_file:12:6}
        target_coordinates=$(cat "$DIR_TARGETS/$target_file")
        target_x=$(echo $target_coordinates | cut -d',' -f1 | tr -d 'X')
        target_y=$(echo $target_coordinates | cut -d',' -f2 | tr -d 'Y')

        distance_to_target=$(calculate_distance $PRO_X $PRO_Y $target_x $target_y)
        echo $distance_to_target
        if (( $(echo "$distance_to_target <= $RADIUS" | bc -l) == 1 )); then
            if grep -q "$target_id" "$FILE_STAGE1"; then
                if ! grep -q "$target_id" "$FILE_STAGE2"; then    
                    # если есть в логе1, но нет в логе2
                    previous_coordinates=$(grep "$target_id" "$FILE_STAGE1" | tail -1 | cut -d',' -f2-)
                    previous_x=$(echo $previous_coordinates | cut -d',' -f1)
                    previous_y=$(echo $previous_coordinates | cut -d',' -f2)
                    distance_between_clocks=$(calculate_distance $previous_x $previous_y $target_x $target_y)
                    speed=$(echo "$distance_between_clocks / $CLOCK" | bc -l)
                    target_type=$(determine_target_type $speed)
                    echo "$(date) ПРО$PRO_NUM Обнаружена цель $target_type с ID:$target_id X=$target_x Y=$target_y" >> $FILE_LOG
                    echo "$target_id,$speed,$target_type" >> $FILE_STAGE2
                    if [ "$target_type" == "$BM" ]; then
                        echo "$target_id" >> $FILE_STAGE3
                        if [ $COUNT_SHOOTS -gt 0 ]; then
                            ((COUNT_SHOOTS--))
                            echo "$target_id" > "$DIR_DESTROY/$target_id"
                            echo "$(date) ПРО$PRO_NUM выстрел по цели ID:$target_id X=$target_x Y=$target_y" >> $FILE_LOG
                        else 
                            echo "$(date) ПРО$PRO_NUM выстрел невозможен по цели ID:$target_id X=$target_x Y=$target_y" >> $FILE_LOG
                        fi
                    fi
                fi
            elif ! grep -q "$target_id" "$FILE_STAGE3"; then
                # если нет ни в логе1, ни в логе3
                echo "$target_id,$target_x,$target_y" >> $FILE_STAGE1
            elif [ $COUNT_SHOOTS -gt 0 ]; then
                # если есть и в логе1, и в логе3
                ((COUNT_SHOOTS--))
                echo "$(date) ПРО$PRO_NUM промах по цели ID:$target_id X=$target_x Y=$target_y" >> $FILE_LOG
                echo "$(date) ПРО$PRO_NUM повторный выстрел по цели ID:$target_id X=$target_x Y=$target_y" >> $FILE_LOG
                echo "$target_id" > "$DIR_DESTROY/$target_id"
            else
                echo "$(date) ПРО$PRO_NUM выстрел невозможен по цели ID:$target_id X=$target_x Y=$target_y" >> $FILE_LOG
            fi
        fi
    done
    sleep $CLOCK
done
