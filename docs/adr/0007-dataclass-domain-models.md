# 0007. Domain models are frozen dataclasses; Pydantic only at boundaries

- Status: Accepted (2026-10-26)
- Deciders: Yevhenii

## Context

A service has data in several shapes: request and response bodies, payloads from other
services and the LLM, table rows, cached values, and the business objects in between.
Using one model for all of them couples the API, the rules and storage, and brings a
validation framework into the domain, which ADR 0006 keeps framework-free.
Decision D2 of the template's [architecture plan](https://github.com/topol-3000/meal-service-template/blob/main/docs/plans/architecture-guidelines.md).

## Decision

We model entities and value objects as `@dataclass(frozen=True, slots=True)`, with
invariants checked in `__post_init__` raising domain errors. Pydantic is used only at
boundaries, where untrusted data enters or leaves: API schemas (subclassing `ApiModel`,
`extra="forbid"`), payloads of other services and of the LLM, cached values and
settings. Persistence models are SQLAlchemy classes. Mapping happens in exactly one place
per boundary: `to_domain()` / `from_domain()` on the API schema, the repository for rows.

## Alternatives

- **Pydantic everywhere.** One class per concept and free validation, but the API shape,
  the business rules and the stored shape then change together, and `domain` imports a
  framework.
- **ORM classes as domain objects** (SQLAlchemy or SQLModel). No mapping code, but the
  domain depends on the ORM, its sessions and lazy loading, and can't be tested without them.
- **attrs.** Equivalent to dataclasses here, as one more dependency.

## Consequences

- Each boundary has a little mapping code, written once.
- Domain objects never leave through HTTP directly, and API schemas never reach use cases.
- No invalid entity can be built, whatever the entry point (HTTP, a job, a test).
