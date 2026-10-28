# 0011. Integration tests against real PostgreSQL and Valkey in testcontainers

- Status: Accepted (2026-10-26)
- Deciders: Yevhenii

## Context

Repositories, migrations and the cache adapter only work if they work against the real
server: SQL dialect, transactions, constraint names, Valkey's errors and timeouts. Tests
should run the same way on a laptop and in CI, without depending on what is running locally.
Decision D7 of the template's [architecture plan](https://github.com/topol-3000/meal-service-template/blob/main/docs/plans/architecture-guidelines.md),
extended to Valkey with D10.

## Decision

Integration tests start their own containers with testcontainers: one PostgreSQL (migrated
once) and one Valkey per test session. Each database test runs in a transaction that is
rolled back; the cache is flushed after each test. These tests are marked
`@pytest.mark.integration`. `make test` (and so `make check` and CI) runs everything;
`make test-unit` skips them. Everything above the adapters is tested with in-memory fakes.

## Alternatives

- **SQLite in memory.** No Docker, but another SQL dialect and no asyncpg, so the tests
  pass for code that fails on PostgreSQL.
- **The platform's PostgreSQL and Valkey.** Tests would depend on `make up`, on local data
  and on each other's leftovers.
- **CI service containers.** Only exist in CI, so tests can't run locally the same way.
- **Mocking the session or client.** Tests the calls made, not whether the query works.

## Consequences

- `make test` needs Docker for services with `with_database` or `with_cache`.
- The test images (`POSTGRES_IMAGE`, `VALKEY_IMAGE` in `tests/conftest.py`) must match the
  images in meal-platform compose; both repositories are bumped together.
- The first integration test of a session pays for the container start-up.
