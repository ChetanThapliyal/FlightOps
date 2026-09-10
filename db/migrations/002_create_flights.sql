CREATE TABLE flights (
    id SERIAL PRIMARY KEY,
    departure_state VARCHAR(255) NOT NULL,
    arrival_state VARCHAR(255) NOT NULL,
    departure_time TIMESTAMP NOT NULL,
    arrival_time TIMESTAMP NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);