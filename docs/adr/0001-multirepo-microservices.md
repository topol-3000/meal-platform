# 0001. Microservices in separate repositories, generated from one copier template

- Status: Accepted (2026-10-25)
- Deciders: Yevhenii

## Context

FamilyMeal is a pet project with two goals: a working product and practice of modern,
AI-assisted development (AGENTS.md, skills, MCP as a dev tool). The domain splits naturally
into recipes, planning, shopping and a Telegram bot. The project must stay small, and the
emphasis is on quality, logging, tracing, monitoring and integrations.

## Decision

We build independent services, each in its own repository (`meal-recipes`, `meal-planner`,
`meal-shopping`, `meal-bot`), all generated from `meal-service-template` with copier.
Cross-cutting pieces (local infrastructure, contracts, ADRs, e2e, evals) live in `meal-platform`.
Each service owns its database.

## Alternatives

- **Monorepo** (uv workspace). Simpler refactors across services and one CI, but it hides
  integration problems the project is meant to practice (versioned contracts, template drift,
  independent deploys), and agents get a larger, noisier context.
- **Modular monolith.** The right call for a real product of this size; rejected only because
  practicing distributed tracing and event-driven integration is an explicit goal.

## Consequences

- Shared tooling changes are made once in the template and pulled with `copier update`.
- Contracts must be explicit and versioned (`meal-platform/contracts`).
- More moving parts locally; `meal-platform` compose keeps that to one command.
- Revisit if keeping repos in sync costs more time than building features.
