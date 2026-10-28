# AGENTS.md: meal-platform

**FamilyMeal** is a family meal planner: an LLM builds a 3–7 day batch-cooking menu
("cook once, eat for several days") from a recipe catalog, recipes are imported by URL,
and a shopping list is built from the accepted plan. Later: a mode for small meal-prep businesses.

This repository is the local platform and the home of everything that crosses a service
boundary. It runs what every `meal-*` service needs on a laptop, and holds the HTTP
contracts between services, the architecture decisions (ADRs), and later the end-to-end
tests (`e2e/`) and LLM evals (`evals/`). It owns **no business code**: services live in
their own repositories, generated from **meal-service-template**, and are checked out next
to this one (`../meal-recipes`).

## System map

| Repo | Responsibility | Database |
|---|---|---|
| meal-service-template | copier template for every service | |
| meal-platform | this repo | |
| meal-recipes | recipe catalog; import by URL (schema.org Recipe JSON-LD first, LLM fallback); ingredient normalization | `meal_recipes` |
| meal-planner | family, plan, CookSession (batch cooking), feedback | `meal_planner` |
| meal-shopping | shopping list, aggregation by ingredient and store department | `meal_shopping` |
| meal-bot | Telegram: `/import <url>`, `/plan`, `/list` | none |
| meal-web | frontend (stage 5) | |

- Services call each other over HTTP; the httpx2 instrumentation carries the trace
  context, so one user action is one trace. No event bus: a service that needs
  asynchronous work gets a plan and an ADR first ([ADR 0005](docs/adr/0005-http-between-services.md)).
- Each service has its own database and never reads another service's tables.
- LLM: Ollama, local, behind a port in each service's domain; structured output parsed into
  Pydantic, calls traced in Langfuse too. The planner only picks recipes that exist in the catalog.

## Commands

| Task | Command |
|---|---|
| Start the core and the profiles in `.env` (creates `.env` first; returns when healthy) | `make up` |
| Stop (keeps the volumes) | `make down` |
| Status / logs | `make ps` / `make logs [s=postgres]` |
| Database and user for a service (idempotent) | `make db-add name=meal-recipes` |
| psql as the superuser | `make psql [db=meal_recipes]` |
| Pull the LLM named in `.env` (profile `ai`) | `make models` |
| Check a service's traces, logs and metrics in Grafana | `make check-telemetry s=meal-recipes` |
| Validate the compose files and JSON contracts | `make lint` |
| Delete all local data (databases, models, Langfuse) | `docker compose down --volumes` (ask first) |

## What runs

| Service | Profile | On the host | In the `meal-platform` network |
|---|---|---|---|
| Grafana + OTLP (`lgtm`) | core | Grafana `localhost:3000`, OTLP HTTP `localhost:4318`, gRPC `4317` | `lgtm:4318` |
| PostgreSQL 18 | core | `localhost:5432`, superuser `postgres`/`postgres` | `postgres:5432` |
| Valkey 9 | core | `localhost:6379` | `valkey:6379` |
| Ollama | `ai` | `localhost:11434` | `ollama:11434` |
| Langfuse | `langfuse` | `localhost:3001`, login from `.env` | `langfuse-web:3000` |

Profiles are switched on by `COMPOSE_PROFILES` in `.env` (both by default); the GPU for
Ollama comes from `compose.gpu.yaml` in `COMPOSE_FILE`. Langfuse brings its own ClickHouse,
MinIO and Redis; its database `langfuse` lives in the shared PostgreSQL and is created by
the `langfuse-db` job on every start.

Grafana's datasource uids are `tempo`, `loki` and `prometheus`. Telemetry and the cache are
not persisted; PostgreSQL (`postgres18_data`), Ollama's models and Langfuse keep their data
in volumes.

## Adding a service

Use the `add-service` skill. In short:

1. `make db-add name=<service>` (only with `with_database`): user, password and database
   all named after the package (`meal_recipes`), as in the service's `.env.example`.
2. To run it here: a `<service>` and a `<service>-migrate` entry in `compose.yaml` sharing
   one `services/<service>.env`, a host port and a row in the README's service table.
3. Its OpenAPI copy in `contracts/openapi/<service>.json`, and a row in the system map above.

Step by step, with the compose snippet: [docs/adding-a-service.md](docs/adding-a-service.md).

## Rules

- **Generated services depend on these names.** Grafana on 3000 with the uids above, OTLP
  on 4318, the network `meal-platform` with `lgtm`, `postgres` and `valkey` in it, ports
  5432 and 6379, and the `DB__URL` naming of `make db-add` are used by the template's
  `Makefile`, `.env.example` and skills. Change them only together with meal-service-template.
- **Pin every image to a tag**, never `latest` (the one exception, Langfuse's MinIO, says
  why in `compose.yaml`). The PostgreSQL and Valkey tags must equal `POSTGRES_IMAGE` and
  `VALKEY_IMAGE` in the template's `tests/conftest.py.jinja`; bump both repositories in
  step. Bump versions in a change of their own.
- **A database per service, owned by its user.** Create it with `make db-add`, never by hand.
  No service gets access to another service's database: services talk over HTTP.
- **Migrations run as the `<service>-migrate` job** from the service's image
  (`python -m <package> migrate`), never in the app's entrypoint. The app waits on it with
  `condition: service_completed_successfully`, and both use the same `env_file`.
- **Contracts change with the API.** A change to a service's HTTP API updates its file in
  `contracts/openapi/` in the same PR series as the service change, linked from both PRs.
- **Decisions that are hard to reverse or span services are ADRs** in `docs/adr/`, written
  first (`write-adr` skill). An accepted ADR is not rewritten; a new one supersedes it.
- **Local only.** Ports are published on `127.0.0.1`, the credentials are the
  `.env.example` ones, and no real secret is ever committed here (`.env` is ignored).
- **Ask before** changing a port, name or image tag above, adding a platform component, or
  deleting volumes.

## Roadmap

0. Template and platform, empty service with traces in Grafana (current)
1. recipes: import
2. planner: plan generation
3. shopping + bot: end-to-end slice (MVP: one family, import → 3-day plan, lunch and dinner → list in Telegram, one trace)
4. evals in CI, dashboards, alerts
5. meal-web
6. pantry, prices and promotions, business mode

Out of MVP scope: auth, pantry, supermarket prices, YouTube import, frontend, B2B.
