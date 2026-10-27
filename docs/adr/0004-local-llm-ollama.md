# 0004. Local LLM via Ollama, behind a domain port, structured output into Pydantic

- Status: Accepted (2026-10-25)
- Deciders: Yevhenii

## Context

The LLM parses recipes when JSON-LD is missing, normalizes ingredients, and composes plans.
Development runs on an RTX 4080 SUPER (16 GB VRAM). Costs should stay at zero and the
provider should be swappable.

## Decision

- Ollama runs locally (compose profile `ai`, GPU via `compose.gpu.yaml`).
- Each service defines the LLM capability it needs as a port (Protocol) in its domain;
  an Ollama adapter in infrastructure implements it.
- Output is always requested as JSON matching a Pydantic model's JSON Schema and validated;
  invalid output is retried a bounded number of times, then fails loudly.
- The planner may only choose recipes that exist in the catalog: it receives candidate ids
  and the result is validated against them.
- The default model is set in `.env` (`OLLAMA_MODEL`); model choice is driven by evals.

## Alternatives

- **Hosted APIs (OpenAI, Anthropic).** Better quality, but cost and data leave the machine.
  The port keeps this option open for a later comparison in evals.
- **LLM frameworks (LangChain, LlamaIndex).** Too much abstraction for a few structured calls.

## Consequences

- Quality depends on a ~14B local model, so evals (parsing on reference URLs; plans: no
  disliked products, within shelf life, variety, portions add up) are essential.
- CI cannot run the real model; unit tests use fakes, evals run on the dev machine
  (and in CI later, stage 4).
