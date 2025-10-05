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

### 4. Create connections in pgAdmin manually 

Log in with:<br><br>
Username: admin@admin.com<br>
Password: root

Inside pgAdmin:

1. Click "**Add New Server**"

2. **Airflow Metadata DB:**  
   - **General tab:**  
     Name: Airflow Metadata DB  
   - **Connection tab:**  
     Hostname: postgres  
     Port: 5432  
     Username: airflow  
     Password: airflow  
     Maintenance Database: airflow  
   - Click **Save** ✅  
   _Note: This connects pgAdmin to the Airflow metadata database, used internally by Airflow to store DAG info, connections, and state._

3. **Project Database (used by DAGs):**  
   - **General tab:**  
     Name: Project Database  
   - **Connection tab:**  
     Hostname: project-db  
     Port: 5433  
     Username: project_user  
     Password: project_pass  
     Maintenance Database: project_db  
   - Click **Save** ✅  
   _Note: This database is for your project data. Must be added manually because pgAdmin cannot automatically read Airflow connections. Airflow DAGs will use a connection ID pointing to this DB._