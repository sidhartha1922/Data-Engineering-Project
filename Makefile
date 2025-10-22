
# Makefile for Airflow Docker setup
.PHONY: help clean build postgres init up down stop restart ps logs logs-init logs-api health test-connections verify fresh-start quick-restart

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

clean: ## Remove all containers, volumes, and logs
	docker compose down -v
	rm -rf airflow/logs/*
	rm -rf airflow/plugins/__pycache__ 2>/dev/null || true
	@echo "✓ Cleaned up containers, volumes, and logs"

build: ## Build images defined in docker-compose.yaml
	@echo "Building Airflow images..."
	docker compose build --no-cache
	@echo "✓ Images built successfully"

postgres: ## Build and start postgres services only
	@echo "Starting postgres services..."
	docker compose up -d postgres projecthost
	@echo "✓ Postgres services started"

init: ## Initialize Airflow database and user
	@echo "Initializing Airflow database and user..."
	docker compose up -d airflow-init
	@echo "✓ Initialization started"

up: ## Start all Airflow services (pgAdmin, projecthost, api-server, scheduler)
	@echo "Starting all Airflow services..."
	docker compose up -d
	@echo "✓ All services started"

down: ## Stop and remove Airflow containers and volumes
	@echo "Stopping and removing containers..."
	docker compose down -v
	@echo "✓ Services stopped and removed"

stop: ## Stop running containers without removing them
	@echo "Stopping Airflow services..."
	docker compose stop
	@echo "✓ Services stopped"

restart: ## Restart all services
	docker compose restart
	@echo "✓ Services restarted"

ps: ## List running services
	@echo "Listing running services..."
	docker compose ps

logs: ## Show all logs (follow mode)
	docker compose logs -f

logs-init: ## Show init logs only
	docker compose logs -f airflow-init

logs-api: ## Show api-server logs only (NEW: replaces logs-web)
	docker compose logs -f airflow-api-server

logs-scheduler: ## Show scheduler logs only
	docker compose logs -f airflow-scheduler

health: ## Run comprehensive health checks
	@echo "🔍 Checking Airflow Services..."
	@echo ""
	@echo "📦 Container Status:"
	@docker compose ps
	@echo ""
	@echo "🗄️ Database Connections:"
	@docker compose exec -T postgres pg_isready -U airflow && echo "✅ Airflow DB: Ready" || echo "❌ Airflow DB: Failed"
	@docker compose exec -T projecthost pg_isready -U project && echo "✅ Project DB: Ready" || echo "❌ Project DB: Failed"
	@echo ""
	@echo "👤 Airflow Users:"
	@docker compose exec -T airflow-api-server airflow users list 2>/dev/null | head -5 || echo "⚠️ API Server not ready yet"
	@echo ""
	@echo "🔗 Airflow Connections:"
	@docker compose exec -T airflow-api-server airflow connections list 2>/dev/null || echo "⚠️ API Server not ready yet"
	@echo ""
	@echo "🌐 Access URLs:"
	@echo "  Airflow UI: http://localhost:8080 (admin/admin)"
	@echo "  pgAdmin:    http://localhost:5050 (admin@admin.com/root)"
	@echo ""
	@echo "✅ Health check complete!"

test-connections: ## Test database connections
	@echo "Testing Airflow metadata DB..."
	@docker compose exec -T postgres pg_isready -U airflow
	@echo "Testing Project DB..."
	@docker compose exec -T projecthost pg_isready -U project
	@echo "Getting Airflow connection..."
	@docker compose exec -T airflow-api-server airflow connections get airflow_conn || echo "⚠️ Connection not found"
	@echo "Getting Project connection..."
	@docker compose exec -T airflow-api-server airflow connections get project_conn || echo "⚠️ Connection not found"

verify: ## Verify Airflow setup
	@echo "🔍 Verifying Airflow Installation..."
	@echo ""
	@echo "Airflow version:"
	@docker compose exec -T airflow-api-server airflow version 2>/dev/null || echo "⚠️ API Server not ready"
	@echo ""
	@echo "Installed packages:"
	@docker compose exec -T airflow-api-server pip list | grep -E "(apache-airflow|asyncpg|psycopg2|sqlalchemy)" || echo "⚠️ Cannot verify packages"

fresh-start: clean build postgres ## Complete fresh start (clean + build + postgres + init + up)
	@echo "⏳ Waiting 10 seconds for postgres to be ready..."
	@sleep 10
	@$(MAKE) init
	@echo "⏳ Waiting 20 seconds for initialization..."
	@sleep 20
	@$(MAKE) up
	@echo "⏳ Waiting 30 seconds for services to start..."
	@sleep 30
	@$(MAKE) health

quick-restart: down up ## Quick restart (no rebuild)
	@echo "⏳ Waiting 30 seconds for services to initialize..."
	@sleep 30
	@$(MAKE) health

# This command will analyze your Dags located in the dags/ directory and report any issues related to the specified rules.
dag-check:
	ruff check dags/ --select AIR3