# 0009. Configuration from environment variables only

- Status: Accepted (2026-10-26)
- Deciders: Yevhenii

## Context

Services run on a laptop (`make run`), in meal-platform compose and later somewhere real.
Configuration must look the same in all three, fail early when something is missing, and
keep secrets out of logs. The reference project read secrets from a Vault service.
Decision D4 of the template's [architecture plan](https://github.com/topol-3000/meal-service-template/blob/main/docs/plans/architecture-guidelines.md).

## Decision

All configuration comes from environment variables (and a local `.env`), read once by a
pydantic-settings `Settings` class. Each adapter has a frozen sub-model, read with
`__` as the delimiter (`DB__URL`, `CACHE__URL`); service-wide values stay flat
(`LOG_LEVEL`). Values without a safe default are required, so a missing one stops startup
and names the field; secrets are `SecretStr`. `get_settings()` is called only in the
composition root; each component receives its own slice. Every variable is listed in
`.env.example` with a comment.

Vault is deferred. When it comes, it becomes a settings source, not a service the code calls.

## Alternatives

- **Config files per environment** (YAML or TOML). A second source next to the
  environment, and files that drift apart between environments.
- **Vault now** (the reference project). Real secret management, but nothing needs it
  locally, and a Vault client in the code makes every component depend on it.

## Consequences

- Tests build `Settings(...)` directly; nothing reads the environment behind their back.
- A process that loads `Settings` needs the whole environment, including the migration job
  (ADR 0015).
- Existing flat variables stay flat to avoid a breaking change.
