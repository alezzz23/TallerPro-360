# TallerPro360 API

Backend inicial en FastAPI para el ecosistema de gestion de talleres.

## Desarrollo

```bash
uv sync --dev
uv run ruff check src tests
uv run pytest
uv run uvicorn tallerpro360_api.app:app --host 0.0.0.0 --port 8000 --reload
```

## Endpoints operativos

- `GET /health`
- `GET /api/v1/meta`
- `GET /api/v1/db-check`
- `GET /metrics`

## Docker

```bash
docker build -t tallerpro360-api .
```

Para pruebas locales con PostgreSQL y media persistente, usa `../../infra/docker/compose.yml`.

El contenedor escribe logs JSON a stdout, expone un health check en `/health` y arranca mediante `scripts/start.sh`. Si `RUN_DB_MIGRATIONS=true`, ejecuta `alembic upgrade head` antes de levantar uvicorn; si no, inicia la API directamente.

## Railway

- Archivo de despliegue: `railway.toml`
- Plantilla de variables: `.env.example`
- Railway termina TLS/HTTPS en produccion; el contenedor se mantiene en HTTP interno.
- `DATABASE_URL` debe llevar `sslmode=require` para PostgreSQL administrado.
- Configura `AUTO_CREATE_TABLES=false` en produccion para no depender de `create_all` en arranque.
- Configura `RUN_DB_MIGRATIONS=true` en Railway para aplicar Alembic en cada arranque del contenedor.

En compose local se deja `RUN_DB_MIGRATIONS=false` porque el entorno de desarrollo sigue usando `AUTO_CREATE_TABLES=true`.

## Alertas

El workflow `Backend Health Monitor` consulta `BACKEND_HEALTHCHECK_URL/health` y `BACKEND_HEALTHCHECK_URL/metrics` cada 15 minutos. Si alguna verificacion falla, GitHub Actions marca el workflow como fallido y usa las notificaciones nativas de GitHub como superficie de alerta.

## Backups

```bash
DATABASE_URL="postgresql://..." ../../infra/scripts/pg_backup.sh
```

El workflow `PostgreSQL Backup` usa ese mismo script con `pg_dump` y sube el respaldo comprimido como artifact.
