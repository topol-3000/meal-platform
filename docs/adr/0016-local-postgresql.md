# 0016. Local PostgreSQL 18: one server, a database and a user per service

- Status: Accepted (2026-10-26)
- Deciders: Yevhenii

## Context

Each service owns its database and never reads another's tables (ADR 0001). Locally,
several services need PostgreSQL at once on one laptop, and a service's `.env.example`
should work as is. The Stage 0 platform created databases with an init script, which runs
only on an empty volume, and used PostgreSQL 17.
Decisions D12 and D13 of the template's [architecture plan](https://github.com/topol-3000/meal-service-template/blob/main/docs/plans/architecture-guidelines.md).

## Decision

meal-platform compose runs one PostgreSQL 18 on `localhost:5432`. Each service gets its own
database and user, both named after the package (`meal_recipes`, password the same), made
by `make db-add name=<service>`. It can be run again, works on an existing volume and
revokes `CONNECT` from `PUBLIC`, so only the owner can open the database. Tests don't use it
(ADR 0011).

PostgreSQL 18, because 19 was still a release candidate in 2026-10; we move after its first
minor releases. The compose tag is the reference, and the template's `POSTGRES_IMAGE` must
match it.

## Alternatives

- **A PostgreSQL container per service.** Stronger isolation, but more memory, more ports
  and more to keep in step, for the same guarantee `REVOKE CONNECT` gives locally.
- **One database with a schema per service.** One connection string, but reading another
  service's tables is one `search_path` away.
- **Init scripts** (Stage 0). Run only on a fresh volume, so a new service needs a manual
  step or a wiped volume.

## Consequences

- A new service with a database runs `make db-add` once; the `add-service` skill says so.
- A major version upgrade gets a new volume (`postgres18_data`), with a dump and restore if
  the local data matters.
- Image tags are bumped in meal-platform and the template together.
