#!/usr/bin/env bash
# Creates one database and one owner role per name in $SERVICE_DATABASES.
# Local dev only: password equals the role name. Runs once, on an empty volume.
set -euo pipefail

IFS=',' read -ra names <<< "${SERVICE_DATABASES:-}"
for name in "${names[@]}"; do
  name="$(echo "$name" | xargs)"
  [[ -z "$name" ]] && continue
  echo "creating role and database: $name"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<-SQL
    CREATE ROLE "$name" LOGIN PASSWORD '$name';
    CREATE DATABASE "$name" OWNER "$name";
    REVOKE ALL ON DATABASE "$name" FROM PUBLIC;
SQL
done
