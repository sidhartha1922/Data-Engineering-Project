############TESTING####################
## Alternative is:- 
docker system prune -a -f --volumes # For corrupted images/volumes or if Db configuration needs to have reset. Only during init the Db connections created
docker compose down -v && docker compose build --no-cache --pull && docker compose up -d postgres projecthost && timeout /t 5 && docker compose up -d airflow-init airflow-api-server && timeout /t 5 && docker compose up -d 
# Use in setup where FAB is enabled. Now using  Simple for testing
docker compose ps && docker compose exec airflow-api-server airflow users list && docker compose exec airflow-api-server airflow connections list && start http://localhost:8080 && start http://localhost:5050
docker compose exec airflow-api-server airflow connections list && start http://localhost:8080 && start http://localhost:5050
##################################################
# 1. Stop everything
docker-compose down -v

# 2. Build no cache
make build

# 3. Postgres first
make postgres

# 4. Rebuild with fixed docker-compose.yml
make init

# 5. Start everything
make up

# 6. Wait for services (30 seconds)
timeout /t 30

# 7. Check health
make health

# OR use the all-in-one command: 
make fresh-start
make logs-init    # Check init logs
make verify       # Verify everything works

# Open your browser at:
http://localhost:8080 (port selected)
# (Login: admin, Password: admin)


#------------DAG Not appear--------------------
# Enter Airflow container
docker exec -it data-engineering-project-airflow-api-server-1 bash

airflow connections test airflow_conn
airflow connections test project_conn

# Refresh DAG folder
airflow dags reserialize

# Check DAG processing errors
airflow dags list-import-errors

# Verify file permissions
ls -la dags/your_dag.py

#------------Task Stuck in Queued state-----------------

# Monitor real-time scheduler errors
docker compose logs -f airflow-scheduler || findstr -i "error\|refused\|sigkill"
docker compose logs airflow-scheduler || findstr "Invalid auth"  # Should be empty
docker compose logs airflow-api-server || findstr "403"  # Should be empty

# Check scheduler status
airflow jobs check --job-type SchedulerJob

# Restart scheduler
airflow scheduler

# Check executor capacity
airflow config get-value core parallelism

#------------Database connection errors-----------------
# Test database connection
airflow db check

# Reset database (caution: loses data)
airflow db reset

# Check connection string
airflow config get-value database sql_alchemy_conn

# Check DAG status
airflow dags test demo_dag 2025-10-19

#-------------------------- >25 means pool exhuasted
# Check database pool exhaustion
docker exec data-engineering-project-postgres-1 psql -U airflow -d airflow -c "SELECT count(*), state FROM pg_stat_activity GROUP BY state;"
\q