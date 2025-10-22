#!/bin/bash
# Airflow initialization script: Sets up metadata DB, admin user, and connections.
# Required env vars: POSTGRES_HOST, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB,
#                   PROJECT_HOST, PROJECT_USER, PROJECT_PASSWORD, PROJECT_DB,
#                   _AIRFLOW_WWW_USER_USERNAME, _AIRFLOW_WWW_USER_PASSWORD
# Optional env vars: AIRFLOW_EMAIL (default: admin@example.com), _AIRFLOW_DB_MIGRATE (default: true),
#                   _AIRFLOW_WWW_USER_CREATE (default: true), AIRFLOW__CORE__AUTH_MANAGER, DB_MAX_RETRIES

set -euo pipefail  # Exit on error (-e), treat unset variables as errors (-u), fail on pipeline errors (-o pipefail)
# Catches unset variables and pipeline errors for robust execution.
# Prevents silent failures due to undefined variables or partial command failures.

# Logging functions for consistent output with timestamps
# Timestamps and checkmarks improve log traceability and readability.
log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1"; }
error() { log "ERROR: $1"; exit 1; }

# Checks required environment variables to prevent script failure due to unset variables
# Uses set -u for early failure and minimal validation
validate_env() {
    local vars=(POSTGRES_HOST POSTGRES_USER POSTGRES_PASSWORD POSTGRES_DB
                PROJECT_HOST PROJECT_USER PROJECT_PASSWORD PROJECT_DB
                _AIRFLOW_WWW_USER_USERNAME _AIRFLOW_WWW_USER_PASSWORD)
    for var in "${vars[@]}"; do
        [ -z "${!var+x}" ] && error "$var must be set"
    done
    log "✓ Environment validated"
}

# Verifies that the configured auth_manager (e.g., FabAuthManager) is available
# Prevents AirflowConfigException during db migrate
check_auth_manager() {
    local auth_manager="${AIRFLOW__CORE__AUTH_MANAGER:-}"
    [ -z "$auth_manager" ] && { log "Using default auth_manager"; return; }
    
    # SKIP FAB check for SimpleAuthManager
    if [[ "$auth_manager" == *"simple"* ]]; then
        log "Using SimpleAuthManager - skipping provider check"
        return
    fi
    
    log "Checking auth_manager..."
    local module="${auth_manager%.*}"
    python -c "import $module" 2>/dev/null || error "Cannot import '$module'"
    log "✓ auth_manager available"
}

# CRITICAL FIX: Waits for Postgres to be ready using pg_isready
# IMPORTANT: Always uses port 5432 inside Docker network (not the host-mapped port from .env)
# Docker port mappings (e.g., 5433:5432) only apply to host access, not inter-container communication
# Inside Docker network: postgres:5432 and projecthost:5432 (both use default Postgres port)
# Limits retries (60 attempts ~5 minutes) to avoid hanging, with clear error messages
wait_for_db() {
    local host=$1 user=$2 db=$3 label=$4 max_retries=${DB_MAX_RETRIES:-60} delay=5 count=0
    log "Waiting for $label..."
    # Always use port 5432 inside Docker network - do not use POSTGRES_PORT or PROJECT_PORT env vars here
    while ! pg_isready -h "$host" -U "$user" -d "$db" -q 2>/dev/null; do
        ((count++ >= max_retries)) && error "$label not ready after $((max_retries * delay))s"
        sleep "$delay"
        ((count++))
    done
    log "✓ $label ready"
}

# Runs Airflow command with error handling
# Captures output for debugging and ensures commands fail cleanly
run_airflow_cmd() {
    airflow "$@" || error "Command 'airflow $*' failed"
}

# Initializes or migrates Airflow DB
# Uses AIRFLOW__DATABASE__SQL_ALCHEMY_CONN internally
# Skips if _AIRFLOW_DB_MIGRATE is false to avoid redundant migrations
migrate_db() {
    [ "${_AIRFLOW_DB_MIGRATE:-true}" != "true" ] && { log "Skipping DB migration"; return; }
    log "Running database migrations..."
    run_airflow_cmd db migrate
    log "✓ Database migrated"
}

# Creates admin user if it doesn't exist
# Idempotent to avoid duplicate user errors
# Silences "already exists" message for cleaner logs
create_user() {
    local username="${_AIRFLOW_WWW_USER_USERNAME:-admin}"
    log "Creating/checking admin user..."
    # Check if user exists by looking for exact username match
    if airflow users list 2>/dev/null | grep -qw "$username"; then
        log "✓ User '$username' already exists"
        return
    fi
    # Create user - suppress warnings but keep errors
    airflow users create \
        --username "$username" \
        --password "${_AIRFLOW_WWW_USER_PASSWORD:-admin}" \
        --firstname Admin \
        --lastname User \
        --role Admin \
        --email "${AIRFLOW_EMAIL:-admin@example.com}" 2>&1 | grep -v "No user yet created" | grep -v "UserWarning" || true
    log "✓ User '$username' created successfully"
}

# Adds connection if it doesn't exist
# Idempotent to prevent duplicate connections
# CRITICAL FIX: Uses 'connections add' (NOT 'connections create') for Airflow 3.1.0
# Airflow 3.1.0 CLI only supports 'add', not 'create'
add_connection() {
    local conn_id=$1 conn_uri=$2
    log "Adding connection '$conn_id'..."
    
    # Check if connection already exists
    if airflow connections get "$conn_id" &>/dev/null; then
        log "✓ Connection '$conn_id' already exists"
        return
    fi
    
    # Add connection using Airflow 3.1.0 syntax
    # CRITICAL: Use 'add' not 'create', conn_id is positional argument
    if airflow connections add "$conn_id" --conn-uri "$conn_uri" 2>&1 | grep -qv "already exists"; then
        log "✓ Connection '$conn_id' added successfully"
    else
        log "✓ Connection '$conn_id' configured"
    fi
}

# NEW: Only run initialization for airflow-init service
# Other services (apiserver, scheduler) skip initialization
should_init() {
    # Check if this is the init service by looking at command or env var
    if [ "${_AIRFLOW_DB_MIGRATE:-false}" = "true" ]; then
        return 0  # true - should initialize
    fi
    return 1  # false - skip initialization
}

# Main initialization function
# Orchestrates DB setup, user creation, and connections
# NEW: Separated init logic from command execution for better control
init_airflow() {
    log "=== Airflow Initialization ==="
    
    validate_env
    check_auth_manager
    
    # CRITICAL FIX: Always use default port 5432 inside Docker network
    # The POSTGRES_PORT and PROJECT_PORT from .env are for host access only (e.g., pgAdmin, DBeaver)
    wait_for_db "$POSTGRES_HOST" "$POSTGRES_USER" "$POSTGRES_DB" "Airflow metadata DB"
    wait_for_db "$PROJECT_HOST" "$PROJECT_USER" "$PROJECT_DB" "Project DB"
    
    migrate_db
    
    if [ "${_AIRFLOW_WWW_USER_CREATE:-true}" = "true" ]; then

        if [ "$AIRFLOW__CORE__AUTH_MANAGER" = "airflow.providers.fab.auth_manager.fab_auth_manager.FabAuthManager" ]; then
            create_user
        fi
        # CRITICAL FIX: Use hardcoded port 5432 for connections (Docker network routing)
        # DO NOT use ${POSTGRES_PORT} or ${PROJECT_PORT} here - those are host ports
        # Inside Docker network, both containers listen on default port 5432
        add_connection "airflow_conn" "postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:5432/${POSTGRES_DB}"
        add_connection "project_conn" "postgres://${PROJECT_USER}:${PROJECT_PASSWORD}@${PROJECT_HOST}:5432/${PROJECT_DB}"
        # +psycopg2
    else
        log "Skipping user creation and connections"
    fi
    
    log "=== Initialization Complete ==="
}

# Main entry point - handles both init and runtime commands
# This pattern is used in official Apache Airflow Docker images
# Reference: https://github.com/apache/airflow/blob/main/scripts/in_container/entrypoint_prod.sh
main() {
    # Run initialization only for airflow-init service
    if should_init; then
        init_airflow
        # For init service, exit after initialization
        log "Init service completed, exiting..."
        exit 0
    fi
    
    # For other services (apiserver, scheduler), just run the command
    # This allows apiserver and scheduler to start directly without re-running init
    if [ "$#" -gt 0 ]; then
        log "Starting Airflow service: $*"
        # Use exec to replace shell process with airflow command
        # This ensures proper signal handling (SIGTERM, SIGINT) for graceful shutdowns
        exec airflow "$@"
    else
        log "No command specified"
        exit 1
    fi
}

# Passes control to the command specified in Docker CMD or docker-compose.yml
# Replaces shell process for proper signal handling (e.g., SIGTERM)
# Keeps container PID 1 clean for graceful shutdowns and logging
main "$@"