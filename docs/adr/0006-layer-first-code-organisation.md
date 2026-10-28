# 0006. Layer-first code organisation with ports and adapters

- Status: Accepted (2026-10-26)
- Deciders: Yevhenii

## Context

Every service is generated from meal-service-template, and coding agents write most of the
code. They need one predictable answer to "where does this go?", and a wrong import should
fail the build rather than wait for review. The reference project (`fastapi-boilerplate`)
contributed the level of detail (per-layer rules, an "adding a module" guide), not its layout.
Decision D1 of the template's [architecture plan](https://github.com/topol-3000/meal-service-template/blob/main/docs/plans/architecture-guidelines.md).

## Decision

We organise each service by layer: `domain/` (entities, value objects, errors, ports as
`typing.Protocol`), `application/` (use cases), `infrastructure/` (adapters implementing
the ports) and `api/` (routers, schemas, dependency providers). The dependency rule is
`api → application → domain ← infrastructure`; `domain` and `application` import no
framework or client library. Once a service has more than one aggregate, each layer gets
feature subfolders (`domain/recipes/`, `application/recipes/`, ...).

The rule is enforced by import-linter contracts in `make check`, not by review.

## Alternatives

- **Feature-first (vertical slices):** `recipes/` holding its router, use cases and
  repository. A feature stays in one folder, but the dependency rule can't be expressed as
  a few layer contracts, and each slice draws its own boundaries.
- **Technical modules without ports** (`controllers/`, `services/`, `models/`). Fewer
  folders, but business logic calls the ORM and HTTP clients directly, so it can't be
  tested or have an adapter replaced without them.

## Consequences

- A feature touches several folders; the template's `AGENTS.md` table and the
  `add-feature` skill say which file goes where.
- Use cases are tested with in-memory fakes of their ports, without a framework or Docker.
- An adapter can be replaced (another LLM, another HTTP API) without touching use cases.
- Revisit if the layer split costs more than it saves in services that stay very small.
