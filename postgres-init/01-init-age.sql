-- Initialize Apache AGE extension
-- This script runs automatically when the PostgreSQL container starts for the first time

-- Create the AGE extension
CREATE EXTENSION IF NOT EXISTS age;

-- Load the AGE extension into the database
LOAD 'age';

-- Set the search path to include AGE functions
SET search_path = ag_catalog, "$user", public;

-- Create a sample graph (optional - you can remove this if not needed)
SELECT create_graph('demo_graph');

-- Create a sample user table (optional - you can customize or remove this)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert some sample data (optional - you can remove this)
INSERT INTO users (name, email) VALUES 
    ('John Doe', 'john@example.com'),
    ('Jane Smith', 'jane@example.com')
ON CONFLICT DO NOTHING;

-- Display success message
\echo 'Apache AGE extension initialized successfully!'
\echo 'Available graphs:'
SELECT * FROM ag_graph;
