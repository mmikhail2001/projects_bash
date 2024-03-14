#!/bin/bash

# TODO:
# возможно, если система вышла за радиус, то залогируется target destroyed ...

# детектирование обращения к необъявленным переменным
set -u

if [ $# -ne 5 ]; then
    echo "usage: $0 <type_system: PRO | ZRDN> <number> <radius> <x> <y>"
    exit 1
fi

COUNT_SHOOTS=0

TYPE_SYSTEM=$1
SYSTEM_NUM=$2
# перевод в метры
RADIUS=$(( $3 * 1000 ))
X=$(( $4 * 1000 ))
Y=$(( $5 * 1000 ))

function set_ammunition() {
    if [ "$TYPE_SYSTEM" == "PRO" ]; then
        TARGET=$BM
        COUNT_SHOOTS=2
    elif [ "$TYPE_SYSTEM" == "ZRDN" ]; then
        TARGET="$PL,$CM"
        COUNT_SHOOTS=1
    fi
}

FILE_STAGE1="./temp/${TYPE_SYSTEM}${SYSTEM_NUM}_state1.log"
FILE_STAGE2="./temp/${TYPE_SYSTEM}${SYSTEM_NUM}_state2.log"
FILE_STAGE3="./temp/${TYPE_SYSTEM}${SYSTEM_NUM}_state3.log"
# временный файл, в котором сохраняются цели, в которые стрельнули, и ждем результата на след. такте
# остальные цели, т.е. те, в которые стрельнули и которые заново не сгенерировались, считаются уничтоженными (в файл не попадают)
FILE_STAGE3_TEMP="./temp/${TYPE_SYSTEM}${SYSTEM_NUM}_state3_temp.log"
DIR_TARGETS="/tmp/GenTargets/Targets"
DIR_DESTROY="/tmp/GenTargets/Destroy"

# стадия 1 - цели, которые были обнаружены и координаты которых уже были записаны
# стадия 2 - цели, которые были обнаружены повторно, по которым посчитана скорость и выявлен тип (ББ БР, Кр. ракеты, Самолеты)
# стадия 3 - цели, за которые несет ответственность данная система (для ПРО это ББ БР)  

COMMAND_POST_HOST="0.0.0.0"
COMMAND_POST_PORT="8081"

source .env
source shared.sh

function ping_callback() {
    send_to_command_post "pong" "" "" "" ""
}

function new_ammunition_callback() {
    set_ammunition
}

# обработчик "func ping_callback" для сигнала ping от командного пункта
trap 'ping_callback' SIGUSR1

# обработчик "func new_ammunition_callback", когда командный пункт поймет,
# что боеприпасы закончились и захочет дать новые
trap 'new_ammunition_callback' SIGUSR2

function get_stage() {
    target_id="$1"
    x="$2"
    y="$3"
    if grep -q "$target_id" "$FILE_STAGE3"; then
        echo 3
    elif grep -q "$target_id" "$FILE_STAGE2"; then
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

# для целей с номером итерации ITER_TO_SAVE будет известен результат только на след такте
# цели, для которых итерации выстрела меньше ITER_TO_SAVE, считаются уничтоженными
function remove_killed_targets() {
    # итерация, на которой еще не известно, уничтожена ли цель или нет (эти цели нужно сохранить в логе)
    ITER_TO_SAVE=$1
    touch $FILE_STAGE3_TEMP
    while IFS= read -r line; do
        local target_id=$(echo "$line" | cut -d',' -f1)
        local target_type=$(echo "$line" | cut -d',' -f2)
        local iter=$(echo "$line" | cut -d',' -f3)
        if [ "$iter" == "$ITER_TO_SAVE" ]; then
            echo "$line" >> "$FILE_STAGE3_TEMP"
        else
            send_to_command_post "target destroyed" "$target_id" "$target_type" "" ""
        fi
    # реверсивная сортировка по 3-ему полю (поля разделены через ',')
    done < <(sort "$FILE_STAGE3" -r -t ',' -nk3)
    # удаление уничтоженных целей
    cp "$FILE_STAGE3_TEMP" "$FILE_STAGE3" 2>/dev/null
    rm "$FILE_STAGE3_TEMP" 2>/dev/null
}

function handle_shot() {
    local target_id="$1"
    local target_type="$2"
    local target_x="$3"
    local target_y="$4"
    local stage="$5"

    if [ "$stage" == "3" ]; then
        # на стадии 3 цели, в которые уже хотя бы раз стреляли
        send_to_command_post "missed target" "$target_id" "$target_type" "$target_x" "$target_y"
    fi

    if [ $COUNT_SHOOTS -gt 0 ]; then
        ((COUNT_SHOOTS--))
        echo "$target_id" > "$DIR_DESTROY/$target_id"
        send_to_command_post "shot at target" "$target_id" "$target_type" "$target_x" "$target_y"
    else 
        send_to_command_post "shot is not possible on target" "$target_id" "$target_type" "$target_x" "$target_y"
    fi
}

set_ammunition
send_to_command_post "registration:$$" "" "" "" ""

NUM_ITER=0
while true; do
    # читаем, начиная со старых записей
    TARGET_FILES=$(ls -t $DIR_TARGETS | head -n $COUNT_TARGETS | tac)
    ((NUM_ITER = NUM_ITER + 1))
    for target_file in $TARGET_FILES; do
        target_id=${target_file:12:6}
        target_coordinates=$(cat "$DIR_TARGETS/$target_file")
        target_x=$(echo $target_coordinates | cut -d',' -f1 | tr -d 'X')
        target_y=$(echo $target_coordinates | cut -d',' -f2 | tr -d 'Y')

        distance_to_target=$(calculate_distance $X $Y $target_x $target_y)
        # если цель находится в радиусе действия системы
        if (( $(echo "$distance_to_target <= $RADIUS" | bc -l) == 1 )); then
            # switch case по присутствию цели на определенной стадии
            case $(get_stage "$target_id" "$target_x" "$target_y") in
                3)
                    # изменение номера итерации, т.к. предыдущий выстрел был промахом и в цель нужно выстрелить заново
                    sed -i "/^$target_id,/s/,[^,]*$/,$NUM_ITER/" "$FILE_STAGE3"
                    current_target_type=$(grep "$target_id" "$FILE_STAGE3" | cut -d',' -f2)
                    handle_shot "$target_id" "$current_target_type" "$target_x" "$target_y" "3"
                    ;;
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
                    echo "$target_id,$speed,$current_target_type" >> $FILE_STAGE2
                    if [[ "$TARGET" == *"$current_target_type"* ]]; then
                        echo "$target_id,$current_target_type,$NUM_ITER" >> $FILE_STAGE3
                        handle_shot "$target_id" "$current_target_type" "$target_x" "$target_y" "1"
                    fi
                    ;;
                0)
                    echo "$target_id,$target_x,$target_y" >> $FILE_STAGE1
                    ;;
            esac
        fi
    done
    # удаление уничтоженных целей, т.е. тех целей, выстрел по которым был совершен в пред. такте 
    # и которые не сгенерировались в текущем такте
    remove_killed_targets "$NUM_ITER" 
    sleep $CLOCK_LOOP
done
