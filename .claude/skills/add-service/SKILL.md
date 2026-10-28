---
name: add-service
description: Register a new meal-* service in the platform (database, compose, contracts, telemetry check). Use when a new service repo is created from meal-service-template.
---

# Add a service to the platform

The rules and the compose snippet are in [docs/adding-a-service.md](../../../docs/adding-a-service.md);
these are the steps.

1. **Generate the repo** (outside this repo, next to it):
   `uvx copier copy --trust gh:topol-3000/meal-service-template meal-<name>`.
2. **Database** (only with `with_database`): `make up`, then `make db-add name=meal-<name>`
   ([section 1](../../../docs/adding-a-service.md#1-database-services-with-with_database)).
   Never create it by hand.
3. **Compose** (once the service should run here): `meal-<name>-migrate` and `meal-<name>`
   entries, `services/meal-<name>.env`, the next host port, and a row in the README's
   service table ([section 2](../../../docs/adding-a-service.md#2-running-it-in-compose)).
4. **Contract**: `contracts/openapi/meal-<name>.json` from the service's `/openapi.json`
   ([section 3](../../../docs/adding-a-service.md#3-contract)).
5. **Map**: a row in the system map in `AGENTS.md`.
6. **Verify telemetry**: run the service (`make docker-run` in its repo), call an endpoint,
   then `make check-telemetry s=meal-<name>`. All three signals must be `ok`.
7. Run `make lint`.
