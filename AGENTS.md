# AGENTS.md: meal-platform

**FamilyMeal** is a family meal planner: an LLM builds a 3–7 day batch-cooking menu
("cook once, eat for several days") from a recipe catalog, recipes are imported by URL,
and a shopping list is built from the accepted plan. Later: a mode for small meal-prep businesses.

This repository is the glue between services. It owns:

- `compose.yaml`: local infrastructure (Postgres, Redis, Grafana LGTM, Ollama, Langfuse)
- `contracts/`: OpenAPI copies of every service API and event schemas (the source of truth for events)
- `docs/adr/`: architecture decision records
- `e2e/`: end-to-end tests across services (from stage 3)
- `evals/`: LLM quality evaluations (recipe parsing, plan generation)

It owns **no business code**. Services live in their own repos generated from
`meal-service-template`.

## System map

| Repo | Responsibility | DB |
|---|---|---|
| meal-service-template | copier template for every service | |
| meal-platform | this repo | |
| meal-recipes | recipe catalog; import by URL (schema.org Recipe JSON-LD first, LLM fallback); ingredient normalization | `recipes` |
| meal-planner | family, plan, CookSession (batch cooking), feedback | `planner` |
| meal-shopping | shopping list, aggregation by ingredient and store department | `shopping` |
| meal-bot | Telegram: `/import <url>`, `/plan`, `/list` | none |
| meal-web | frontend (stage 5) | |

Communication:

- Reads: synchronous HTTP between services (traced by httpx instrumentation).
- Long operations: Redis Streams events, one stream per event type:
  `recipe.import.requested → recipe.imported`, `plan.requested → plan.generated`,
  `plan.accepted → shopping_list.ready`. W3C trace context travels in message fields,
  so one user action is one trace across services (ADR 0003).
- Each service has its own database and never reads another service's tables.
- LLM: Ollama, local, behind a port in each service's domain; structured output parsed into
  Pydantic. The planner only picks recipes that exist in the catalog.

## Commands

| Task | Command |
|---|---|
| First run | `make up` (creates `.env` from `.env.example`) |
| Pull the LLM | `make models` |
| Status / logs | `make ps`, `make logs s=lgtm` |
| Check a service's telemetry | `make check-telemetry s=meal-recipes` |
| Validate compose and JSON schemas | `make lint` |
| Stop / wipe all data | `make down` / `make nuke` (ask before running `nuke`) |

Endpoints: Grafana http://localhost:3000, Langfuse http://localhost:3001,
OTLP http://localhost:4318 (`http://lgtm:4318` inside the `meal-platform` network),
Postgres `localhost:5432` (role = db = password = service name, dev only),
Redis `localhost:6379`, Ollama http://localhost:11434.

## Rules

- Infrastructure versions are pinned (no `latest`). Bump them in a dedicated change.
- Everything binds to `127.0.0.1`. Secrets in `.env` only; `.env.example` holds dev defaults.
- A new service: use the `add-service` skill (database, compose wiring, contracts).
- A decision that is hard to reverse or affects several services needs an ADR first
  (`write-adr` skill). ADRs are immutable once accepted; supersede them with a new one.
- Event contracts: additive changes only within a version. Breaking change means a new
  `event_version` and a period when consumers accept both.
- Contract changes go in the same PR series as the producing service change, and are
  linked from both PRs.

## Roadmap

0. Template and platform, empty service with traces in Grafana (current)
1. recipes: import
2. planner: plan generation
3. shopping + bot: end-to-end slice (MVP: one family, import → 3-day plan, lunch and dinner → list in Telegram, one trace)
4. evals in CI, dashboards, alerts
5. meal-web
6. pantry, prices and promotions, business mode

Out of MVP scope: auth, pantry, supermarket prices, YouTube import, frontend, B2B.
