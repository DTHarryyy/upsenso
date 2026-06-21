#!/usr/bin/env bash
# UPSENSO — free logical backup of the production database (macOS/Linux/CI).
# Mirror of backup_db.ps1. Requires pg_dump on PATH and SUPABASE_DB_URL set.
#
#   export SUPABASE_DB_URL="postgresql://postgres.<ref>:<PASSWORD>@aws-0-<region>.pooler.supabase.com:5432/postgres"
#   ./scripts/backup_db.sh
#
# Restore: pg_restore --clean --if-exists --no-owner -d "$SUPABASE_DB_URL" <file.dump>
set -euo pipefail

KEEP_LAST="${KEEP_LAST:-14}"
SCHEMA="${SCHEMA:-public}"

if [[ -z "${SUPABASE_DB_URL:-}" ]]; then
  echo "SUPABASE_DB_URL is not set. Get it from Supabase -> Project Settings -> Database -> Connection string (Session pooler)." >&2
  exit 1
fi
command -v pg_dump >/dev/null 2>&1 || { echo "pg_dump not found. Install Postgres client tools." >&2; exit 1; }

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/backups"
mkdir -p "$DIR"
TS="$(date +%Y%m%d-%H%M%S)"
OUT="$DIR/upsenso-$SCHEMA-$TS.dump"

echo "[backup] dumping schema '$SCHEMA' -> $OUT"
pg_dump "$SUPABASE_DB_URL" --schema="$SCHEMA" --no-owner -Fc -f "$OUT"
echo "[backup] OK -> $OUT ($(du -h "$OUT" | cut -f1))"

# Rotation: keep the newest $KEEP_LAST dumps.
ls -1t "$DIR"/upsenso-*.dump 2>/dev/null | tail -n "+$((KEEP_LAST + 1))" | while read -r f; do
  rm -f "$f"; echo "[backup] rotated out $(basename "$f")"
done
