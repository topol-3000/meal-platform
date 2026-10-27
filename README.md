# meal-platform

Local platform for the FamilyMeal `meal-*` services, and the place for what they share:
HTTP contracts and architecture decisions. Services are generated from
[meal-service-template](https://github.com/topol-3000/meal-service-template).

## Quick start

Needs Docker Engine 25+ with Compose v2.

```bash
make up                            # Grafana, PostgreSQL, Valkey; waits until healthy
make db-add name=meal-recipes      # a database and user for a service, safe to repeat
```

Then in the service: `cp .env.example .env && make migrate && make run`.

| What | Where |
|---|---|
| Grafana (Tempo, Loki, Prometheus) | <http://localhost:3000>, no login |
| OTLP | `http://localhost:4318` (HTTP), `localhost:4317` (gRPC) |
| PostgreSQL 18 | `localhost:5432`, superuser `postgres` / `postgres` |
| Valkey 9 | `localhost:6379` |

Containers in the `meal-platform` Docker network reach them as `lgtm`, `postgres` and
`valkey`; that is how a service's `make docker-run` sends telemetry to `lgtm:4318`.

`make down` stops everything and keeps the databases. `docker compose down --volumes` also
deletes them. Telemetry is kept only while `lgtm` runs.

## Services

| Service | Host port | Database | Cache |
|---|---|---|---|
| none yet | | | |

How to add one: [docs/adding-a-service.md](docs/adding-a-service.md).

## Layout

| Path | What |
|---|---|
| `compose.yaml` | the platform containers, and the services once they run here |
| `scripts/db-add.sh` | `make db-add`: user and database per service |
| `docs/adding-a-service.md` | database, compose entries with the `<service>-migrate` job, contract |
| `docs/adr/` | architecture decisions that span services |
| `contracts/openapi/` | OpenAPI document of each service |
| `AGENTS.md` | rules for coding agents and humans |
