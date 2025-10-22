# https://github.com/apache/airflow/blob/providers-postgres/6.3.0/providers/postgres/tests/system/postgres/example_postgres.py
# from airflow.sdk import dag, task
"""
Demo ETL DAG with proper connection handling.
Connections are created by entrypoint.sh:
  - airflow_conn: metadata database
  - project_conn: project database
"""

import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.providers.standard.operators.python import PythonOperator
from airflow.exceptions import AirflowException

import logging

logger = logging.getLogger("airflow.task")

# Now you can access the connection
# "CONN_META"
# "CONN_PROJECT"

""" TESTING
https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html#best-practices-handling-conflicting-complex-python-dependencies
"""

# Alternative
# Helper: resolve path to SQL files
# SQL_DIR = os.path.join(os.path.dirname(__file__), "..", "sql")

default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "start_date": pendulum.datetime(year=2025, month=10, day=15, hour=15, tz="UTC"),
    "schedule_interval": None,  # E.g run every hour "@hourly"
    "retry_delay": timedelta(minutes=5),
    "retries": 1,
}


def test_connection(**context):
    """Test connection with proper error handling."""
    task_id = context["task"].task_id
    try:
        logger.info(f"[{task_id}] Testing airflow_conn...")

        hook = PostgresHook(postgres_conn_id="airflow_conn")
        # Use hook.get_records() instead of manual cursor - more reliable
        result = hook.get_records("SELECT 1 as test;")

        logger.info(f"[{task_id}] ✓ Connection OK: {result}")
        return True

    except Exception as e:
        logger.error(f"[{task_id}] ✗ Failed: {str(e)}", exc_info=True)
        raise


# Refer later:- https://stackoverflow.com/questions/76217291/ensuring-unique-dag-id-on-apache-airflow to use DagBag
# https://stackoverflow.com/questions/76772947/how-to-template-database-in-airflow-sqlexecutequeryoperator
with DAG(
    dag_id="demo_dag",
    catchup=False,
    tags=["etl"],
    default_args=default_args,
    description="Demo ETL pipeline",
) as dag:
    # Task 1: Test connection

    test_connection_task = PythonOperator(
        task_id="test_connection",
        python_callable=test_connection,
        retries=1,
    )

    # Task 2: Create project table
    create_project_table = SQLExecuteQueryOperator(
        task_id="t2_create_project_table1",
        conn_id="project_conn",  # Connection ID created by entrypoint.sh
        do_xcom_push=True,
        show_return_value_in_logs=True,
        sql="""
            CREATE TABLE IF NOT EXISTS project_schema.project_table1 (
                id SERIAL PRIMARY KEY,
                name TEXT,
                email TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """,
    )

    # Task 3: Log metadata
    log_metadata = SQLExecuteQueryOperator(
        task_id="t1_metadata",
        conn_id="airflow_conn",  # Connection ID created by entrypoint.sh
        do_xcom_push=True,
        show_return_value_in_logs=True,
        sql="""
            INSERT INTO public.meta_table (dag_name, run_time)
            VALUES ('demo_dag', CURRENT_TIMESTAMP);
        """,
    )

    # Task 4: Insert data
    insert_data = SQLExecuteQueryOperator(
        task_id="insert_project_table1",
        conn_id="project_conn",  # Connection ID created by entrypoint.sh
        do_xcom_push=True,
        show_return_value_in_logs=True,
        sql="""
            INSERT INTO project_schema.project_table1 (name, email)
            VALUES 
              ('Alice', 'alice@example.com'),
              ('Bob', 'bob@example.com')
            ON CONFLICT DO NOTHING;
        """,
    )

    # Task 5: Query results
    query_data = SQLExecuteQueryOperator(
        task_id="query_project_table1",
        conn_id="project_conn",  # Connection ID created by entrypoint.sh
        sql="SELECT * FROM project_schema.project_table1;",
        do_xcom_push=True,
        show_return_value_in_logs=True,
    )

    # Task dependencies
    (
        test_connection_task
        >> [log_metadata, create_project_table]
        >> insert_data
        >> query_data
    )
