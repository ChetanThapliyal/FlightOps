-- =============================================================================
-- Migration: 003_create_tickets.sql
-- Table:     tickets
-- Purpose:   Booked tickets linking a user to a specific flight route.
--            departure_state_id / arrival_state_id reference the states table.
--            user_id references the users table.
--            ticket_number is unique per booking.
-- Seed:      None — populated at runtime by the application booking flow.
-- Run order: 4th — depends on: 001_create_states.sql, 003_create_users.sql
-- NOTE:      Run 003_create_users.sql before this file (users FK must exist).
-- =============================================================================

CREATE TABLE tickets (
    id                 SERIAL         PRIMARY KEY,
    ticket_number      VARCHAR(50)    NOT NULL UNIQUE,                 -- unique booking reference
    departure_state_id INT            NOT NULL REFERENCES states(id),  -- FK → states
    arrival_state_id   INT            NOT NULL REFERENCES states(id),  -- FK → states
    departure_time     TIMESTAMPTZ    NOT NULL,                        -- timezone-aware
    arrival_time       TIMESTAMPTZ    NOT NULL,                        -- timezone-aware
    ticket_price       DECIMAL(10, 2) NOT NULL,
    user_id            INT            NOT NULL REFERENCES users(id),   -- FK → users
    CHECK (arrival_time > departure_time),                             -- arrival must be after departure
    CHECK (ticket_price > 0)
);

-- Indexes for common query patterns (look up tickets by user or route)
CREATE INDEX idx_tickets_user_id         ON tickets(user_id);
CREATE INDEX idx_tickets_departure_state ON tickets(departure_state_id);
CREATE INDEX idx_tickets_arrival_state   ON tickets(arrival_state_id);