# AGENTS.md: meal-platform

The local platform of **FamilyMeal** and the home of everything that crosses a service
boundary. It runs what every `meal-*` service needs on a laptop (Grafana with Tempo, Loki
and Prometheus, PostgreSQL, Valkey), and holds the HTTP contracts between services and the
architecture decisions (ADRs). Services live in their own repositories, generated from
**meal-service-template**, and are checked out next to this one (`../meal-recipes`).

## Commands

| Task | Command |
|---|---|
| Start everything (returns when healthy) | `make up` |
| Stop (keeps the PostgreSQL volume) | `make down` |
| Status / logs | `make ps` / `make logs [s=postgres]` |
| Database and user for a service (idempotent) | `make db-add name=meal-recipes` |
| psql as the superuser | `make psql [db=meal_recipes]` |
| Delete all local data | `docker compose down --volumes` (ask first) |

## What runs

| Service | Image | On the host | In the `meal-platform` network |
|---|---|---|---|
| Grafana + OTLP (`lgtm`) | `grafana/otel-lgtm` | Grafana `localhost:3000`, OTLP HTTP `localhost:4318`, gRPC `4317` | `lgtm:4318` |
| PostgreSQL | `postgres:18-alpine` | `localhost:5432`, superuser `postgres`/`postgres` | `postgres:5432` |
| Valkey | `valkey/valkey:9` | `localhost:6379` | `valkey:6379` |

Grafana's datasource uids are `tempo`, `loki` and `prometheus`. Telemetry and the cache are
not persisted; PostgreSQL keeps its data in the `postgres-data` volume.

## Adding a service

1. `make db-add name=<service>` (only with `with_database`): user, password and database
   all named after the package (`meal_recipes`), as in the service's `.env.example`.
2. To run it here: a `<service>` and a `<service>-migrate` entry in `compose.yaml` sharing
   one `services/<service>.env`, a host port and a row in the README's service table.
3. Its OpenAPI copy in `contracts/openapi/<service>.json`.

Step by step, with the compose snippet: [docs/adding-a-service.md](docs/adding-a-service.md).

## Rules

- **Generated services depend on these names.** Grafana on 3000 with the uids above, OTLP
  on 4318, the network `meal-platform` with `lgtm`, `postgres` and `valkey` in it, ports
  5432 and 6379, and the `DB__URL` naming of `make db-add` are used by the template's
  `Makefile`, `.env.example` and skills. Change them only together with meal-service-template.
- **Pin every image to a tag**, never `latest`. The PostgreSQL and Valkey tags must equal
  `POSTGRES_IMAGE` and `VALKEY_IMAGE` in the template's `tests/conftest.py.jinja`; bump both
  repositories in step.
- **A database per service, owned by its user.** Create it with `make db-add`, never by hand.
  No service gets access to another service's database: services talk over HTTP.
- **Migrations run as the `<service>-migrate` job** from the service's image
  (`python -m <package> migrate`), never in the app's entrypoint. The app waits on it with
  `condition: service_completed_successfully`, and both use the same `env_file`.
- **Contracts change with the API.** A change to a service's HTTP API updates its file in
  `contracts/openapi/` in the same change.
- **Decisions that span services are ADRs** in `docs/adr/`.
- **Local only.** Ports are published on `127.0.0.1`, the credentials are the
  `.env.example` ones, and no real secret is ever committed here.
- **Ask before** changing a port, name or image tag above, adding a platform component, or
  deleting volumes.
