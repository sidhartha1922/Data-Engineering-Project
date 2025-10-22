-- Create user
CREATE USER project WITH PASSWORD 'project';

-- Create database
CREATE DATABASE project OWNER project;

GRANT ALL PRIVILEGES ON DATABASE project TO project;

-- Connect to project DB
\connect project;

CREATE SCHEMA IF NOT EXISTS project_schema;

-- Grant schema privileges
GRANT ALL ON SCHEMA project_schema TO project;

-- Create table
CREATE TABLE IF NOT EXISTS project_schema.project_table1 (
    id SERIAL PRIMARY KEY,
    name TEXT,
    email TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- CRITICAL FIX: Grant all privileges on table
GRANT ALL ON TABLE project_schema.project_table1 TO project;

-- CRITICAL FIX: Grant all privileges on the sequence (auto-increment)
-- This is required for INSERT operations to work
GRANT ALL ON SEQUENCE project_schema.project_table1_id_seq TO project;

-- Also grant on all sequences in the schema for future tables
GRANT ALL ON ALL SEQUENCES IN SCHEMA project_schema TO project;