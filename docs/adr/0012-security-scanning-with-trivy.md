# 0012. Security scanning with Trivy in every service's CI

- Status: Accepted (2026-10-26)
- Deciders: Yevhenii

## Context

Each service ships a Docker image built from a Python base image and a `uv.lock` with
dozens of packages. Vulnerabilities appear after a service is written, so a scan that
only runs on change misses them. The reference project installed Trivy with `curl | sh`
from the `main` branch.
Decision D8 of the template's [architecture plan](https://github.com/topol-3000/meal-service-template/blob/main/docs/plans/architecture-guidelines.md).

## Decision

Every service's CI runs two Trivy scans with `aquasecurity/trivy-action`, pinned by commit:
a filesystem scan (vulnerabilities in `uv.lock` including dev dependencies, secrets,
misconfigurations) and a scan of the image between its build and its push. A `CRITICAL`
or `HIGH` finding with a fix fails the build. CI runs on pull requests, pushes to main
and weekly. Findings are fixed, not ignored; `.trivyignore` holds only findings without a
fix, each with a reason and an `exp:` review date. The template repository runs the same
scans on every variant.

## Alternatives

- **The reference project's setup** (`curl | sh` from `main`). Unpinned, so a
  compromised release runs in CI; the action's tags were in fact rewritten in a 2026-03
  supply chain attack, hence the commit pin.
- **A separate `uv.lock` audit** (pip-audit and similar). Trivy already reads every package
  in `uv.lock`, so it would report the same thing twice.
- **A separate `trivy.yml` workflow.** It would build the image a second time and couldn't
  stop the push.

## Consequences

- The weekly run can fail with no code change; that is the point.
- The runtime image has no pip (its vendored packages had fixable `HIGH` findings and the
  app never uses it).
- License scanning is not decided yet (the plan's Q9).
