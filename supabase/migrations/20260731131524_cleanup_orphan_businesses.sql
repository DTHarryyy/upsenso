-- =============================================================================
-- Clean up 8 orphaned businesses left by the duplicate-signup bug (2026-07-26).
--
-- WHAT HAPPENED: business_repository_impl.createBusiness minted a fresh
-- Uuid().v4() on every call, so each retry of a failing signup created a BRAND
-- NEW server-side business. The INSERT commits immediately; the flow then died
-- before branches/roles/receipt_settings/users landed, and the catch only marked
-- the LOCAL row sync-failed — it never reused the id or cleaned up the remote
-- orphan. One user tapped retry 8 times in 100 seconds → 8 orphans, all owned by
-- the same auth user, each carrying nothing but the row plus what the AFTER
-- INSERT triggers added (a subscription + one subscription_events link).
--
-- Side effect that made it urgent: BusinessRemoteDs.getBusinessByOwner uses
-- .maybeSingle(), which THROWS on >1 row — that account could no longer start
-- online or sync at all.
--
-- 20260731131554 (unique index on owner_id + atomic onboarding RPC) makes the
-- whole class impossible. This file only removes the existing wreckage, and must
-- run BEFORE the unique index or the index build fails.
--
-- APPLIED to prod 2026-07-31 (8 businesses removed; 1 remains).
--
-- SAFETY: subscription_events has NO FK to businesses, so its rows are deleted
-- explicitly first (whole per-business chains — never a partial chain, which
-- would break hash verification). Everything else cascades. The §1 assertion
-- refuses to run if any target ever held real business data; on top of that,
-- transactions / audit_logs / stock_ledger / refunds / purchase_orders /
-- purchase_order_lines / product_variants are all FK'd NO ACTION, so a target
-- with financial history would make the DELETE error out rather than destroy it.
-- Do not "fix" those FKs to CASCADE to make this run.
--
-- ROLLBACK: none — these rows carry no business data (that is asserted below).
-- Restoring them would only recreate the broken state. If a target ever fails
-- the assertion, STOP and investigate rather than relaxing it.
-- =============================================================================

DO $$
DECLARE
  -- Explicit id list, captured 2026-07-31. Deliberately NOT `WHERE name =
  -- 'Cruz Store'` — a name match could sweep up a real business created later.
  v_ids uuid[] := ARRAY[
    '27fb57f1-5923-4cfd-b404-89fd8c910bd2',
    'bfbce7e6-34db-4bcb-aecd-dd60c5a9fc78',
    'a24e8f50-6c6c-4877-bc87-82fea2a00ec5',
    'c4a29ca1-8e63-41b3-a30f-5c219bacc61d',
    'dd11fe21-edf1-4f0b-b257-2ebe674d674c',
    '04b3dab9-17cf-422e-b770-af59af08b078',
    '89b340bd-500f-40d9-8e29-3e176ea44a06',
    '8ef2db6a-33f6-4140-9cbf-2fcd99954943'
  ]::uuid[];
  v_bad     int;
  v_deleted int;
BEGIN
  -- ── 1. Refuse to delete anything that ever held real business data ─────────
  -- audit_logs is deliberately NOT a blanket check: each orphan carries exactly
  -- 16 PERMISSION_TABLE_CHANGED / business_modules rows written by
  -- trg_provision_modules at the business's own created_at timestamp. That is
  -- the orphan's own provisioning noise, not user activity — verified
  -- 2026-07-31: 128 such rows across the 8, ZERO of them written at any other
  -- time, and no other action_type at all. Any audit row that is NOT that
  -- trigger output means somebody actually used the business, and blocks.
  SELECT count(*) INTO v_bad
  FROM public.businesses b
  WHERE b.id = ANY(v_ids)
    AND (
      EXISTS (SELECT 1 FROM public.transactions   x WHERE x.business_id = b.id) OR
      EXISTS (SELECT 1 FROM public.stock_ledger   x WHERE x.business_id = b.id) OR
      EXISTS (SELECT 1 FROM public.refunds        x WHERE x.business_id = b.id) OR
      EXISTS (SELECT 1 FROM public.purchase_orders x WHERE x.business_id = b.id) OR
      EXISTS (SELECT 1 FROM public.products       x WHERE x.business_id = b.id) OR
      EXISTS (SELECT 1 FROM public.employees      x WHERE x.business_id = b.id) OR
      EXISTS (SELECT 1 FROM public.branches       x WHERE x.business_id = b.id) OR
      EXISTS (
        SELECT 1 FROM public.audit_logs x
        WHERE x.business_id = b.id
          AND NOT (x.action_type = 'PERMISSION_TABLE_CHANGED'
                   AND x.entity_type = 'business_modules'
                   AND x.created_at = b.created_at)
      )
    );

  IF v_bad > 0 THEN
    RAISE EXCEPTION
      'ABORT: % of the targeted businesses hold real data. These were expected to be empty orphans — investigate before deleting anything.',
      v_bad;
  END IF;

  -- ── 2. Drain the permission-audited children FIRST ────────────────────────
  -- business_modules, user_permissions and branch_permissions each carry a
  -- log_permission_change() trigger that INSERTs an audit_logs row on DELETE.
  -- Letting them go via the businesses cascade deadlocks against itself: the
  -- trigger's insert references a business_id that the same statement is
  -- removing, and audit_logs.business_id is FK'd NO ACTION →
  --   "insert or update on table audit_logs violates foreign key constraint".
  -- Deleting them here, while the parent still exists, lets those trigger rows
  -- land cleanly; §3 then clears them along with the rest.
  DELETE FROM public.business_modules    WHERE business_id = ANY(v_ids);
  DELETE FROM public.user_permissions    WHERE business_id = ANY(v_ids);
  DELETE FROM public.branch_permissions  WHERE business_id = ANY(v_ids);

  -- ── 3. subscription_events has no FK — clear whole chains explicitly ───────
  DELETE FROM public.subscription_events WHERE business_id = ANY(v_ids);

  -- audit_logs is FK'd NO ACTION, so it would block the delete below. Safe to
  -- clear only because §1 proved every pre-existing row is this business's own
  -- provisioning trigger output; §2 just added its DELETE counterparts.
  DELETE FROM public.audit_logs WHERE business_id = ANY(v_ids);

  -- ── 4. The businesses themselves; the remaining children cascade ──────────
  DELETE FROM public.businesses WHERE id = ANY(v_ids);
  GET DIAGNOSTICS v_deleted = ROW_COUNT;

  RAISE NOTICE 'Deleted % orphan business row(s).', v_deleted;
END;
$$;

-- ── 4. Post-condition: no owner may still hold duplicates, or the unique index
-- in the next migration would fail to build.
DO $$
DECLARE
  v_dupes int;
BEGIN
  SELECT count(*) INTO v_dupes
  FROM (
    SELECT owner_id FROM public.businesses
    WHERE owner_id IS NOT NULL
    GROUP BY owner_id HAVING count(*) > 1
  ) d;

  IF v_dupes > 0 THEN
    RAISE EXCEPTION
      'ABORT: % owner(s) still hold more than one business — resolve before creating businesses_owner_id_key.',
      v_dupes;
  END IF;
END;
$$;
