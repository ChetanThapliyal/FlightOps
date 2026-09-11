-- =============================================================================
-- Migration: 002_create_flights.sql
-- Table:     flights
-- Purpose:   Available flights between US states.
--            departure_state_id and arrival_state_id are FKs into the states
--            table — ensures referential integrity and enables efficient JOINs.
-- Seed:      ~7,350 rows (3 flights × 50×49 unique state pairs).
-- Run order: 2nd — depends on: 001_create_states.sql
-- =============================================================================

CREATE TABLE flights (
    id                 SERIAL         PRIMARY KEY,
    departure_state_id INT            NOT NULL REFERENCES states(id),  -- FK → states
    arrival_state_id   INT            NOT NULL REFERENCES states(id),  -- FK → states
    departure_time     TIMESTAMPTZ    NOT NULL,                        -- timezone-aware
    arrival_time       TIMESTAMPTZ    NOT NULL,                        -- timezone-aware
    price              DECIMAL(10, 2) NOT NULL,
    CHECK (arrival_time > departure_time),                             -- arrival must be after departure
    CHECK (price > 0)
);

-- Indexes for common query patterns (search by route or date)
CREATE INDEX idx_flights_departure_state ON flights(departure_state_id);
CREATE INDEX idx_flights_arrival_state   ON flights(arrival_state_id);
CREATE INDEX idx_flights_departure_time  ON flights(departure_time);

-- =============================================================================
-- Seed Data
-- =============================================================================
-- Strategy: 3 flights per unique state pair (50 × 49 routes × 3 = 7,350 rows)
--
-- CTE 1 — state_regions:
--   Maps each state to one of 6 geographic regions for distance-based pricing.
--   Regions: northeast | southeast | midwest | south | mountain | pacific
--
-- CTE 2 — route_data:
--   Generates 3 flights per route using generate_series(1, 3).
--   Each flight falls in a different 10-day window within the next 30 days:
--     Flight 1 → days  1–10
--     Flight 2 → days 11–20
--     Flight 3 → days 21–30
--   Departure hour is random (00:00–22:00).
--
-- CTE 3 — priced_data:
--   Computes arrival_time and price.
--   Arrival is always departure_time + 1–5 hours (guaranteed > departure).
--   Price is region-aware:
--     Same region (short haul)       → $50–$200
--     Adjacent regions (mid haul)    → $150–$350
--     Distant / cross-country        → $250–$550
-- =============================================================================

WITH
state_regions AS (
    SELECT
        id,
        state_code,
        CASE
            WHEN state_code IN ('ME','NH','VT','MA','RI','CT','NY','NJ','PA') THEN 'northeast'
            WHEN state_code IN ('MD','DE','VA','WV','NC','SC','GA','FL')      THEN 'southeast'
            WHEN state_code IN ('OH','MI','IN','IL','WI','MN','IA','MO',
                                'ND','SD','NE','KS')                          THEN 'midwest'
            WHEN state_code IN ('KY','TN','AL','MS','AR','LA','OK','TX')      THEN 'south'
            WHEN state_code IN ('MT','ID','WY','CO','NM','AZ','UT','NV')      THEN 'mountain'
            WHEN state_code IN ('WA','OR','CA','AK','HI')                     THEN 'pacific'
        END AS region
    FROM states
),
route_data AS (
    -- 3 flights per route, staggered across 3 x 10-day departure windows
    SELECT
        s1.id     AS departure_state_id,
        s2.id     AS arrival_state_id,
        s1.region AS dep_region,
        s2.region AS arr_region,
        (NOW() + INTERVAL '1 day' * ((g.n - 1) * 10 + FLOOR(RANDOM() * 10)))::DATE
            + TIME '00:00:00'
            + INTERVAL '1 hour' * FLOOR(RANDOM() * 23) AS departure_time
    FROM       state_regions s1
    CROSS JOIN state_regions s2
    CROSS JOIN generate_series(1, 3) AS g(n)
    WHERE s1.state_code <> s2.state_code  -- exclude same-state routes
),
priced_data AS (
    SELECT
        departure_state_id,
        arrival_state_id,
        departure_time,
        -- arrival_time: 1–5 hours after departure (always > departure_time)
        departure_time + INTERVAL '1 hour' * (1 + FLOOR(RANDOM() * 5)) AS arrival_time,
        CASE
            -- Same region → short haul: $50–$200
            WHEN dep_region = arr_region
                THEN CAST((50 + RANDOM() * 150) AS NUMERIC(10, 2))

            -- Adjacent regions → mid haul: $150–$350
            WHEN (dep_region = 'northeast' AND arr_region IN ('southeast', 'midwest'))
              OR (dep_region = 'southeast' AND arr_region IN ('northeast', 'midwest', 'south'))
              OR (dep_region = 'midwest'   AND arr_region IN ('northeast', 'southeast', 'south', 'mountain'))
              OR (dep_region = 'south'     AND arr_region IN ('southeast', 'midwest', 'mountain'))
              OR (dep_region = 'mountain'  AND arr_region IN ('midwest', 'south', 'pacific'))
              OR (dep_region = 'pacific'   AND arr_region = 'mountain')
                THEN CAST((150 + RANDOM() * 200) AS NUMERIC(10, 2))

            -- Distant / cross-country → long haul: $250–$550
            ELSE CAST((250 + RANDOM() * 300) AS NUMERIC(10, 2))
        END AS price
    FROM route_data
)
INSERT INTO flights (departure_state_id, arrival_state_id, departure_time, arrival_time, price)
SELECT departure_state_id, arrival_state_id, departure_time, arrival_time, price
FROM priced_data;
