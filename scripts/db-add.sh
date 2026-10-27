#!/usr/bin/env bash
# Create the PostgreSQL user and database of one service (D12). Safe to run again: what
# already exists is left alone. Works on an existing volume, unlike /docker-entrypoint-initdb.d.
#
#   scripts/db-add.sh meal-recipes
#
# User, password and database are all the package name (meal_recipes), as in the service's
# .env.example: DB__URL=postgresql+asyncpg://meal_recipes:meal_recipes@localhost:5432/meal_recipes
# The service owns its database; no other service's user can connect to it.
set -euo pipefail

name=${1:?usage: scripts/db-add.sh meal-<name>}
# The rule of service_name in meal-service-template's copier.yml. It also makes `db` safe to
# put into SQL unquoted: lowercase letters, digits and underscores only.
if [[ ! $name =~ ^meal-[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]]; then
    echo "error: '$name' is not a service name like meal-recipes" >&2
    exit 1
fi
db=${name//-/_}

cd "$(dirname "$0")/.."
if [[ -z $(docker compose ps --quiet --status running postgres) ]]; then
    echo "error: postgres is not running; start it with 'make up'" >&2
    exit 1
fi

sql() {
    docker compose exec -T postgres \
        psql -U postgres -d postgres -v ON_ERROR_STOP=1 --quiet --tuples-only --no-align -c "$1"
}

if [[ -n $(sql "SELECT 1 FROM pg_roles WHERE rolname = '$db'") ]]; then
    echo "user $db: exists"
else
    sql "CREATE ROLE $db LOGIN PASSWORD '$db'"
    echo "user $db: created"
fi

owner=$(sql "SELECT pg_get_userbyid(datdba) FROM pg_database WHERE datname = '$db'")
if [[ -z $owner ]]; then
    sql "CREATE DATABASE $db OWNER $db"
    echo "database $db: created"
elif [[ $owner == "$db" ]]; then
    echo "database $db: exists"
else
    echo "error: database $db exists but is owned by $owner, not $db" >&2
    exit 1
fi

# By default every user may connect to every database (PUBLIC has CONNECT). Only the owner
# (and the superuser) may connect to this one. Repeating it changes nothing.
sql "REVOKE ALL ON DATABASE $db FROM PUBLIC"
