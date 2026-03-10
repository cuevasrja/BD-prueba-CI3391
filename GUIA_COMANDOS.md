# Guia de uso de comandos

## Objetivo
Esta guia explica como usar los comandos definidos en justfile para administrar una base de datos PostgreSQL local con Docker.

## Requisitos
- Docker instalado
- Docker Compose disponible
- just instalado
- psql en el host (opcional, solo para conexion desde la terminal local)

## Archivos importantes
- justfile: comandos de automatizacion
- docker-compose.yml: definicion del servicio PostgreSQL
- sql/schema.sql: creacion de tablas y llaves
- sql/load.sql: carga de datos de prueba
- .env.example: variables de entorno de referencia

## Configuracion inicial
1. Copia variables de ejemplo:

```bash
cp .env.example .env
```

2. Si lo necesitas, edita .env para cambiar:
- DB_NAME
- DB_USER
- DB_PASSWORD
- DB_PORT
- DB_CONTAINER

## Comandos disponibles

### Ver lista de recetas

```bash
just --list
```

### Levantar la base de datos
Inicia el contenedor de PostgreSQL en segundo plano.

```bash
just up
```

### Ver estado
Muestra el estado de los servicios.

```bash
just status
```

### Ver logs
Sigue los logs de PostgreSQL.

```bash
just logs
```

### Esperar a que la BD este lista
Receta interna para sincronizar antes de ejecutar SQL.

```bash
just wait-db
```

### Ejecutar esquema
Crea tablas y restricciones desde sql/schema.sql.

```bash
just schema
```

### Cargar data de prueba
Ejecuta sql/load.sql.

```bash
just load
```

### Reinicializar todo el dataset
Limpia volumen, levanta el contenedor, crea esquema y carga data.

```bash
just reset-data
```

### Ejecutar un script SQL especifico
El archivo se toma relativo a la carpeta sql.

```bash
just run-sql schema.sql
just run-sql load.sql
```

### Ejecutar SQL inline
Ejecuta una consulta puntual.

```bash
just exec-sql "select now();"
just exec-sql "select count(*) from bebedor;"
```

### Abrir psql dentro del contenedor

```bash
just psql
```

### Conectar desde tu terminal local
Requiere cliente psql instalado en tu host.

```bash
just psql-host
```

### Detener contenedor sin borrar datos

```bash
just stop
```

### Bajar stack sin borrar volumen

```bash
just down
```

### Limpiar todo (incluye datos)
Elimina contenedor, red y volumen. Se pierde la informacion cargada.

```bash
just clean
```

## Flujo recomendado de trabajo

### Primera vez

```bash
just up
just schema
just load
```

### Cuando quieras reiniciar desde cero

```bash
just reset-data
```

### Consulta rapida

```bash
just exec-sql "select * from fuente_soda limit 10;"
```

## Solucion de problemas

### Error: relation does not exist
Causa: se intento cargar datos antes de crear el esquema.

Solucion:

```bash
just schema
just load
```

### Error de conexion al arrancar
Causa: PostgreSQL aun no termina de iniciar.

Solucion:
- Usa recetas que ya esperan disponibilidad (run-sql, schema, load, exec-sql, reset-data).
- Si ejecutas manualmente, espera unos segundos y reintenta.

### Puerto ocupado
Si DB_PORT esta en uso, cambia DB_PORT en .env y reinicia:

```bash
just down
just up
```
