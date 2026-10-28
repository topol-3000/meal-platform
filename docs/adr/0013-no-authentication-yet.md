# 0013. No authentication in the template yet

- Status: Accepted (2026-10-26)
- Deciders: Yevhenii

## Context

The MVP is one family using a Telegram bot, and every service runs locally behind
`127.0.0.1`. Auth is out of MVP scope (see the roadmap in `AGENTS.md`). The reference
project used `python-jose` for JWTs.
Decision D9 of the template's [architecture plan](https://github.com/topol-3000/meal-service-template/blob/main/docs/plans/architecture-guidelines.md).

## Decision

The template has no authentication code, docs or library choice. The first service that
needs auth (the bot's Telegram users, meal-web, or exposing a service beyond localhost)
gets its own plan and a new ADR first.

## Alternatives

- **Pick a library now** (`python-jose`, as in the reference project). It would be chosen
  before knowing who authenticates whom (users, the bot, service to service), and every
  service would carry it unused.
- **Auth as a template option** (like `with_database`). The same choice made early, plus
  one more variant for CI and the docs checkers to cover.

## Consequences

- Nothing protects a service's API yet, so services stay on localhost (meal-platform
  publishes ports on `127.0.0.1` only) until that decision is made.
- `docs/stack.md` lists no auth library; agents ask before adding one.
