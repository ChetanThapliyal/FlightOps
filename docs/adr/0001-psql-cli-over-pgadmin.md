# ADR-0001: PostgreSQL Developer Tooling and Data Persistence Strategy

## Status

Accepted

## Date

2026-09-09

## Context

FlightOps needs a way to query and administer the PostgreSQL database during development and in production. Two approaches were evaluated:

1. **pgAdmin (Web UI)**: a browser-based administration tool deployed as a separate container (`dpage/pgadmin4`). Provides a graphical query editor, table browser, and visual explain plans.

2. **psql (CLI)**: the native PostgreSQL command-line client, already bundled inside the `postgres` container. Accessed via `docker compose exec` locally or `kubectl exec` in Kubernetes.

### Factors considered — Database Administration

| Factor | pgAdmin | psql (CLI) |
|---|---|---|
| Resource overhead | ~200–300 MB RAM idle | Zero — on-demand |
| Additional credentials | Requires its own email + password | Uses existing DB credentials |
| Attack surface | Extra exposed port (5050), web UI | No additional exposure |
| Production relevance | Never deployed in prod clusters | Standard production debugging tool |
| Learning value | Abstracts SQL behind GUI | Builds SQL and CLI fluency |
| Setup complexity | Extra service, depends_on, healthcheck | Already available in Postgres image |

Additionally, since this project spans multiple days with the system shutting down between sessions, the Compose stack needs a data persistence strategy. Two volume approaches were evaluated:

### Factors considered — Data Persistence

| Factor | Bind Mount | Named Volume |
|---|---|---|
| Data survives `compose down` | ✅ Yes | ✅ Yes |
| Managed by Docker | ❌ Manual host path | ✅ Fully managed |
| Portability across machines | ❌ Tied to host filesystem | ✅ Works anywhere |
| Production parity (k8s PVCs) | ❌ Not representative | ✅ Mirrors PVC behaviour |
| Accidental deletion risk | Low (visible on disk) | Medium — `down -v` destroys it |

## Decision

### 1. Database Administration — psql CLI

We will use **psql via `docker compose exec`** (and later `kubectl exec`) as the sole database administration tool and **remove pgAdmin** from the Compose stack.

```bash
# Local development
docker compose exec postgres psql -U flightops -d flightops

# Kubernetes (Day 4+)
kubectl exec -it postgres-0 -n flightops -- psql -U flightops -d flightops
```

### 2. Data Persistence — Named Volume

We will use a **Docker named volume** (`flightops_pgdata`) rather than a bind mount to persist PostgreSQL data across `compose down` / system restarts.

```yaml
# compose.yml
services:
  postgres:
    volumes:
      - flightops_pgdata:/var/lib/postgresql/data

volumes:
  flightops_pgdata:
```

> **Warning:** Running `docker compose down -v` will destroy the named volume and all data. Use plain `docker compose down` to stop the stack while preserving data.

## Consequences

### psql CLI
- **Positive:** Leaner stack — one fewer container to manage, secure, and resource-constrain.
- **Positive:** Production parity — mirrors exactly how database debugging is done in real Kubernetes environments.
- **Positive:** Builds proficiency with `psql`, the standard tool for production database troubleshooting.
- **Negative:** No graphical query editor or visual explain plans.
- **Mitigation:** For complex query analysis, developers can use local GUI tools (e.g., DBeaver, DataGrip) connected to the exposed port `5432` if needed — these don't require containerization.

### Named Volume
- **Positive:** Data persists across daily shutdowns without any extra steps.
- **Positive:** Production parity — Docker named volumes behave analogously to Kubernetes PersistentVolumeClaims (PVCs), reinforcing the same mental model.
- **Positive:** No host-path coupling — the stack is portable across developer machines.
- **Negative:** Volume contents are not directly browsable on the host filesystem.
- **Negative:** A careless `docker compose down -v` permanently destroys all data with no confirmation prompt.
