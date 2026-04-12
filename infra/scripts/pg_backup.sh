#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "DATABASE_URL is required" >&2
  exit 1
fi

output_dir="${1:-${BACKUP_OUTPUT_DIR:-$PWD/infra/backups}}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_path="$output_dir/tallerpro360-postgres-$timestamp.sql.gz"

mkdir -p "$output_dir"
pg_dump --no-owner --no-privileges "$DATABASE_URL" | gzip -c > "$backup_path"

echo "$backup_path"