#!/bin/bash
echo "Creating initial databases..."
PGPASSWORD=$DATABASE_PASSWORD psql -h $DATABASE_HOSTNAME -p $DATABASE_PORT -U $DATABASE_USERNAME $DATABASE_NAME -f ${script_folder}/init_database.sql
