#!/bin/bash

# Функция обработки пользовательского сигнала
custom_signal_handler() {
    echo "Received custom signal. Calling callback function..." > signal.log
    # Вызов вашей callback функции здесь
    # Пример: my_callback_function
}

# Установка обработчика сигнала для кастомного сигнала
trap 'custom_signal_handler' SIGUSR1

# Ваш скрипт здесь
echo "Script started."

# Предположим, что здесь какая-то длинная операция
while true
do
    echo "I'm sleeping"
    sleep 1
done

echo "Script finished."
