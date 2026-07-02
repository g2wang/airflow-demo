#!/bin/bash
set -e

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo "Loading environment from .env..."
    export $(grep -v '^#' .env | xargs)
fi

# Fallback to current working directory if PROJECT_DIR is not set
if [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR="$PWD"
fi

# Fallback to default password if POSTGRES_PASSWORD is not set
if [ -z "$POSTGRES_PASSWORD" ]; then
    POSTGRES_PASSWORD="postgres"
fi

echo "Using PROJECT_DIR: $PROJECT_DIR"
export AIRFLOW_HOME="$PROJECT_DIR/airflow_home"
export AIRFLOW__CORE__LOAD_EXAMPLES=False


# 1. Start PostgreSQL via Docker Compose
echo "Starting PostgreSQL container..."
docker compose up -d

# 2. Wait for PostgreSQL to be healthy
echo "Waiting for PostgreSQL to become healthy..."
for i in {1..30}; do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' airflow-postgres 2>/dev/null || true)
    if [ "$STATUS" = "healthy" ]; then
        echo "PostgreSQL is healthy!"
        break
    fi
    echo "Current status: $STATUS (waiting...)"
    sleep 1
    if [ $i -eq 30 ]; then
        echo "Error: PostgreSQL did not become healthy in time."
        exit 1
    fi
done

# 3. Generate mock Parquet data
echo "Generating mock Parquet data..."
uv run python scripts/generate_mock_data.py

# 4. Initialize Airflow Database
echo "Initializing Airflow database..."
uv run airflow db init

# 5. Configure Airflow connection for Postgres
echo "Configuring Postgres connection in Airflow..."
# Ignore errors if the connection doesn't exist yet
uv run airflow connections delete 'postgres_default' || true
uv run airflow connections add 'postgres_default' \
    --conn-type 'postgres' \
    --conn-host 'localhost' \
    --conn-login 'postgres' \
    --conn-password "$POSTGRES_PASSWORD" \
    --conn-schema 'analytics' \
    --conn-port '5432'

# 6. Start Airflow Standalone
echo "=========================================================="
echo "Starting Apache Airflow Standalone..."
echo "Open your browser to http://localhost:8080"
echo "Login credentials will be printed below."
echo "To stop Airflow, press Ctrl+C."
echo "=========================================================="
uv run airflow standalone
