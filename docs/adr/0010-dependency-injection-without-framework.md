# 0010. Dependency injection without a framework

- Status: Accepted (2026-10-26)
- Deciders: Yevhenii

## Context

Use cases receive their ports through `__init__` (ADR 0006), and something has to build
adapters, open resources with a lifetime (HTTP client, database engine, cache client) and
hand them to routes. The reference project used `dependency-injector` with wiring and
class-based views (`fastapi-class`), next to FastAPI's own dependency system.
Decision D5 of the template's [architecture plan](https://github.com/topol-3000/meal-service-template/blob/main/docs/plans/architecture-guidelines.md).

## Decision

We use no DI framework. `create_app()` in `main.py` is the composition root: it builds
settings, and its `lifespan` opens every resource inside one `AsyncExitStack`, closing
them in reverse order. The resources live in one typed `AppState` on `app.state`.
Providers in `api/dependencies.py` build adapters and use cases from it, exposed as typed
aliases (`type HttpClientDep = Annotated[httpx2.AsyncClient, Depends(get_http_client)]`).

## Alternatives

- **dependency-injector** (the reference project). A container with wiring is a second
  DI system next to FastAPI's, with global state that tests have to reset, and one more
  runtime dependency for what FastAPI's `Depends` already does.
- **A service locator or module-level singletons.** Simple, but hides dependencies, ties
  tests to global state and creates clients at import time.

## Consequences

- Adding a resource is four steps: a factory in `infrastructure/`, opened in `lifespan`,
  a field on `AppState`, a provider.
- Tests swap a use case or adapter with `app.dependency_overrides` on its provider.
- Everything is plain typed Python that pyright strict checks.
