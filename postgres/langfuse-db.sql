-- Langfuse's user and database in the shared PostgreSQL (run by the `langfuse-db` job).
-- Safe to run again: what exists is left alone. Local credentials only, like .env.example.
SELECT 'CREATE ROLE langfuse LOGIN PASSWORD ''langfuse'''
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'langfuse')\gexec

SELECT 'CREATE DATABASE langfuse OWNER langfuse'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'langfuse')\gexec

-- Only Langfuse (and the superuser) may connect, as for a service's database.
REVOKE ALL ON DATABASE langfuse FROM PUBLIC;
