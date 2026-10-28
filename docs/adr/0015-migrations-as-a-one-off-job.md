# 0015. Database migrations run as a one-off job from the service image

- Status: Accepted (2026-10-26)
- Deciders: Yevhenii

## Context

A service with a database (ADR 0008) must apply its Alembic migrations before a new
version serves traffic, locally in compose and later in a real deployment, possibly with
several replicas.
Decision D11 of the template's [architecture plan](https://github.com/topol-3000/meal-service-template/blob/main/docs/plans/architecture-guidelines.md).

## Decision

Migrations ship inside the package (`infrastructure/db/migrations/`). A one-off job from
the service image runs `python -m <package> migrate` before the new version starts: in
compose a `<service>-migrate` service that the app waits on with
`condition: service_completed_successfully`; in Kubernetes an init container or a
pre-upgrade Job. A PostgreSQL advisory lock serialises concurrent runs. Migrations are
written expand-then-contract, so each one works with the release that is still running.
The job gets the service's whole environment (the same `env_file`), because it loads the
same `Settings` (ADR 0009).

## Alternatives

- **In the container's entrypoint.** Replicas race to migrate, and a failed migration
  becomes a crash loop.
- **From CI.** CI would need database credentials and network access to every environment.

## Consequences

- A failed migration stops the start instead of taking the service down in a loop.
- Every schema change needs two releases when it removes or renames something.
- `CREATE INDEX CONCURRENTLY` and similar steps need `autocommit_block()`, which also
  releases the advisory lock; the template's persistence doc covers it.
