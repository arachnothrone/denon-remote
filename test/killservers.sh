#!/bin/sh

# Kills all local running servers.

binlist=("rpi_ag.out" "ir_agent.out")

# Check names in cli arguments:
if [ $# -gt 0 ]; then
    echo "Process names to kill: $@"
    for name in $@; do
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
else
    # Otherwise, kill all in the list:
    for bin in $binlist;
    do
        pid=$(ps -ef | grep $bin | grep -v grep | awk '{print $2}')
        if ! [ -z $pid ]; then
            echo "Killing $bin with pid $pid"
            kill -9 $pid
            while kill -0 $pid 2> /dev/null; do
                sleep 1
            done
        fi
    done
fi

