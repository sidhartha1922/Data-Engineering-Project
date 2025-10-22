# OFFICIAL DOCS REFER:- https://hub.docker.com/r/apache/airflow/Dockerfile
# https://airflow.apache.org/docs/apache-airflow/stable/extra-packages-ref.html
# initialize build stage, sets base image for subsequent instructions
ARG AIRFLOW_VERSION=3.0.6
ARG PYTHON_VERSION=3.12
ARG IMAGE_FLAVOR=slim
ARG PIP_VERSION=25.2
FROM apache/airflow:${IMAGE_FLAVOR}-${AIRFLOW_VERSION}-python${PYTHON_VERSION}

# Setting again to avoid conflicts as a best practice. Could be used in multiple stages.
# ${variable:-word} indicates that if variable is set then the result will be that value. If variable is not set then word will be the result.
# ENV will overwrite the ARG set before FROM. ARG can be passed during runtime through CLI as well.
ENV AIRFLOW_VERSION=${AIRFLOW_VERSION:-3.0.6}
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

# https://airflow.apache.org/docs/docker-stack/build.html#adding-packages-from-requirements-txt
# Switch to airflow user before installing Python packages (user already exists in base image)
USER airflow

# Upgrade pip
RUN pip install --upgrade "pip==${PIP_VERSION}"

# Fab for production. But keep it installed for now
# postgres provider includes psycopg2-binary and asyncpg automatically
RUN pip install --no-cache-dir \
    "apache-airflow-providers-fab"  \
    "apache-airflow-providers-postgres" \
    polars 
# Install polars as regular package (not Airflow extra)

COPY requirements.txt /tmp/requirements.txt
# Install custom requirements without constraints (not related to airflow, e.g., ruff for linting)
# No constraints for non-Airflow packages to avoid version conflicts
RUN pip install --no-cache-dir -r /tmp/requirements.txt 

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