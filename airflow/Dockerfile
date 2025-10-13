# OFFICIAL DOCS REFER:- https://hub.docker.com/r/apache/airflow/Dockerfile
# https://airflow.apache.org/docs/apache-airflow/stable/extra-packages-ref.html
# initialize build stage, sets base image for subsequent instructions
ARG AIRFLOW_VERSION=3.1.0 
ARG PYTHON_VERSION=3.12
ARG IMAGE_FLAVOR=slim
ARG PIP_VERSION=25.2
FROM apache/airflow:${IMAGE_FLAVOR}-${AIRFLOW_VERSION}-python${PYTHON_VERSION}

# Setting again to avoid conflicts as a best practice. Could be used in multiple stages.
# ${variable:-word} indicates that if variable is set then the result will be that value. If variable is not set then word will be the result.
# ENV will overwrite the ARG set before FROM. ARG can be passed during runtime through CLI as well.
ENV AIRFLOW_VERSION=${AIRFLOW_VERSION:-3.1.0}
ENV PYTHON_VERSION=${PYTHON_VERSION:-3.12}
ENV PIP_VERSION=${PIP_VERSION:-25.2}
ENV DIR_PATH=/tmp

# Switch to root to install system dependencies
USER root

# absolute paths to read easily, to avoid unneccesary file execs in random directory
WORKDIR $DIR_PATH

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements into temp as extras not airflow itself
COPY requirements.txt /tmp/requirements.txt

# Download constraints file
RUN curl -sSL "https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt" -o /tmp/constraints.txt

# https://airflow.apache.org/docs/docker-stack/build.html#adding-packages-from-requirements-txt
# Switch to airflow user before installing Python packages (user already exists in base image)
USER airflow

# Upgrade pip
RUN pip install --upgrade "pip==${PIP_VERSION}"

# https://airflow.apache.org/docs/apache-airflow-providers/index.html
# CRITICAL FIX: Install Airflow with fab extras for Airflow 3.x
# [fab] extra includes Flask-AppBuilder provider needed for AIRFLOW__CORE__AUTH_MANAGER
# Without [fab], the FAB auth manager will fail to import causing "duplicate key" errors
RUN pip install --no-cache-dir \
    "apache-airflow[fab]==${AIRFLOW_VERSION}" \
    --constraint /tmp/constraints.txt

# Install apache-airflow-providers-postgres separately (cleaner than [postgres] extra)
# This includes psycopg2-binary and asyncpg automatically
RUN pip install --no-cache-dir \
    "apache-airflow-providers-postgres" \
    --constraint /tmp/constraints.txt

# Explicitly install asyncpg to ensure it's available (Airflow 3.x requires for async DB operations)
# Even though providers-postgres should include it, explicit install prevents edge cases
RUN pip install --no-cache-dir asyncpg --constraint /tmp/constraints.txt

# Install polars as regular package (not Airflow extra)
RUN pip install --no-cache-dir polars --constraint /tmp/constraints.txt

# Install custom requirements without constraints (not related to airflow, e.g., ruff for linting)
# No constraints for non-Airflow packages to avoid version conflicts
RUN pip install --no-cache-dir -r /tmp/requirements.txt 

# Verify critical packages are installed - helps with debugging if build succeeds but runtime fails
# This verification step will show package versions in build logs
RUN pip list | grep -E "(apache-airflow|apache-airflow-providers-postgres|asyncpg|psycopg2|sqlalchemy|flask-appbuilder|polars)" && echo "✓ All required packages installed"

# Switch back to root to copy entrypoint
USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Optional: clean tmp (free space)
RUN rm -rf /tmp/constraints.txt /tmp/requirements.txt

# Final switch to airflow user
USER airflow

WORKDIR /opt/airflow

# Set entrypoint. Using exec form rather than shell script. 
# E.g, EXEC FORM:- RUN [ "sh", "-c", "echo $HOME" ] ==> to run shell script using exec form
# E.g, COMMAND SHELL:- RUN source $HOME/.bashrc && echo $HOME ==> Also use \ after && if more commands on new line
ENTRYPOINT ["/entrypoint.sh"]