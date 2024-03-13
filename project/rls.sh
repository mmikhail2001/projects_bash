#!/bin/bash

set -u

if [ $# -ne 9 ]; then
    echo "usage RLS: $0 <number> <radius> <x> <y> <direction_angle> <viewing_angle> <pro_radius> <X> <Y>"
    exit 1
fi

CLOCK_LOOP=0.8
CLOCK_MOVE_TARGETS=1
COUNT_TARGETS=60

TYPE_SYSTEM="RLS"
SYSTEM_NUM=$1
# перевод в метры
RADIUS=$(( $2 * 1000 ))
X=$(( $3 * 1000 ))
Y=$(( $4 * 1000 ))
DIRECTION_ANGLE=$5
VIEWING_ANGLE=$6
PRO_RADIUS=$(( $7 * 1000 ))
PRO_X=$(( $8 * 1000 ))
PRO_Y=$(( $9 * 1000 ))

BM=1
PL=2
CM=3

TARGET=$BM

FILE_STAGE1="./temp/${TYPE_SYSTEM}${SYSTEM_NUM}_state1.log"
FILE_STAGE2="./temp/${TYPE_SYSTEM}${SYSTEM_NUM}_state2.log"
DIR_TARGETS="/tmp/GenTargets/Targets"

COMMAND_POST_HOST="0.0.0.0"
COMMAND_POST_PORT="8081"

password="sdfr374yry3c4hkcn34ycm3u4cynfecy"
salt="mysalt"

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

function ping_callback() {
    send_to_command_post "pong" "" "" "" ""
}

trap 'ping_callback' SIGUSR1

# определение, находится ли цель в секторе действия РЛС
is_in_coverage_sector() {
    local x=$1
    local y=$2
    
    dx=$(echo "$x - $X" | bc)
    dy=$(echo "$y - $Y" | bc)
    distance=$(echo "sqrt($dx^2 + $dy^2)" | bc)
    # a = arctangent 
    # тангенс угла - результат в радианах
    angle_rad=$(echo "a($dy / $dx)" | bc -l)
    # перевод радиан в градусы
    angle_degree=$(echo "$angle_rad * (180 / 4 * a(1))" | bc -l)
    angle=$(echo "($angle_degree + 360) % 360" | bc)

    half_sector=$(echo "$VIEWING_ANGLE / 2" | bc)
    lower_bound=$(echo "($DIRECTION_ANGLE - $half_sector + 360) % 360" | bc)
    upper_bound=$(echo "($DIRECTION_ANGLE + $half_sector) % 360" | bc)

    if (( $(echo "$distance <= $RADIUS && $lower_bound <= $angle && $angle <= $upper_bound" | bc -l) )); then
        echo 1
    else
        echo 0
    fi
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

function calculate_distance {
    local x1=$1
    local y1=$2
    local x2=$3
    local y2=$4
    echo "sqrt((${x1}-${x2})^2 + (${y1}-${y2})^2)" | bc -l
}

# определение, летит ли цель по направлению к зоне действия ПРО 
function is_intersected_PRO_zone() {
    local x1=$1
    local y1=$2
    local x2=$3
    local y2=$4
    local center_x=$PRO_X
    local center_y=$PRO_Y
    local radius=$PRO_RADIUS

    # Прямая движения цели: y = kx + b; найдем k, b
    local k=$(bc -l <<< "scale=10; ($y2 - $y1) / ($x2 - $x1)")
    local b=$(bc -l <<< "scale=10; $y1 - $k * $x1")

    # (x3, y3) - координаты точки пересечения прямой движения цели (заданной по 2 точкам) и прямой, 
    # перпендикулярной к данной и проходящей через центр окружности.
    local x3=$(bc -l <<< "scale=10; -($b - ($center_x / $k) - $center_y) / ($k + 1 / $k)")
    local y3=$(bc -l <<< "scale=10; $k * $x3 + $b")

    # расстояние от точки пересечения (x3, y3) до центра окружности (center_x, center_y)
    local distance=$(bc -l <<< "scale=10; sqrt(($x3 - $center_x)^2 + ($y3 - $center_y)^2)")

    echo "distance[$distance], radius[$radius]" >> test.test.log

    if (( $(bc <<< "$distance <= $radius") )); then
        echo 1
    else
        echo 0
    fi
}

function get_stage() {
    local target_id=$1
    local x=$2
    local y=$3
    if grep -q "$target_id" "$FILE_STAGE2"; then
        echo 2
    elif grep -q "$target_id" "$FILE_STAGE1"; then
        if grep -q "$target_id,$x,$y" "$FILE_STAGE1"; then
            echo "Erorr: double read"    
        fi
        echo 1
    else
        echo 0
    fi
}

send_to_command_post "registration:$$" "" "" "" ""

NUM_ITER=0
while true; do
    TARGET_FILES=$(ls -t $DIR_TARGETS | head -n $COUNT_TARGETS | tac)
    ((NUM_ITER = NUM_ITER + 1))
    for target_file in $TARGET_FILES; do
        target_id=${target_file:12:6}
        target_coordinates=$(cat "$DIR_TARGETS/$target_file")
        target_x=$(echo $target_coordinates | cut -d',' -f1 | tr -d 'X')
        target_y=$(echo $target_coordinates | cut -d',' -f2 | tr -d 'Y')

        if [ "$(is_in_coverage_sector $target_x $target_y)" -eq 1 ]; then
            # switch case по присутствию цели на определенной стадии
            case $(get_stage "$target_id" "$target_x" "$target_y") in
                1)
                    # сохранены изначальные координаты, нужно извлечь вторые координаты, найти скорость, выстрелить, если нужно
                    previous_coordinates=$(grep "$target_id" "$FILE_STAGE1" | cut -d',' -f2-)
                    previous_x=$(echo $previous_coordinates | cut -d',' -f1)
                    previous_y=$(echo $previous_coordinates | cut -d',' -f2)
                    distance_between_clocks=$(calculate_distance $previous_x $previous_y $target_x $target_y)
                    speed=$(echo "$distance_between_clocks / $CLOCK_MOVE_TARGETS" | bc -l)
                    current_target_type=$(determine_target_type $speed)
                    # сообщать об обнаружении всех целей или только тех, которые входят в зону ответственности системы ?
                    send_to_command_post "target detected" "$target_id" "$current_target_type" "$target_x" "$target_y"
                    echo "$target_id,$speed,$current_target_type,$previous_x,$previous_y,$target_x,$target_y" >> $FILE_STAGE2
                    if [[ "$TARGET" == *"$current_target_type"* ]]; then
                        if [ "$(is_intersected_PRO_zone $previous_x $previous_y $target_x $target_y)" -eq 1 ]; then
                            send_to_command_post "target moves to PRO" "$target_id" "$current_target_type" "$target_x" "$target_y"
                        fi
                    fi
                    ;;
                0)
                    echo "$target_id,$target_x,$target_y" >> $FILE_STAGE1
                    ;;
            esac
        fi
    done
    sleep $CLOCK_LOOP
done
