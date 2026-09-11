# PostgreSQL Commands — FlightOps

Quick reference for managing PostgreSQL via Docker Compose.

---

## Container

```bash
docker compose -f compose.postgres.yml up -d    # start
docker compose -f compose.postgres.yml ps       # status
docker compose -f compose.postgres.yml down     # stop
```

---

## psql Shell

```bash
# Enter interactive shell
docker compose -f compose.postgres.yml exec postgres psql -U flightops -d flightops
```

| Command | Description |
|---|---|
| `\dt` | List tables |
| `\d <table>` | Describe table (columns, constraints, indexes) |
| `\q` | Quit |

---

## Migrations

### Run Order

> Tables must be created in this order due to FK dependencies:

| # | File | Depends On |
|---|---|---|
| 1 | `001_create_states.sql` | — |
| 2 | `002_create_flights.sql` | states |
| 3 | `004_create_users.sql` | — |
| 4 | `003_create_tickets.sql` | states, users |

### Run All (Fresh Setup)

```bash
for f in \
  db/migrations/001_create_states.sql \
  db/migrations/002_create_flights.sql \
  db/migrations/004_create_users.sql \
  db/migrations/003_create_tickets.sql; do
  echo "--- $f ---"
  docker compose -f compose.postgres.yml exec -T postgres psql -U flightops -d flightops < "$f"
done
```

### Drop Everything & Rebuild

```bash
# Drop in reverse FK order
docker compose -f compose.postgres.yml exec -T postgres psql -U flightops -d flightops -c "
  DROP TABLE IF EXISTS tickets CASCADE;
  DROP TABLE IF EXISTS flights CASCADE;
  DROP TABLE IF EXISTS users   CASCADE;
  DROP TABLE IF EXISTS states  CASCADE;
"

# Re-run all migrations
for f in \
  db/migrations/001_create_states.sql \
  db/migrations/002_create_flights.sql \
  db/migrations/004_create_users.sql \
  db/migrations/003_create_tickets.sql; do
  echo "--- $f ---"
  docker compose -f compose.postgres.yml exec -T postgres psql -U flightops -d flightops < "$f"
done
```

---

## Verify

### Row counts across all tables

```bash
docker compose -f compose.postgres.yml exec -T postgres psql -U flightops -d flightops -c "
  SELECT 'states'  AS table_name, COUNT(*) FROM states
  UNION ALL
  SELECT 'flights' AS table_name, COUNT(*) FROM flights
  UNION ALL
  SELECT 'users'   AS table_name, COUNT(*) FROM users
  UNION ALL
  SELECT 'tickets' AS table_name, COUNT(*) FROM tickets;
"
```

### Sample flights (with state names via JOIN)

```bash
docker compose -f compose.postgres.yml exec -T postgres psql -U flightops -d flightops -c "
  SELECT f.id, s1.state_name AS from, s2.state_name AS to,
         f.departure_time, f.arrival_time, f.price
  FROM flights f
  JOIN states s1 ON s1.id = f.departure_state_id
  JOIN states s2 ON s2.id = f.arrival_state_id
  ORDER BY f.departure_time
  LIMIT 10;
"
```

### Search flights by route

```bash
docker compose -f compose.postgres.yml exec -T postgres psql -U flightops -d flightops -c "
  SELECT f.id, f.departure_time, f.arrival_time, f.price
  FROM flights f
  JOIN states s1 ON s1.id = f.departure_state_id
  JOIN states s2 ON s2.id = f.arrival_state_id
  WHERE s1.state_name = 'California'
    AND s2.state_name = 'New York'
  ORDER BY f.departure_time;
"
```
