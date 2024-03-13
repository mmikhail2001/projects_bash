#!/bin/bash

custom_signal_handler() {
    echo "Received custom signal. Calling callback function..." > signal.log
}

trap 'custom_signal_handler' SIGUSR1
echo "Script started."

while true
do
    echo "I'm sleeping"
    sleep 1
done

echo "Script finished."
