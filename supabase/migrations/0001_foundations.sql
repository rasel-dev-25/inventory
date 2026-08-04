-- 0001_foundations.sql
--
-- Extensions, enum types, the shop/membership tables every other table's
-- RLS policy keys off of, and the trigger/helper functions the rest of
-- the schema is built from. See ARCHITECTURE.md and lib/data/local/ for
-- the local Drift schema this mirrors.
--
-- Design notes:
--   * Money is BIGINT minor units everywhere (never NUMERIC or MONEY —
--     see the working plan's money-handling research).
--   * Enums are native Postgres enum types, matching
--     lib/domain/entities/enums.dart one-for-one, for the same reason
--     the local schema uses Drift's textEnum<T>() instead of free text:
--     a typo in a string can't compile, but it also can't INSERT.
--   * The three sync-infrastructure tables in the local schema
--     (SyncOutboxEntries, SyncPendingUploads, SyncCursors) are NOT
--     mirrored here — they are purely client-side bookkeeping (the
--     outbox queue, the upload queue, the pull cursor), not business
--     data, so there is nothing for them to sync *to*.
--   * shop_members exists only server-side — a local device only needs
--     to know its own role, not the full membership list, but Postgres
--     needs the full table to enforce RLS for every member.

create extension if not exists pgcrypto;

-- ── Enum types, one per lib/domain/entities/enums.dart enum ────────────

create type payment_method as enum ('cash', 'mobile_banking', 'bank_transfer');
create type fund_source_type as enum ('shop', 'investor');
create type investment_type as enum ('cash_loan', 'cash_mudaraba', 'cash_musharaka', 'goods_in_kind');
create type profit_payout_cycle as enum ('daily', 'monthly', 'per_contract');
create type payment_status as enum ('full_cash', 'partial', 'full_due');
create type due_status as enum ('pending', 'partially_paid', 'paid');
create type due_source_type as enum ('sale', 'rent');
create type rent_status as enum ('active', 'returned', 'overdue', 'treated_as_stolen');
create type order_status as enum ('pending', 'fulfilled', 'cancelled');
create type quick_capture_type as enum ('voice_note', 'photo_note');
create type quick_capture_status as enum ('pending', 'converted');
create type expense_category as enum ('monthly_rent', 'daily_other');
create type repayment_type as enum ('capital_return', 'profit_share');
create type fixed_asset_source as enum ('shop_cash_purchase', 'converted_from_stock');
create type legacy_settlement_status as enum ('pending', 'settled');
create type shop_member_role as enum ('owner', 'staff');

-- ── Shops and membership ────────────────────────────────────────────────

create table shops (
  id         uuid primary key,
  name       text not null,
  created_at timestamptz not null default clock_timestamp()
);

create table shop_members (
  shop_id    uuid not null references shops(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  role       shop_member_role not null,
  created_at timestamptz not null default clock_timestamp(),
  primary key (shop_id, user_id)
);

-- Per-request cache of the caller's shop id, avoiding a repeated
-- shop_members lookup inside every RLS policy on every row. SECURITY
-- DEFINER so a user cannot spoof this by creating their own same-named
-- function; STABLE so Postgres can cache the result within one query.
create or replace function my_shop_id() returns uuid
language sql stable security definer as $$
  select shop_id from shop_members where user_id = auth.uid() limit 1;
$$;

create or replace function is_owner() returns boolean
language sql stable security definer as $$
  select exists (
    select 1 from shop_members
    where user_id = auth.uid() and role = 'owner'
  );
$$;

-- ── Trigger functions used by every mutable / append-only table ────────

-- Server-authoritative, monotonically increasing updated_at. Uses
-- clock_timestamp() (wall-clock at execution), not now() (fixed at
-- transaction start) — a slow transaction must not appear to predate a
-- fast one that committed after it started. The GREATEST(...) guard
-- gives per-row monotonicity even under clock skew between commits.
create or replace function set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := greatest(old.updated_at + interval '1 microsecond', clock_timestamp());
  new.synced_at := clock_timestamp();
  return new;
end;
$$;

-- Sets both timestamps on first insert of a mutable row.
create or replace function set_created_at() returns trigger
language plpgsql as $$
begin
  new.created_at := clock_timestamp();
  new.updated_at := clock_timestamp();
  new.synced_at := clock_timestamp();
  return new;
end;
$$;

-- Attached to every append-only table (cash_ledger_entries,
-- stock_movements, investor_repayments, due_payments,
-- audit_log_entries) — a ledger fact, once written, is never edited or
-- deleted from the Dart API surface; this trigger makes that a database
-- guarantee too, not just an application convention. Corrections happen
-- via a reversal row, never an UPDATE/DELETE.
create or replace function forbid_update_or_delete() returns trigger
language plpgsql as $$
begin
  raise exception '% rows are immutable — insert a reversal row instead of modifying %',
    tg_table_name, tg_table_name;
end;
$$;

-- Stamps synced_at on insert for append-only tables (no updated_at column
-- on these — see forbid_update_or_delete above).
create or replace function set_synced_at_on_insert() returns trigger
language plpgsql as $$
begin
  new.synced_at := clock_timestamp();
  return new;
end;
$$;

-- ── Standard RLS: owner full access, staff read-only, scoped to shop ───
--
-- Applied identically to every business table via this procedure rather
-- than hand-written per table, so the *rule* is defined once and every
-- table's policy is guaranteed identical — the simplified permission
-- model the owner chose (no per-table exceptions) is enforced by
-- construction, not by remembering to copy the same four statements
-- correctly 21 times.
-- Takes the bare table name (never schema-qualified — all tables here
-- live in `public`) so policy names built from it via %I are always a
-- single valid identifier, regardless of search_path.
create or replace procedure apply_standard_rls(table_name text) as $$
begin
  execute format('alter table public.%I enable row level security', table_name);

  execute format(
    'create policy %I on public.%I for select using (shop_id = my_shop_id())',
    table_name || '_select', table_name
  );

  execute format(
    'create policy %I on public.%I for insert with check (is_owner() and shop_id = my_shop_id())',
    table_name || '_owner_insert', table_name
  );

  execute format(
    'create policy %I on public.%I for update using (is_owner() and shop_id = my_shop_id()) with check (is_owner() and shop_id = my_shop_id())',
    table_name || '_owner_update', table_name
  );

  execute format(
    'create policy %I on public.%I for delete using (is_owner() and shop_id = my_shop_id())',
    table_name || '_owner_delete', table_name
  );
end;
$$ language plpgsql;

-- ── Append-only RLS: owner can insert, nobody can update/delete ────────
--
-- Deliberately does not create an UPDATE or DELETE policy at all —
-- Postgres RLS defaults to deny when no policy exists for an operation,
-- so this is a second, independent enforcement layer on top of the
-- forbid_update_or_delete trigger (defense in depth: even if a future
-- migration mistakenly adds an update/delete policy to one of these
-- tables, the trigger still blocks it).
create or replace procedure apply_append_only_rls(table_name text) as $$
begin
  execute format('alter table public.%I enable row level security', table_name);

  execute format(
    'create policy %I on public.%I for select using (shop_id = my_shop_id())',
    table_name || '_select', table_name
  );

  execute format(
    'create policy %I on public.%I for insert with check (is_owner() and shop_id = my_shop_id())',
    table_name || '_owner_insert', table_name
  );
end;
$$ language plpgsql;
