# 0005. Services talk over HTTP; no event bus for now

- Status: Accepted (2026-10-26)
- Deciders: Yevhenii
- Supersedes: [0003](0003-events-redis-streams.md)

## Context

ADR 0003 planned long operations (recipe import, plan generation) as events on Redis
Streams, with trace context in message fields. While the template's architecture was built
(meal-service-template `docs/plans/architecture-guidelines.md`, D14), no service existed
that needed events yet, and supporting them meant every generated service would carry a
consumer loop, idempotency by `event_id`, reclaiming pending entries and a second way to
propagate trace context, all tested in every template variant. The cache also moved from
Redis to Valkey (D10), so a Redis for events is no longer there anyway. Load is one family.

## Decision

Services call each other over synchronous HTTP, through the template's shared httpx2
client, whose instrumentation carries W3C trace context, so one user action is still one
trace. Neither the template nor the platform has an event bus, stream consumers or
background workers (Redis/Valkey Streams, Celery). The first service that needs
asynchronous work gets its own plan and a new ADR before any code.

## Alternatives

- **Keep 0003 (Redis Streams).** The design was ready, but every service would carry the
  consumer machinery before any of them has a long operation to run.
- **A task queue (Celery, arq).** Couples producer to consumer code and hides the event
  model (the reason 0003 rejected it); it would also be the first worker process in a
  template that only serves HTTP.

## Consequences

- `contracts/events/` and the event envelope schema are removed; contracts are the
  OpenAPI documents in `contracts/openapi/`.
- The template has no `inject_trace_context` / `extract_trace_context` helpers and no
  `add-event-handler` skill.
- Valkey in the platform is a cache only: not persisted, and the `noeviction` and AOF
  settings that 0003 needed for streams are gone.
- A slow operation is a slow HTTP call, bounded by the caller's timeout.
- 0002's consequence "trace context in event messages" no longer applies, and the
  event-driven integration that 0001 named as a practice goal is deferred until a service
  needs it.
- Revisit when the first long operation is designed (stage 1, recipe import by URL with the
  LLM fallback, or the bot waiting on plan generation in stage 2).
