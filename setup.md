# Installation guide to setup project pre-requisites [Windows Only].

---

### 1. Installing the official docker compose file

- Run the Command in Windows terminal within the project directory.
- Refer below docs to contnue with next steps.

```bash
curl -LfO https://airflow.apache.org/docs/apache-airflow/3.1.0/docker-compose.yaml
```

- Add below code in YAML config file at the end

```bash
  pgadmin:
    container_name: pgadmin4_container
    image: dpage/pgadmin4
    restart: always
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@admin.com
      PGADMIN_DEFAULT_PASSWORD: root
    ports:
      - "5432:80"
```

Refer [here](https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html) and [example](https://airflow.apache.org/docs/apache-airflow/stable/tutorial/pipeline.html)

### 2. Creating new directories

```bash
mkdir dags logs plugins config
```

### 3. Initialize the Database and start the airflow

- `**Note:- Run the Docker software before proceeding**`

```bash
# Initialize the database
docker compose up airflow-init

# Start up all services (with -d, it's detached mode which means no logs would be shown)
docker compose up -d
```
- Once Airflow is up and running, visit the UI [here](http://localhost:8080)

Log in with:<br><br>

Username: airflow<br>
Password: airflow

- Then visit pgAdmin [here](http://localhost:5050)

Log in with:<br><br>
Username: admin@admin.com<br>
Password: root

Inside pgAdmin:
- Click “Add New Server”
- General tab: Give it a name, e.g., Airflow Postgres
- Connection tab:<br>
Hostname: postgres → this is the Docker service name<br>
Port: 5432<br>
Username: airflow<br>
Password: airflow<br>
Maintenance Database: airflow

Click Save → now pgAdmin can manage your PostgreSQL database.

- Then, identify the IP address of the PostgreSQL Docker container:

```bash
docker container ls
docker inspect <container_id> | findstr IPAddress
```

### 4. Add a connection in Airflow:

- **Before writing to pipeline, Airflow need to be told how to postgres running in Docker**

- Go to the Airflow UI and set up a new connection
- Go to Admin → Connections.
- Click “+” (Add a new record).
- Fill out the form:<br>
Connection Id (Name) → tutorial_pg_conn<br>
Connection Type → postgres<br>
Host → If using Docker Compose: postgres (service name in docker-compose.yaml)<br>
Schema (Database) → airflow (or whatever database you created in pgAdmin/Postgres)<br>
Login → airflow (your Postgres user from yaml)<br>
Password → airflow<br>
Port → 5432<br>
Save ✅