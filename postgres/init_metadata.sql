-- init_metadata.sql

-- The POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB from .env create the database automatically
-- Airflow already tracks DAG/task metadata in its own schema

-- Connect to the airflow database first (created by Docker entrypoint)
\c airflow;

-- Create meta_table in the airflow database (not default postgres database)
-- This table tracks custom ETL metadata alongside Airflow's built-in tables
CREATE TABLE IF NOT EXISTS public.meta_table (
    id SERIAL PRIMARY KEY,
    dag_name TEXT,
    run_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- public is default schema automatically handled. We add it so that thr DAG knows which exact table and which Db to writr 

-- Grant permissions to airflow user so DAGs can insert into this table
GRANT ALL ON TABLE public.meta_table TO airflow
