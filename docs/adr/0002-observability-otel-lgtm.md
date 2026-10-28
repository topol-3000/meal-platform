# 0002. OpenTelemetry everywhere, Grafana LGTM locally, Langfuse for LLM calls

- Status: Accepted (2026-10-25)
- Deciders: Yevhenii

## Context

Observability is a primary goal. The MVP must show one user action (import → plan → list)
as a single trace across services. LLM calls need their own view: prompts, outputs,
latency, token counts, evals.

## Decision

- Services use the OpenTelemetry SDK for traces, metrics and logs and export over OTLP/HTTP.
  FastAPI and httpx are auto-instrumented; use cases and LLM calls get manual spans.
  HTTP metrics follow the stable semantic conventions (`http.server.request.duration`).
- Logs are written with structlog: JSON to stdout with `trace_id`/`span_id`, and the same
  records are exported over OTLP so Loki links logs to traces.
- Locally, `grafana/otel-lgtm` (Collector, Tempo, Loki, Prometheus, Pyroscope, Grafana)
  receives everything in one container.
- LLM calls are additionally sent to Langfuse (self-hosted) for prompt and quality analysis.
- All of this is in `meal-service-template` so every service gets it by default.

## Alternatives

- **Separate Collector, Tempo, Loki, Prometheus containers.** Closer to production but many
  configs to maintain for a dev setup; can come later for alerting (stage 4).
- **Jaeger + Prometheus only.** No log correlation in one UI.
- **LLM traces only in Tempo.** Possible with GenAI semantic conventions, but no prompt
  management, datasets or eval scoring.

## Consequences

- One trace per user action requires trace context in event messages (ADR 0003).
- `otel-lgtm` is for development only; production would need a real backend.
- Langfuse brings ClickHouse, MinIO and its own Redis; it sits behind the `langfuse`
  compose profile so the core stack stays light.
