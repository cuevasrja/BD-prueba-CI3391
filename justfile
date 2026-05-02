# Variables configurables (puedes sobreescribirlas por entorno)
DB_CONTAINER := env_var_or_default("DB_CONTAINER", "postgres_local")
DB_USER := env_var_or_default("DB_USER", "app")
DB_NAME := env_var_or_default("DB_NAME", "appdb")
DB_PORT := env_var_or_default("DB_PORT", "5432")
DB_PASSWORD := env_var_or_default("DB_PASSWORD", "app123")

set dotenv-load := true

default:
    @just --list

# Levanta Postgres y espera a que esté listo (usa healthcheck)
up:
    docker compose up -d --wait

# Espera hasta que Postgres acepte conexiones (respaldo para 'up --wait')
wait-db:
    @echo "Verificando disponibilidad de PostgreSQL..."
    @until docker exec {{DB_CONTAINER}} pg_isready -U {{DB_USER}} -d {{DB_NAME}} >/dev/null 2>&1; do \
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
    docker exec -it {{DB_CONTAINER}} psql -U {{DB_USER}} -d {{DB_NAME}}

# Conecta desde tu terminal local (requiere psql instalado en host)
psql-host:
    PGPASSWORD={{DB_PASSWORD}} psql -h localhost -p {{DB_PORT}} -U {{DB_USER}} -d {{DB_NAME}}

# Ejecuta un script SQL desde el host (ruta relativa al directorio actual)
# Uso: just run-sql sql/schema.sql
run-sql script:
    @just wait-db
    @docker exec -i {{DB_CONTAINER}} psql -U {{DB_USER}} -d {{DB_NAME}} < {{script}}

# Ejecuta SQL inline
# Uso: just exec-sql "select now();"
exec-sql query:
    @just wait-db
    @docker exec -i {{DB_CONTAINER}} psql -U {{DB_USER}} -d {{DB_NAME}} -c "{{query}}"

# Crea el esquema manualmente
schema:
    @just run-sql sql/schema.sql

# Carga los datos manualmente
load:
    @just run-sql sql/load.sql

# Reinicia todo el dataset (ultra rápido con auto-init en docker-compose)
reset-data:
    @just clean
    @just up

# Reconstruye el stack desde cero: borra volumen y vuelve a inicializar
rebuild:
    @just clean
    @just up

# Muestra las extensiones instaladas en la base de datos
extensions:
    @docker exec -i {{DB_CONTAINER}} psql -U {{DB_USER}} -d {{DB_NAME}} -c "\dx"

# Estado rápido del contenedor
status:
    docker compose ps
