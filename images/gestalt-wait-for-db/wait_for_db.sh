#!/bin/bash

until pg_isready -h ${PGHOST} -p ${PGPORT}; do
  EXIT_CODE=$?
  TIME=$( date "+%Y-%m-%d %H:%M:%S+%s" )
  echo "[${TIME}] [${EXIT_CODE}] waiting for db at {$PGHOST}:${PGPORT}...."
  sleep 2
done

EXIT_CODE=$?
TIME=$( date "+%Y-%m-%d %H:%M:%S+%s" )
echo "[${TIME}] [${EXIT_CODE}] ${PGHOST}:${PGPORT} is accepting connections!"

if [ -n "${PGPASS}" ]; then
  echo "${PGHOST}:${PGPORT}:*:${PGUSER}:${PGPASS}" > ~/.pgpass
  chmod 0600 ~/.pgpass
fi

if [ -n "${PGDATABASE}" ]; then
  until psql -lqt | cut -d \| -f 1 | grep -qw ${PGDATABASE}; do
    EXIT_CODE=$?
    TIME=$( date "+%Y-%m-%d %H:%M:%S+%s" )
    echo "[${TIME}] [${EXIT_CODE}] waiting for db ${PGDATABASE} to be created at ${PGHOST}:${PGPORT}...."
    sleep 2
  done
  EXIT_CODE=$?
  TIME=$( date "+%Y-%m-%d %H:%M:%S+%s" )
  echo "[${TIME}] [${EXIT_CODE}] SUCCESS!"
  psql -lqt
fi

