#!/bin/sh

# Kills all local running servers/clients. Takes process names from the 
# predefined binlist if no arguments are given. 
# Usage: killservers.sh [process_name1] [process_name2] ...

if [ $# -gt 0 ]; then
    binlist=$@
else
    binlist=("rpi_ag.out" "ir_agent.out")
fi

echo "Process names to kill: $binlist"
for name in $binlist; do
    echo "Looking for $name ..."
    ps -ef | grep $name
    echo "Debug: filtered output:"
    ps -ef | grep $name | grep -v grep | grep -v killservers.sh
    pid=$(ps -ef | grep $name | grep -v grep | grep -v killservers.sh | awk '{print $2}')
    echo "Found pid $pid"
    if ! [ -z $pid ]; then
        echo "Killing $name with pid $pid"
        kill -9 $pid
        while kill -0 $pid 2> /dev/null; do
            sleep 1
        done
    fi
done
