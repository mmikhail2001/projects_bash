#!/bin/bash

set -u

# Указываем путь к файлу с данными
SYSTEM_PIDS_FILE="test_file.txt"

# Определяем систему и PID для тестирования
system="system1"
pid="999"

echo "Исходное содержимое файла $SYSTEM_PIDS_FILE:"
cat "$SYSTEM_PIDS_FILE"
echo

# Выполняем команду sed для замены PID у указанной системы
# sed -i "/[^,]*$system/s/*/$system,$pid,pong/2" "$SYSTEM_PIDS_FILE"
# sed -i "/^${pid},${system}/s/^[0-9]*/${pid}/" "$SYSTEM_PIDS_FILE"
# sed -i "/${system}/s/^[0-9]*/${pid}/" "$SYSTEM_PIDS_FILE"
# sed -i "/${system}/s//$pid,$system,pong/" "$SYSTEM_PIDS_FILE"
sed -i "s/^.*$system.*/$pid,$system,pong/" "$SYSTEM_PIDS_FILE"


echo "Файл $SYSTEM_PIDS_FILE после применения команды sed:"
cat "$SYSTEM_PIDS_FILE"
