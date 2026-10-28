# 0014. Optional cache: Valkey through redis-py

- Status: Accepted (2026-10-26)
- Deciders: Yevhenii

## Context

Some lookups are slow (another service over HTTP, the LLM), and a cache helps. Not every
service needs one. The
client must join the app's traces like every other I/O. Valkey is the BSD-licensed fork of
Redis, which moved away from BSD.
Decision D10 of the template's [architecture plan](https://github.com/topol-3000/meal-service-template/blob/main/docs/plans/architecture-guidelines.md).

## Decision

The cache is a template option, `with_cache` (default `false`). The server is Valkey
(BSD-3, Linux Foundation); the client is redis-py's `redis.asyncio`, traced by
`opentelemetry-instrumentation-redis`. All cache calls go through one adapter in
`infrastructure/cache/`, and features wrap it behind their own ports.

The cache is an optimisation, never the source of truth: cache-aside only, every write has
a TTL, a cache error counts as a miss (logged once as `cache.unavailable`, the request
continues), and `/health/ready` does not check it.

## Alternatives

- **valkey-py.** The Valkey fork of redis-py, but without OpenTelemetry instrumentation and
  with slow releases.
- **Valkey GLIDE.** Its Python client exports OpenTelemetry separately and can't attach
  its spans to the app's trace.
- **Redis 8.** Works with the same client, but its extras aren't needed and Valkey stays
  BSD-licensed. (Langfuse's own Redis in meal-platform compose is Langfuse's choice, not a
  service cache.)

## Consequences

- The client can be swapped in one file. We revisit it when GLIDE's Python client accepts a
  parent span context, or if redis-py stops working with Valkey.
- A Valkey outage slows requests by at most the timeout per call (0.5 s by default) and
  never fails them.
- The TTL bounds staleness, also when an invalidation fails.
