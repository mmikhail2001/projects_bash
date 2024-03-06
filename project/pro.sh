#!/bin/bash

if [ $# -ne 4 ]; then
    echo "usage: $0 <radius> <x> <y> <number>"
    exit 1
fi

# TODO: нужно добавить константу CLOCK (которая означает время, через которое нужно вновь читать 30 файликов)
# это время должно использоваться при подсчете скорости: (distance) / CLOCK

RADIUS=$1
PRO_X=$2
PRO_Y=$3
PRO_NUM=$4

function calculate_distance {
    local x1=$1
    local y1=$2
    local x2=$3
    local y2=$4
    echo "sqrt((${x1}-${x2})^2 + (${y1}-${y2})^2)" | bc -l
}

# TODO: не нужны типы целей на русском языке
# сделай константы, именно их и возаращай и используй дальше 
# BM=1
# PL=2
# CM=3

# сделай константы FILE_STATE1, FILE_STATE2, FILE_STATE3 

function determine_target_type {
    local speed=$1
    if (( speed >= 8000 && speed <= 10000 )); then
        echo "ББ БР"
    elif (( speed >= 250 && speed <= 1000 )); then
        echo "Крылатая ракета"
    elif (( speed >= 50 && speed <= 250 )); then
        echo "Самолет"
    else
        echo "Неизвестный тип цели"
    fi
}

# TODO: нужен внешний вечный цикл, который будет читать новые 30 файликов
# и перед следующей итерацией sleep CLOCK
TARGET_FILES=$(ls -t /tmp/GenTargets/Targets | head -n 30)

for target_file in $TARGET_FILES; do
    target_id=${target_file:12:6}
    target_coordinates=$(cat "/tmp/GenTargets/Targets/$target_file")
    # TODO: сделай это без sed, просто нужно убрать первый символ (Y или X)
    target_x=$(echo $target_coordinates | cut -d',' -f1 | sed 's/X//')
    target_y=$(echo $target_coordinates | cut -d',' -f2 | sed 's/Y//')

    distance=$(calculate_distance $PRO_X $PRO_Y $target_x $target_y)
    # TODO: зачем в if используется bc, сделай сравнение просто
    if (( $(echo "$distance <= $RADIUS" | bc -l) )); then
        # state_file1, state_file2, state_file3 вынеси в константы
         
        state_file="/tmp/pro${PRO_NUM}_state1.log"
        if grep -q "$target_id" "$state_file"; then
            # TODO: чтобы найти speed, надо distance / CLOCK
            # if файла нет во втором состоянии then 
            # {
                speed=$(calculate_distance $(cat "$state_file" | grep "$target_id" | cut -d',' -f2) $target_x $target_y)
                target_type=$(determine_target_type $speed)
                echo "$(date) ПРО$PRO_NUM Обнаружена цель $target_type с ID:$target_id X=$target_x Y=$target_y" >> /tmp/pro${PRO_NUM}.log
                echo "$target_id" >> /tmp/pro${PRO_NUM}_state2.log
                # TODO: вот здесь нужен код. Если target_type=BM, то 
                # echo "$target_id" > "/tmp/GenTargets/Destroy/$target_id"
                # echo "$(date) ПРО$PRO_NUM выстрел по цели ID:$target_id X=$target_x Y=$target_y" >> /tmp/pro${PRO_NUM}.log
                # echo "$target_id" >> /tmp/pro${PRO_NUM}_state3.log
            # }
            # if файл есть в третьем состоянии then
            # {
                # echo "$target_id" > "/tmp/GenTargets/Destroy/$target_id"
                # echo "$(date) ПРО$PRO_NUM повторный выстрел по цели ID:$target_id X=$target_x Y=$target_y" >> /tmp/pro${PRO_NUM}.log
            # }
            
        else
            echo "$target_id,$target_coordinates" >> "/tmp/pro${PRO_NUM}_state1.log"
        fi
    fi
done

# TODO: замени state на stage (в названиях переменных)
