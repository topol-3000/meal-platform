# meal-platform

Local platform for **FamilyMeal**, a family meal planner built as a set of small Python
`meal-*` services, and the place for what they share: HTTP contracts and architecture
decisions. Services are generated from
[meal-service-template](https://github.com/topol-3000/meal-service-template).

## Quick start

Needs Docker Engine 25+ with Compose v2.

```bash
make up                            # creates .env, starts everything, waits until healthy
make models                        # pull the Ollama model named in .env
make db-add name=meal-recipes      # a database and user for a service, safe to repeat
make help                          # everything else
```

Then in the service: `cp .env.example .env && make migrate && make run`.

`make up` starts the core (Grafana LGTM, PostgreSQL, Valkey) and the profiles listed in
`COMPOSE_PROFILES` in `.env`: `ai` (Ollama) and `langfuse`, both on by default. Without an
NVIDIA GPU, remove `compose.gpu.yaml` from `COMPOSE_FILE` in `.env`. On Windows run from
WSL2, or use `;` as the separator in `COMPOSE_FILE`.

| What | Where |
|---|---|
| Grafana (Tempo, Loki, Prometheus) | <http://localhost:3000>, no login |
| OTLP | `http://localhost:4318` (HTTP), `localhost:4317` (gRPC) |
| PostgreSQL 18 | `localhost:5432`, superuser `postgres` / `postgres` |
| Valkey 9 | `localhost:6379` |
| Ollama (profile `ai`) | <http://localhost:11434> |
| Langfuse (profile `langfuse`: LLM traces, prompts, evals) | <http://localhost:3001>, `admin@familymeal.local` / `familymeal` |

Containers in the `meal-platform` Docker network reach them as `lgtm`, `postgres`,
`valkey` and `ollama`; that is how a service's `make docker-run` sends telemetry to
`lgtm:4318`. To see a service in Grafana: `make docker-run` in its repository, call any
endpoint, then `make check-telemetry s=<service>` here.

`make down` stops everything and keeps the volumes (databases, Ollama models, Langfuse).
`docker compose down --volumes` also deletes them. Telemetry is kept only while `lgtm` runs.

## Services

| Service | Host port | Database | Cache |
|---|---|---|---|
| none yet | | | |

How to add one: [docs/adding-a-service.md](docs/adding-a-service.md).

## Layout

| Path | What |
|---|---|
| `compose.yaml`, `compose.gpu.yaml` | the platform containers (and the GPU for Ollama), and the services once they run here |
| `scripts/db-add.sh` | `make db-add`: user and database per service |
| `scripts/check-telemetry.sh` | `make check-telemetry`: a service's traces, logs and metrics reached Grafana |
| `postgres/langfuse-db.sql` | Langfuse's user and database, run by the `langfuse-db` job |
| `docs/adding-a-service.md` | database, compose entries with the `<service>-migrate` job, contract |
| `docs/adr/` | architecture decisions that span services |
| `contracts/openapi/` | OpenAPI document of each service |
| `e2e/`, `evals/` | end-to-end tests (stage 3) and LLM evals (stage 1 on) |
| `AGENTS.md` | system map and rules for coding agents and humans |
