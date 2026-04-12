# TallerPro360

Monorepo inicial para el ecosistema digital de talleres descrito en el PRD.

## Estructura

- `apps/mobile`: app movil Flutter para asesor y tecnico.
- `services/api`: backend FastAPI.
- `infra/docker`: infraestructura local con PostgreSQL y el backend API.

## Requisitos locales

- Python 3.12+
- `uv`
- Docker
- Flutter SDK
- Java 17

## Backend

```bash
cd services/api
uv sync --dev
uv run ruff check src tests
uv run pytest
uv run uvicorn tallerpro360_api.app:app --host 0.0.0.0 --port 8000 --reload
```

## Infra local

```bash
cd infra/docker
docker compose up --build -d
```

Esto levanta PostgreSQL y el backend con persistencia local para `/app/media`.

## Observabilidad

- `GET /health` para health checks.
- `GET /api/v1/meta` para metadata basica del servicio.
- `GET /metrics` para scraping Prometheus.
- Logging estructurado JSON a stdout para requests y errores.

El workflow `Backend Health Monitor` verifica `/health` y `/metrics` contra produccion usando el secret `BACKEND_HEALTHCHECK_URL`.

Compose local expone HTTP solamente. En Railway el TLS/HTTPS lo termina la plataforma, por lo que no se agrega nginx ni Traefik al repo.

## CI/CD

- `CI`: lint y tests de backend + analyze/test de Flutter en PRs y pushes a `main`.
- `Mobile Release Builds`: genera APK en `main` y construye IPA solo si existe `apps/mobile/ios`.
- `Deploy Backend to Railway`: despliega `services/api` a Railway en pushes a `main` despues de pasar checks de backend.
- `Backend Health Monitor`: revisa `/health` y `/metrics` en produccion cada 15 minutos y falla el workflow ante cualquier error.
- `PostgreSQL Backup`: ejecuta `pg_dump` programado y sube el respaldo como artifact.

## Railway

Usa [services/api/.env.example](services/api/.env.example) como plantilla de variables de entorno para produccion. `DATABASE_URL` debe incluir `sslmode=require` en Railway/PostgreSQL administrado. En Railway define `RUN_DB_MIGRATIONS=true` y conserva `AUTO_CREATE_TABLES=false` para que el contenedor aplique Alembic antes de iniciar la API.

## Tareas de VS Code

- `Run TallerPro360 API`
- `Run TallerPro360 Postgres`
