# Variables configurables (puedes sobreescribirlas por entorno)
DB_CONTAINER := env_var_or_default("DB_CONTAINER", "postgres_local")
DB_USER := env_var_or_default("DB_USER", "app")
DB_NAME := env_var_or_default("DB_NAME", "appdb")
DB_PORT := env_var_or_default("DB_PORT", "5432")
DB_PASSWORD := env_var_or_default("DB_PASSWORD", "app123")

set dotenv-load := true

default:
    @just --list

# Levanta Postgres en segundo plano
up:
    docker compose up -d

# Espera hasta que Postgres acepte conexiones
wait-db:
        until docker compose exec -T postgres sh -c 'pg_isready -U {{DB_USER}} -d {{DB_NAME}} >/dev/null 2>&1 && psql -U {{DB_USER}} -d {{DB_NAME}} -c "select 1" >/dev/null 2>&1'; do \
            echo "Esperando a PostgreSQL..."; \
            sleep 1; \
        done

# Muestra logs de la base de datos
logs:
    docker compose logs -f postgres

# Detiene el contenedor sin eliminar datos
stop:
    docker compose stop postgres

# Baja el stack sin borrar volumen
down:
    docker compose down

# Limpia todo: contenedor + volumen (borra la data)
clean:
    docker compose down -v --remove-orphans

# Abre psql dentro del contenedor
psql:
    docker compose exec postgres psql -U {{DB_USER}} -d {{DB_NAME}}

# Conecta desde tu terminal local (requiere psql instalado en host)
psql-host:
    PGPASSWORD={{DB_PASSWORD}} psql -h localhost -p {{DB_PORT}} -U {{DB_USER}} -d {{DB_NAME}}

# Ejecuta un script SQL de la carpeta ./sql
# Uso: just run-sql 001_init.sql
run-sql script:
    @just wait-db
    docker compose exec -T postgres psql -U {{DB_USER}} -d {{DB_NAME}} -f /scripts/{{script}}

# Ejecuta SQL inline
# Uso: just exec-sql "select now();"
exec-sql query:
    @just wait-db
    docker compose exec -T postgres psql -U {{DB_USER}} -d {{DB_NAME}} -c "{{query}}"

# Crea el esquema (tablas y llaves)
schema:
    @just run-sql schema.sql

# Carga los datos de prueba
load:
    @just run-sql load.sql

# Reinicia todo el dataset de la materia
reset-data:
    @just clean
    @just up
    @just schema
    @just load

# Estado rápido del contenedor
status:
    docker compose ps
