#!/bin/bash
# set -e

function sleep_forever() {
    while [ 1 ]; do
        sleep 60
    done
}

CMD=${1:-install}

pwd
find . -type f

if [ "$CMD" == 'install' ]; then
    echo "Installing Gestalt platform... ('install' container argument specified)"

    SECONDS=0
    log=/install.log

    echo "Initiating Gestalt platform installation at `date`" | tee -a $log

    scripts/install.sh $2 2>&1 | tee -a $log

    echo "Total elapsed time: $SECONDS seconds." | tee -a $log

    if [ "$2" == "debug" ]; then 
        echo "Debug was enabled, sleeping forever so container stays running..."
        sleep_forever
    fi
elif [ "$1" == 'sleep' ]; then
    echo "Sleep command asserted, sleeping forever so container stays running..."
    sleep_forever 
else
  echo "Skipping Gestalt installation ('install' container argument not specified)."
fi
