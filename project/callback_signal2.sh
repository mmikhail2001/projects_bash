#!/bin/bash

ctrlc_received=0

function handle_ctrlc()
{
    echo
    if [[ $ctrlc_received == 0 ]]
    then
        echo "I'm hmmm... running. Press Ctrl+C again to stop!"
        ctrlc_received=1
    else
        echo "It's all over!"
        exit
    fi
}

# trapping the SIGINT signal
trap handle_ctrlc SIGINT

while true
do
    echo "I'm sleeping"
    sleep 1
done
