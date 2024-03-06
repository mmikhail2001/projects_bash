#!/bin/bash

MAIN_FILE="temp/pro1_state3.log"
TEMP_FILE="temp/pro1_state3_temp.log"
NUM=5

while IFS= read -r line; do
    last_field=$(echo "$line" | cut -d',' -f3)
    if [ "$last_field" -ge $NUM ]; then
        echo "$line" >> "$TEMP_FILE"
    else
        cp "$TEMP_FILE" "$MAIN_FILE"
        rm "$TEMP_FILE"
        break
    fi
done < <(sort "$MAIN_FILE" -r -t ',' -nk3)

if [ -f "$TEMP_FILE" ]; then
    cp "$TEMP_FILE" "$MAIN_FILE"
    rm "$TEMP_FILE"
fi
