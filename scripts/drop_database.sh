#!/bin/bash

if [ -z "$1" ]; then
  echo "Must run with database name as argument"
  exit 1
fi

if [ "$2" != "--yes" ]; then
  echo "Must confirm delete with --yes"
  exit 1
fi

DB_NAME=$1

echo "Dropping database '$DB_NAME'..."

PGPASSWORD=$DATABASE_PASSWORD psql -h $DATABASE_HOSTNAME -p $DATABASE_PORT -U $DATABASE_USERNAME $DATABASE_NAME << EOF
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = '$DB_NAME'
  AND pid <> pg_backend_pid();

drop database if exists "$DB_NAME";
EOF

RET=$?
if [ $RET -ne 0 ]; then
  echo "Error dropping database, return code $RET"
  exit $RET
fi

echo "Done."
