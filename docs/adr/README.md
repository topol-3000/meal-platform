# Architecture decision records

Decisions that hold for more than one service, or for the platform itself: the stack, how
services are built, deployed and talk to each other. A decision inside one service belongs
in that service's repository.

One file per decision, numbered in order (`NNNN-<kebab-title>.md`). Each says the
context, the decision, the alternatives, its consequences and its status (proposed,
accepted, superseded by NNNN). An accepted ADR is not rewritten: a new one supersedes it.

| # | Decision | Status |
|---|---|---|
| [0001](0001-multirepo-microservices.md) | Microservices in separate repos, generated from a copier template | Accepted |
| [0002](0002-observability-otel-lgtm.md) | OpenTelemetry, Grafana LGTM locally, Langfuse for LLM | Accepted |
| [0003](0003-events-redis-streams.md) | Long operations as Redis Streams events with trace context | Superseded by 0005 |
| [0004](0004-local-llm-ollama.md) | Local LLM via Ollama behind a port, Pydantic structured output | Accepted |
| [0005](0005-http-between-services.md) | Services talk over HTTP; no event bus for now | Accepted |
| [0006](0006-layer-first-code-organisation.md) | Layer-first code organisation with ports and adapters | Accepted |
| [0007](0007-dataclass-domain-models.md) | Domain models are frozen dataclasses; Pydantic only at boundaries | Accepted |
| [0008](0008-postgresql-sqlalchemy-optional.md) | PostgreSQL through SQLAlchemy async, asyncpg and Alembic; optional per service | Accepted |
| [0009](0009-configuration-from-environment.md) | Configuration from environment variables only | Accepted |
| [0010](0010-dependency-injection-without-framework.md) | Dependency injection without a framework | Accepted |
| [0011](0011-integration-tests-with-testcontainers.md) | Integration tests against real PostgreSQL and Valkey in testcontainers | Accepted |
| [0012](0012-security-scanning-with-trivy.md) | Security scanning with Trivy in every service's CI | Accepted |
| [0013](0013-no-authentication-yet.md) | No authentication in the template yet | Accepted |
| [0014](0014-optional-valkey-cache-with-redis-py.md) | Optional cache: Valkey through redis-py | Accepted |
| [0015](0015-migrations-as-a-one-off-job.md) | Database migrations run as a one-off job from the service image | Accepted |
| [0016](0016-local-postgresql.md) | Local PostgreSQL 18: one server, a database and a user per service | Accepted |
| [0017](0017-no-license-scanning.md) | No license scanning | Accepted |

New ADR: see the `write-adr` skill, template in [0000-template.md](0000-template.md).
