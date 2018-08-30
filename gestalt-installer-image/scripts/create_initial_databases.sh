#!/bin/bash
echo "Creating initial databases..."
echo "script_folder=${script_folder}"
PGPASSWORD=$DATABASE_PASSWORD psql -h $DATABASE_HOSTNAME -p $DATABASE_PORT -U $DATABASE_USERNAME $DATABASE_NAME -f "${script_folder}/init_database.sql"
