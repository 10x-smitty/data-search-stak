-- Set up Apache AGE and create test data
CREATE EXTENSION IF NOT EXISTS age;
LOAD 'age';
SET search_path = ag_catalog, "$user", public;

-- Create demo graph
SELECT create_graph('demo_graph');

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert test users
INSERT INTO users (name, email) VALUES 
    ('Alice Johnson', 'alice@example.com'),
    ('Bob Smith', 'bob@example.com'),
    ('Charlie Brown', 'charlie@example.com'),
    ('Diana Prince', 'diana@example.com'),
    ('Eve Wilson', 'eve@example.com')
ON CONFLICT DO NOTHING;

-- Add some graph nodes
SELECT * FROM cypher('demo_graph', $$
    CREATE (:Person {name: 'Alice', age: 30, city: 'New York'})
$$) AS (v agtype);

SELECT * FROM cypher('demo_graph', $$
    CREATE (:Person {name: 'Bob', age: 25, city: 'San Francisco'})
$$) AS (v agtype);

SELECT * FROM cypher('demo_graph', $$
    CREATE (:Person {name: 'Charlie', age: 35, city: 'Chicago'})
$$) AS (v agtype);

-- Create relationships
SELECT * FROM cypher('demo_graph', $$
    MATCH (a:Person {name: 'Alice'}), (b:Person {name: 'Bob'})
    CREATE (a)-[:KNOWS {since: '2020'}]->(b)
$$) AS (v agtype);

SELECT * FROM cypher('demo_graph', $$
    MATCH (b:Person {name: 'Bob'}), (c:Person {name: 'Charlie'})
    CREATE (b)-[:WORKS_WITH {project: 'Data Pipeline'}]->(c)
$$) AS (v agtype);

-- Verify data
SELECT 'Users Table:' as info;
SELECT * FROM users;

SELECT 'Graph Data:' as info;
SELECT * FROM cypher('demo_graph', $$
    MATCH (n:Person) 
    RETURN n.name as name, n.age as age, n.city as city
$$) AS (name agtype, age agtype, city agtype);

SELECT 'Graph Relationships:' as info;
SELECT * FROM cypher('demo_graph', $$
    MATCH (a:Person)-[r]->(b:Person) 
    RETURN a.name as person1, type(r) as relationship, b.name as person2, properties(r) as props
$$) AS (person1 agtype, relationship agtype, person2 agtype, props agtype);
