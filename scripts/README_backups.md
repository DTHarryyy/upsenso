# Free database backups (Supabase Free plan)

Supabase Free has **no automated backups / no PITR**. For a POS that's not
acceptable — so this is a free, self-run `pg_dump` routine that gives you real,
restorable backups. It does **not** replace PITR (you lose data *between* dumps),
so upgrade to Pro for daily backups + PITR as soon as you have revenue.

Scripts:
- `backup_db.ps1` — Windows / PowerShell (your platform)
- `backup_db.sh` — macOS / Linux / CI

Backups are written to `backups/` (gitignored) as compressed `*.dump` files and
rotated (newest 14 kept by default).

---

## 1. One-time setup
1. **Install `pg_dump`** (Postgres client tools):
   ```
   winget install -e --id PostgreSQL.PostgreSQL
   ```
2. **Get your connection string:** Supabase Dashboard → *Project Settings →
   Database → Connection string → URI*, choose **Session pooler** (IPv4-friendly).
3. **Store it as an env var** (never hardcode the password):
   ```
   setx SUPABASE_DB_URL "postgresql://postgres.<ref>:<PASSWORD>@aws-0-<region>.pooler.supabase.com:5432/postgres"
   ```
   Open a **new** terminal afterward.
4. **Test:**
   ```
   powershell -ExecutionPolicy Bypass -File scripts\backup_db.ps1
   ```
   You should see a `.dump` appear in `backups/`.

## 2. Schedule a daily backup (Windows Task Scheduler)
Run once in an **admin** PowerShell (adjust the path):
```powershell
$action  = New-ScheduledTaskAction -Execute 'powershell.exe' `
  -Argument '-ExecutionPolicy Bypass -File "C:\Projects\pos\scripts\backup_db.ps1"'
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
Register-ScheduledTask -TaskName 'UpsensoDbBackup' -Action $action -Trigger $trigger `
  -Description 'Daily logical backup of the Upsenso production database'
```
> The scheduled task runs as your user, so it inherits `SUPABASE_DB_URL` set via
> `setx`. For a service account, set the env var for that account instead.

(Linux/macOS: `0 2 * * *  SUPABASE_DB_URL=... /path/scripts/backup_db.sh`)

## 3. Restore
```
pg_restore --clean --if-exists --no-owner -d "%SUPABASE_DB_URL%" backups\upsenso-public-YYYYMMDD-HHMMSS.dump
```
`--clean --if-exists` drops existing objects first so the restore is idempotent.

## 4. What's covered — and what isn't
- ✅ **Covered:** the `public` schema — all business data (sales, products,
  inventory, employees…), RLS policies, functions, and triggers. This is the
  irreplaceable part.
- ⚠️ **Not covered by default:** `auth.users` (the login accounts) and Storage
  objects (product images), which are managed by Supabase. Owners can re-sign-up
  after a full restore. To also capture logins, add `--schema=auth` to the dump
  (heavier; can conflict on restore into a fresh project — test it).

## 5. Operational advice
- **Copy dumps off the machine** (cloud drive / another disk). A backup on the
  same laptop that dies with it isn't a backup.
- **Test a restore** into a scratch project at least once — an untested backup
  is a guess.
- **Upgrade to Pro** for PITR the moment you can; this routine is the floor, not
  the goal.
