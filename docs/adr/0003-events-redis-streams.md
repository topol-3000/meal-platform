# 0003. Long-running operations as events over Redis Streams, trace context in message fields

- Status: Superseded by [0005](0005-http-between-services.md) (2026-10-28); accepted 2026-10-25
- Deciders: Yevhenii

## Context

Recipe import (HTTP fetch + LLM) and plan generation (LLM) take seconds to minutes.
The Telegram bot must not block on them. Load is one family; operational simplicity matters
more than throughput.

## Decision

- Reads between services are synchronous HTTP.
- Long operations are events on Redis Streams, one stream per event type
  (`recipe.import.requested`, `recipe.imported`, `plan.requested`, `plan.generated`,
  `plan.accepted`, `shopping_list.ready`). Each consuming service uses its own consumer group.
- Every message uses the envelope in `contracts/events/schemas/envelope.schema.json`,
  including W3C `traceparent`/`tracestate`. Producers create a PRODUCER span and inject the
  context; consumers create a CONSUMER span with the extracted context as parent.
- Handlers are idempotent by `event_id`.

## Alternatives

- **RabbitMQ / Kafka / NATS.** More features (DLQ, routing, replay at scale), another
  system to run. Redis is already needed for caching.
- **Celery / arq task queues.** Couples producer to consumer code and hides the event model.
- **Span links instead of parent/child.** More correct for fan-out, but the MVP flow is a
  chain and parent/child gives the single readable trace that is the MVP goal.

## Consequences

- No built-in dead letter queue: poison messages are logged as `event.rejected` and acked;
  pending entries are reclaimed with `XAUTOCLAIM`.
- Redis runs with AOF and `noeviction` so streams are not lost or evicted.
- Revisit when we need replay across many consumers or business-mode load.
