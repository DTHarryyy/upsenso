<#
  UPSENSO — free logical backup of the production database (Windows / PowerShell).

  No paid Supabase plan required. Runs pg_dump to a timestamped, compressed
  custom-format file and rotates old ones. This is your safety net on Free —
  it does NOT replace PITR, but it's vastly better than nothing for a POS.

  ── ONE-TIME SETUP ──────────────────────────────────────────────────────────
  1. Install Postgres client tools (gives you pg_dump / pg_restore):
       winget install -e --id PostgreSQL.PostgreSQL
     (or use the binaries bundled with the Supabase CLI / Postgres.app)

  2. Get your connection string:
       Supabase Dashboard -> Project Settings -> Database
       -> "Connection string" -> URI tab -> "Session pooler" (IPv4-friendly).
     It looks like:
       postgresql://postgres.<ref>:<PASSWORD>@aws-0-<region>.pooler.supabase.com:5432/postgres

  3. Store it as an environment variable (NEVER hardcode it in this file):
       setx SUPABASE_DB_URL "postgresql://...."
     Then open a NEW terminal so the variable is visible.

  4. Test it:
       powershell -ExecutionPolicy Bypass -File scripts\backup_db.ps1

  ── SCHEDULE (daily) ────────────────────────────────────────────────────────
  See scripts/README_backups.md for the Task Scheduler command.

  ── RESTORE ─────────────────────────────────────────────────────────────────
  pg_restore --clean --if-exists --no-owner -d "$env:SUPABASE_DB_URL" <file.dump>
#>
param(
  [int]$KeepLast = 14,      # how many recent dumps to retain
  [string]$Schema = 'public' # app data + RLS + functions + triggers live here
)
$ErrorActionPreference = 'Stop'

$dbUrl = $env:SUPABASE_DB_URL
if ([string]::IsNullOrWhiteSpace($dbUrl)) {
  Write-Error "SUPABASE_DB_URL is not set. See the setup notes at the top of this script."
  exit 1
}

if (-not (Get-Command pg_dump -ErrorAction SilentlyContinue)) {
  Write-Error "pg_dump not found on PATH. Install Postgres client tools: winget install -e --id PostgreSQL.PostgreSQL"
  exit 1
}

$backupDir = Join-Path $PSScriptRoot '..\backups'
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }

$ts  = Get-Date -Format 'yyyyMMdd-HHmmss'
$out = Join-Path $backupDir "upsenso-$Schema-$ts.dump"

Write-Host "[backup] dumping schema '$Schema' -> $out"
# -Fc = compressed custom format (restore selectively with pg_restore).
# --no-owner = restorable into a fresh project without role-ownership errors.
& pg_dump $dbUrl --schema=$Schema --no-owner -Fc -f $out
if ($LASTEXITCODE -ne 0) {
  Write-Error "[backup] pg_dump FAILED (exit $LASTEXITCODE). No backup was written."
  exit $LASTEXITCODE
}

$sizeMB = [Math]::Round((Get-Item $out).Length / 1MB, 2)
Write-Host "[backup] OK -> $out ($sizeMB MB)"

# Rotation: keep the newest $KeepLast dumps, delete older ones.
Get-ChildItem $backupDir -Filter 'upsenso-*.dump' |
  Sort-Object LastWriteTime -Descending |
  Select-Object -Skip $KeepLast |
  ForEach-Object { Remove-Item $_.FullName -Force; Write-Host "[backup] rotated out $($_.Name)" }
