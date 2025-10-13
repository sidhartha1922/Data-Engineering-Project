# https://github.com/apache/airflow/blob/providers-postgres/6.3.0/providers/postgres/tests/system/postgres/example_postgres.py
from pathlib import Path
from airflow import DAG
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
# Don't use PostgresOperator
# Refer https://medium.com/@JusticeDanalayst/how-i-solved-a-2-day-airflow-dag-import-error-in-docker-71e411ec7417

# from airflow.decorators import task
from datetime import datetime, timedelta
# import os

""" TESTING
https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html#best-practices-handling-conflicting-complex-python-dependencies
"""

# Load env vars
PROJECT_CONN_ID = "project_conn"  # Created in entrypoint.sh
AIRFLOW_CONN_ID = "airflow_conn"  # Created in entrypoint.sh

# Alternative
# Helper: resolve path to SQL files
# SQL_DIR = os.path.join(os.path.dirname(__file__), "..", "sql")

default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "start_date": datetime(2025, 1, 1),
    "schedule_interval": "@hourly",  # run every hour
    "retry_delay": timedelta(minutes=5),
    "retries": 5,
}

# Refer later:- https://stackoverflow.com/questions/76217291/ensuring-unique-dag-id-on-apache-airflow to use DagBag
with DAG(
    dag_id=Path(__file__).stem,  # Dynamically based on filename
    catchup=False,
    tags=["etl"],
    default_args=default_args,
) as dag:
    # Log DAG run in custom metadata table (optional)
    log_etl_metadata = SQLExecuteQueryOperator(
        task_id="t1_metadata",
        conn_id=AIRFLOW_CONN_ID,
        # Alternative, sql=os.path.join(SQL_DIR, "xyz.sql"),
        sql="""
            INSERT INTO meta_table (dag_name, run_time)
            VALUES ('etl_demo', CURRENT_TIMESTAMP);
        """,
    )

    # Create table in project DB (idempotent)
    create_project_table1 = SQLExecuteQueryOperator(
        task_id="t2_create_project_table1",
        conn_id=PROJECT_CONN_ID,
        sql="""
            CREATE TABLE IF NOT EXISTS project_table1 (
                id SERIAL PRIMARY KEY,
                name TEXT,
                email TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """,
    )

    # Insert sample data (idempotent: avoid duplicates on retries)
    insert_project_table1 = SQLExecuteQueryOperator(
        task_id="insert_project_table1",
        conn_id=PROJECT_CONN_ID,
        sql="""
            INSERT INTO project_table1 (name, email)
            VALUES 
              ('Alice', 'alice@example.com'),
              ('Bob', 'bob@example.com')
            ON CONFLICT DO NOTHING;
        """,
    )

    # Query for test/debug
    query_project_table1 = SQLExecuteQueryOperator(
        task_id="query_project_table1",
        conn_id=PROJECT_CONN_ID,
        sql="SELECT * FROM project_table1;",
        do_xcom_push=True,
    )

    # Task dependency chain
    (
        log_etl_metadata
        >> create_project_table1
        >> insert_project_table1
        >> query_project_table1
    )
