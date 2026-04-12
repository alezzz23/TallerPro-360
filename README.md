# TallerPro360

Monorepo inicial para el ecosistema digital de talleres descrito en el PRD.

## Estructura

- `apps/mobile`: app movil Flutter para asesor y tecnico.
- `services/api`: backend FastAPI.
- `infra/docker`: infraestructura local con PostgreSQL.

## Requisitos locales

- Python 3.12+
- `uv`
- Docker
- Flutter SDK

## Backend

```bash
cd services/api
uv sync
```

## Base de datos

```bash
cd infra/docker
docker compose up -d
```

## Tareas de VS Code

- `Run TallerPro360 API`
- `Run TallerPro360 Postgres`

## Mobile
    
Flutter no esta instalado en esta maquina, por eso el modulo movil queda como scaffold manual.

Cuando instales Flutter:

```bash
cd apps/mobile
flutter create .
flutter pub get
flutter run
```
