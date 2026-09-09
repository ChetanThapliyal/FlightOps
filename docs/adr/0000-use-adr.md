# ADR-0000: Record Architecture Decisions

## Status

Accepted

## Date

2026-08-29

## Context

As FlightOps grows in complexity (spanning application code, Kubernetes manifests, Terraform modules, Helm charts, and CI/CD pipelines), architectural decisions risk becoming tribal knowledge. When a contributor (or future-self) asks *"why did we do it this way?"*, the answer shouldn't require to rummage through old commits or Slack threads.

We need a lightweight, version-controlled mechanism to capture the **why** behind significant technical decisions.

## Decision

We will use **Architecture Decision Records (ADRs)** as described by [Michael Nygard](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions).

Each ADR will:
- Live in `docs/adr/` as a numbered markdown file (`NNNN-short-title.md`).
- Structure should be: **Status**, **Date**, **Context**, **Decision**, **Consequences**.
- Should be immutable once accepted: if a decision is reversed, a new ADR supersedes it with a link back.

## Consequences

- **Positive:** Decisions are discoverable, reviewable in PRs, and survive team changes (if any).
- **Positive:** Forces explicit reasoning before committing to a direction.
- **Negative:** Adds a small overhead per decision, but the cost of *not* documenting is higher.