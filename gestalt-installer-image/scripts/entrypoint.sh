#!/bin/bash
# set -e

if [ "$1" == 'install' ]; then
  echo "Installing Gestalt platform... ('install' container argument specified)"

  SECONDS=0
  log=/gestalt/install-gestalt-platform.log

  echo "Initiating Gestalt platform installation at `date`" | tee -a $log
  cd /gestalt && ./install-gestalt-platform.sh $2 | tee -a $log
  echo "Total elapsed time: $SECONDS seconds." | tee -a $log
else
  echo "Skipping Gestalt installation ('install' container argument not specified)."
fi

echo "Sleeping forever so container stays running..."
while [ 1 ]; do
  sleep 60
done

# echo "Sleeping for awhile so container stays running..."
# for i in `seq 1 5`; do
#   echo "Sleeping for a min... (iteration $i)"
#   sleep 60
# done
# echo "Finished."
