-- 0008_outbox_sync_rpc.sql
--
-- The server side of the outbox pusher: a single idempotent, generic RPC
-- the client calls with the already-resolved row-level upserts for one
-- local business event (see lib/data/local/tables/sync.dart's
-- SyncOutboxEntries doc comment — the client computes the payload once,
-- the server applies it atomically without re-deriving any business
-- rule). See SYNC.md for the full design and the shop_id substitution
-- this depends on client-side.
--
-- Deliberately generic (one RPC + one allow-list) rather than one
-- hand-written RPC per business event type: with 22 syncable tables and
-- growing, a per-event RPC would mean every new use case needs a new
-- migration just to sync — the allow-list plus dynamic per-table upsert
-- below gets the same safety (nothing outside the 22 known tables is
-- reachable, and this function is SECURITY INVOKER so every dynamic
-- INSERT still goes through that table's own RLS policy) without that
-- multiplying-migrations cost.

-- ── Idempotency ledger ──────────────────────────────────────────────────
--
-- SyncOutboxEntries.idempotencyKey (client-side) is generated once per
-- event and reused across every retry. This table is what makes that
-- meaningful server-side: a retried push after a dropped response (the
-- request succeeded but the client never saw the ack) must not double-
-- apply. Append-only by nature — a processed event is a permanent fact —
-- so it gets the same defense-in-depth as the business ledger tables.
create table processed_outbox_events (
  shop_id         uuid not null references shops(id) on delete cascade,
  idempotency_key text primary key,
  processed_at    timestamptz not null default clock_timestamp()
);

call apply_append_only_rls('processed_outbox_events');

-- ── Generic dynamic upsert for one syncable table ───────────────────────
--
-- p_row's keys become the column list; created_at/updated_at/synced_at
-- are deliberately expected to be absent from the client's payload (the
-- set_created_at/set_updated_at triggers from 0001_foundations.sql fill
-- those in unconditionally, exactly as they do for a direct PostgREST
-- insert — the outbox path does not bypass that server-authoritative
-- timestamp logic).
--
-- Append-only tables (cash_ledger_entries, stock_movements,
-- investor_repayments, due_payments, audit_log_entries) use
-- `on conflict do nothing` instead of `do update`: an append-only row is
-- a permanent fact, and forbid_update_or_delete() would reject the
-- `do update` branch anyway if a retry ever re-sent an id that made it
-- through on an earlier attempt whose ack was lost — this makes that
-- case a harmless no-op instead of a hard failure.
--
-- SECURITY INVOKER (the default — no `security definer` here,
-- deliberately unlike the onboarding RPCs in 0006): every dynamic
-- INSERT below runs as the calling user, so the same
-- apply_standard_rls/apply_append_only_rls owner-only-write policies
-- that protect a direct PostgREST call protect this path too. A staff
-- device (view-only, per the working plan's permission model) gets
-- exactly the same RLS rejection here as it would calling the REST API
-- directly — this function does not create a privilege escalation path.
create or replace function apply_jsonb_upsert(p_table text, p_row jsonb) returns void
language plpgsql as $$
declare
  cols text;
  vals text;
  updates text;
  is_append_only boolean;
begin
  if p_table not in (
    'categories', 'products', 'product_images', 'customers', 'investors',
    'investor_repayments', 'legacy_settlements', 'purchase_trips',
    'purchase_items', 'purchase_other_costs', 'sales', 'dues',
    'due_payments', 'rent_pricing_tiers', 'rent_transactions', 'expenses',
    'orders', 'fixed_assets', 'quick_captures', 'cash_ledger_entries',
    'stock_movements', 'audit_log_entries'
  ) then
    -- Deliberately not reachable for shops/shop_members/app_settings
    -- (composite or bespoke keys, and their own dedicated RPCs/flows —
    -- see 0006_owner_onboarding_rpc.sql) or anything outside `public`.
    raise exception 'table % is not sync-eligible via apply_outbox_event', p_table;
  end if;

  is_append_only := p_table in (
    'cash_ledger_entries', 'stock_movements', 'investor_repayments',
    'due_payments', 'audit_log_entries'
  );

  select string_agg(format('%I', key), ', '),
         string_agg(format('%L', p_row ->> key), ', ')
    into cols, vals
  from jsonb_object_keys(p_row) as key;

  if cols is null then
    raise exception 'apply_jsonb_upsert called with an empty row for table %', p_table;
  end if;

  if is_append_only then
    execute format(
      'insert into public.%I (%s) values (%s) on conflict (id) do nothing',
      p_table, cols, vals
    );
  else
    select string_agg(format('%I = %L', key, p_row ->> key), ', ')
      into updates
    from jsonb_object_keys(p_row) as key
    where key <> 'id';

    execute format(
      'insert into public.%I (%s) values (%s) on conflict (id) do update set %s',
      p_table, cols, vals, updates
    );
  end if;
end;
$$;

revoke all on function apply_jsonb_upsert(text, jsonb) from public;
revoke execute on function apply_jsonb_upsert(text, jsonb) from anon;
grant execute on function apply_jsonb_upsert(text, jsonb) to authenticated;

-- ── The RPC the outbox pusher actually calls ────────────────────────────
--
-- p_upserts is a JSON array of `{"table": "...", "row": {...}}` objects —
-- one local business event (e.g. "record a purchase trip") often touches
-- several tables (the trip row, its items, its other-cost lines) in one
-- disciplined transaction client-side (see PurchaseDao.saveTrip's doc
-- comment); this RPC preserves that atomicity server-side too, since a
-- plpgsql function body is one transaction — either every upsert in the
-- batch lands, or none do.
create or replace function apply_outbox_event(p_idempotency_key text, p_upserts jsonb) returns void
language plpgsql as $$
declare
  v_shop_id uuid;
  upsert_entry jsonb;
begin
  if exists (select 1 from processed_outbox_events where idempotency_key = p_idempotency_key) then
    -- Already applied on an earlier attempt whose ack the client never
    -- saw — exactly-once semantics for a retried push, silently.
    return;
  end if;

  v_shop_id := my_shop_id();
  if v_shop_id is null then
    raise exception 'caller has no shop membership';
  end if;

  for upsert_entry in select * from jsonb_array_elements(p_upserts)
  loop
    perform apply_jsonb_upsert(upsert_entry ->> 'table', upsert_entry -> 'row');
  end loop;

  insert into processed_outbox_events (shop_id, idempotency_key)
    values (v_shop_id, p_idempotency_key);
end;
$$;

revoke all on function apply_outbox_event(text, jsonb) from public;
revoke execute on function apply_outbox_event(text, jsonb) from anon;
grant execute on function apply_outbox_event(text, jsonb) to authenticated;
