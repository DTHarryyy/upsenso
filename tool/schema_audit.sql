-- =============================================================================
-- tool/schema_audit.sql  —  UPSENSO schema census (READ-ONLY)
-- =============================================================================
-- Repeatable, non-destructive discovery queries backing
-- docs/UPSENSO_DB_ARCHITECTURE_AUDIT.md. Run each section against the prod DB
-- (or a restored clone) to reproduce the audit's numbers and to re-measure after
-- each normalization phase — the issue counts should trend to zero.
--
-- SAFE: every statement is a SELECT. Nothing is modified.
-- Run one section at a time (Supabase SQL editor) or the whole file via psql.
--
-- NOTE ON EMPTY DB: after the 2026-07-04 reset the DB has 0 rows, so the
-- data-dependent sections (§3 dead columns, §11 orphans) return nothing. Run
-- them against a populated clone, or use the pre-reset snapshots in
-- backups/reset-20260704/ (see tool note at bottom).
-- =============================================================================

-- §1 ── Object inventory -------------------------------------------------------
select
  (select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace
     where n.nspname='public' and c.relkind='r')                       as base_tables,
  (select count(*) from pg_views where schemaname='public')            as views,
  (select count(*) from pg_matviews where schemaname='public')         as matviews,
  (select count(*) from pg_trigger t join pg_class c on c.oid=t.tgrelid
     join pg_namespace n on n.oid=c.relnamespace
     where n.nspname='public' and not t.tgisinternal)                  as triggers,
  (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
     where n.nspname='public')                                         as functions,
  (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
     where n.nspname='public' and p.prosecdef)                         as security_definer_fns,
  (select count(*) from information_schema.sequences
     where sequence_schema='public')                                   as sequences,
  (select count(*) from pg_indexes where schemaname='public')          as indexes;

-- §2 ── Per-table shape (column count → wide-table detector) -------------------
select table_name, count(*) as cols
from information_schema.columns
where table_schema='public'
group by table_name
order by cols desc, table_name;

-- §3 ── Dead / near-dead column census (NEEDS DATA) ---------------------------
-- Generates the per-column count(col) vs count(*) query for every table.
-- Copy the output column `q`, run it, and read the null ratios. (On an empty DB
-- this yields no signal — use a populated clone or the backup snapshots.)
select format(
  'select %L as tbl, count(*) as rows, %s from public.%I',
  table_name,
  string_agg(format('count(%I) as %I', column_name, column_name), ', '),
  table_name) as q
from information_schema.columns
where table_schema='public'
group by table_name
order by table_name;

-- §4 ── FK-gap report: every *_id column with NO foreign key ------------------
-- Excludes known non-FK id-like names (booleans, external identifiers).
select c.table_name, c.column_name, c.data_type, c.is_nullable
from information_schema.columns c
where c.table_schema='public'
  and c.column_name like '%\_id'
  and c.data_type <> 'boolean'
  and c.column_name not in ('tax_id','reference_id','show_order_id')   -- external / polymorphic / bool
  and not exists (
    select 1
    from information_schema.key_column_usage kcu
    join information_schema.table_constraints tc
      on tc.constraint_name=kcu.constraint_name and tc.constraint_schema=kcu.constraint_schema
    where tc.constraint_type='FOREIGN KEY'
      and kcu.table_schema='public' and kcu.table_name=c.table_name
      and kcu.column_name=c.column_name)
order by c.table_name, c.column_name;

-- §5 ── Type-consistency: id columns that are TEXT (vs uuid elsewhere) ---------
select c.table_name, c.column_name, c.data_type
from information_schema.columns c
where c.table_schema='public'
  and (c.column_name='id' or c.column_name like '%\_id')
  and c.data_type = 'text'
order by c.table_name, c.column_name;

-- §6 ── Duplicate / redundant indexes (same table, same key columns) ----------
select t.relname as tbl, array_to_string(ix.indkey,' ') as keycols,
       count(*) as n, string_agg(i.relname, ', ') as idxs
from pg_index ix
join pg_class i on i.oid=ix.indexrelid
join pg_class t on t.oid=ix.indrelid
join pg_namespace nsp on nsp.oid=t.relnamespace
where nsp.nspname='public'
group by t.relname, array_to_string(ix.indkey,' ')
having count(*) > 1
order by t.relname;

-- §7 ── FK columns with no supporting (leading) index -------------------------
-- Unindexed FKs make parent deletes and RLS joins scan the child table.
with fk as (
  select tc.table_name, kcu.column_name,
         (select attnum from pg_attribute a
            join pg_class c on c.oid=a.attrelid
            join pg_namespace n on n.oid=c.relnamespace
           where n.nspname='public' and c.relname=tc.table_name
             and a.attname=kcu.column_name) as attnum
  from information_schema.table_constraints tc
  join information_schema.key_column_usage kcu
    on kcu.constraint_name=tc.constraint_name and kcu.constraint_schema=tc.constraint_schema
  where tc.constraint_type='FOREIGN KEY' and tc.table_schema='public'
)
select fk.table_name, fk.column_name
from fk
where not exists (
  select 1 from pg_index ix
  join pg_class t on t.oid=ix.indrelid
  join pg_namespace n on n.oid=t.relnamespace
  where n.nspname='public' and t.relname=fk.table_name
    and (string_to_array(array_to_string(ix.indkey,' '),' '))[1] = fk.attnum::text)
order by fk.table_name, fk.column_name;

-- §8 ── Delta-sync readiness: synced tables missing a (business_id, updated_at)
--       index or the set_updated_at trigger --------------------------------
select c.relname as tbl,
  exists (select 1 from information_schema.columns col
            where col.table_schema='public' and col.table_name=c.relname
              and col.column_name='updated_at')                         as has_updated_at,
  exists (select 1 from pg_trigger tg where tg.tgrelid=c.oid and not tg.tgisinternal
            and pg_get_triggerdef(tg.oid) ilike '%set_updated_at%')      as has_touch_trigger,
  exists (select 1 from pg_indexes i where i.schemaname='public' and i.tablename=c.relname
            and i.indexdef ilike '%business_id%updated_at%')             as has_delta_index
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind='r'
order by c.relname;

-- §9 ── RLS coverage: enabled but 0 policies, or disabled ---------------------
select c.relname as tbl, c.relrowsecurity as rls_enabled,
       (select count(*) from pg_policies p where p.schemaname='public' and p.tablename=c.relname) as policies
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind='r'
  and (c.relrowsecurity = false
       or (select count(*) from pg_policies p where p.schemaname='public' and p.tablename=c.relname) = 0)
order by c.relname;

-- §10 ── Duplicate/overlapping RLS policies (heuristic: >4 policies) -----------
select tablename, count(*) as n,
       string_agg(policyname||'['||cmd||']', ', ' order by policyname) as policies
from pg_policies where schemaname='public'
group by tablename
having count(*) > 4
order by count(*) desc;

-- §11 ── Orphan-row check generator for FK candidates (NEEDS DATA) -------------
-- Example (refund_authorizations.transaction_id → transactions.id):
--   select count(*) from refund_authorizations ra
--   left join transactions t on t.id = ra.transaction_id
--   where ra.transaction_id is not null and t.id is null;   -- must be 0 to add FK

-- §12 ── SECURITY DEFINER function surface (review search_path + caller checks)
select p.proname, pg_get_function_identity_arguments(p.oid) as args
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.prosecdef
order by p.proname;

-- =============================================================================
-- Dead-column evidence from pre-reset data (no live rows):
--   node scratchpad/null_census.js against backups/reset-20260704/*.json
--   → e.g. audit_logs.employee_id 0/377, inventory_levels.variant_id 0/3.
-- =============================================================================
