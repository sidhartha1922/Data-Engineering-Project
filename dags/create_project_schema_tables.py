from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator
from datetime import datetime

with DAG(
    "create_project_schema",
    start_date=datetime(2025, 1, 1),
    schedule_interval=None,
    catchup=False,
    tags=["setup"]
) as dag:

    create_schema = PostgresOperator(
        task_id="create_schema",
        postgres_conn_id="my_postgres",
        sql="CREATE SCHEMA IF NOT EXISTS my_schema;"
    )

    create_sample_table = PostgresOperator(
        task_id="create_sample_table",
        postgres_conn_id="my_postgres", # Created this in YAML during airflow init
        sql="""
        CREATE TABLE IF NOT EXISTS my_schema.sample_table (
            id SERIAL PRIMARY KEY,
            name VARCHAR(50),
            created_at TIMESTAMP DEFAULT NOW()
        );
        """
    )

    create_schema >> create_sample_table
