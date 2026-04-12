#!/bin/sh

set -eu

run_db_migrations="$(printf '%s' "${RUN_DB_MIGRATIONS:-false}" | tr '[:upper:]' '[:lower:]')"

case "$run_db_migrations" in
  1|true|yes)
    echo "Running Alembic migrations before startup"
    alembic upgrade head
    ;;
esac

exec uvicorn tallerpro360_api.app:app \
  --host 0.0.0.0 \
  --port "${PORT:-8000}" \
  --no-access-log