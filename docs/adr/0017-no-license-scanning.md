# 0017. No license scanning

- Status: Accepted (2026-10-28)
- Deciders: Yevhenii

## Context

ADR 0012 added Trivy's vulnerability, secret and misconfiguration scans to every service's
CI and left license scanning open. The reference project ran Trivy's `license` scanner and
failed the build on `CRITICAL` and `HIGH`. On a rendered service (Trivy 0.70.0,
2026-10-27), the filesystem scan sees no licenses, because `uv.lock` records none. The
image scan reports 318 `HIGH` "restricted" (GPL/LGPL) and 174 "unknown" entries, all from
the Debian packages of the `python:3.14-slim` base image and none from Python packages.
Services run as network services and aren't distributed.
Decision D15 of the template's [architecture plan](https://github.com/topol-3000/meal-service-template/blob/main/docs/plans/architecture-guidelines.md).

## Decision

We don't scan licenses. Neither a service's CI nor the template's runs Trivy's `license`
scanner, failing or report-only, and no other tool checks licenses.

## Alternatives

- **The reference project's setting** (`CRITICAL,HIGH`, exit code 1). Fails every build on
  the base image's Debian packages, which we don't choose.
- **A report-only image scan.** Hundreds of base-image entries on every run, so in practice
  nobody would read it.
- **A failing scan of Python packages only, with an allowlist.** Would stop a copyleft
  dependency (AGPL, GPL) arriving through an upgrade, at the cost of a license policy to
  keep up, for a project that isn't distributed.

## Consequences

- Nothing stops a copyleft dependency, direct or transitive.
- Revisit if the code or the images are published, or with business mode (roadmap stage 6).
