############TESTING####################
## Alternative is:- 
docker system prune -a -f --volumes # For corrupted images/volumes or if Db configuration needs to have reset. Only during init the Db connections created
docker compose down -v && docker compose build --no-cache --pull && docker compose up -d postgres projecthost && timeout /t 10 && docker compose up -d airflow-init && timeout /t 10 && docker compose up -d
docker compose ps && docker compose exec airflow-api-server airflow users list && docker compose exec airflow-api-server airflow connections list && start http://localhost:8080 && start http://localhost:5050
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