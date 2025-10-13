-- init_project.sql
-- create user
CREATE USER project WITH PASSWORD 'project';

-- create database
CREATE DATABASE project OWNER project;

GRANT ALL PRIVILEGES ON DATABASE project TO project;

-- connect to project DB
\connect project;

CREATE SCHEMA IF NOT EXISTS project_schema;
-- PostgreSQL 15 requires additional privileges:
-- Note: Connect to the airflow_db database before running the following GRANT statement
-- You can do this in psql with: \c airflow_db
GRANT ALL ON SCHEMA project_schema TO project;

-- create tables
CREATE TABLE IF NOT EXISTS project_table1 (
    id SERIAL PRIMARY KEY,
    name TEXT,
    email TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);