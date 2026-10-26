---
name: add-service
description: Register a new meal-* service in the platform (database, compose, contracts, telemetry check). Use when a new service repo is created from meal-service-template.
---

# Add a service to the platform

1. **Generate the repo** (outside this repo):
   `uvx copier copy --trust gh:topol-3000/meal-service-template meal-<name>`.
2. **Database** (if the service stores data): add `<name>` to `SERVICE_DATABASES` in
   `.env.example` and `compose.yaml`. The init script only runs on an empty volume, so on an
   existing setup create it once:
   `docker compose exec postgres psql -U postgres -c "CREATE ROLE <name> LOGIN PASSWORD '<name>'" -c "CREATE DATABASE <name> OWNER <name>"`.
3. **Contracts**: create `contracts/openapi/meal-<name>.yaml` from the service's
   `/openapi.json`; add JSON Schemas for every event it produces under
   `contracts/events/schemas/` and list them in `contracts/events/README.md`.
4. **Map**: add a row to the system map in `AGENTS.md`.
5. **Verify telemetry**: run the service (`make docker-run` in its repo), call an endpoint,
   then `make check-telemetry s=meal-<name>`. All three signals must be `ok`.
6. Run `make lint`.
