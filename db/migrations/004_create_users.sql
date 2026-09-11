-- =============================================================================
-- Migration: 004_create_users.sql
-- Table:     users
-- Purpose:   Application user accounts. Referenced as FK by the tickets table.
-- Seed:      None — populated at runtime via user registration flow.
-- Run order: 3rd — no dependencies on other tables.
--            Must run BEFORE 003_create_tickets.sql (tickets.user_id FK).
-- =============================================================================

CREATE TABLE users (
    id       SERIAL       PRIMARY KEY,
    name     VARCHAR(50)  NOT NULL,
    password VARCHAR(50)  NOT NULL,  -- NOTE: store hashed passwords in production (e.g. bcrypt)
    email    VARCHAR(50)  NOT NULL UNIQUE
);