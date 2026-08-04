-- 0005_ledger_and_audit.sql
--
-- Append-only tables mirroring lib/data/local/tables/ledger.dart,
-- investors.dart's InvestorRepayments, dues.dart's DuePayments, and
-- audit.dart. No updated_at/deleted_at column on any of these — the
-- forbid_update_or_delete trigger (migration 0001) makes editing or
-- deleting a row a hard database error, and apply_append_only_rls
-- (migration 0001) means only the owner may INSERT and nobody has an
-- UPDATE/DELETE policy at all. This is the pair of independent
-- enforcement layers documented in migration 0001 — either one alone
-- would be enough, both together is deliberate defense in depth for the
-- rows that every cash and stock figure in the app is derived from.

create table cash_ledger_entries (
  id             uuid primary key,
  shop_id        uuid not null references shops(id) on delete cascade,
  amount_minor   bigint not null, -- signed: positive = cash in, negative = cash out
  payment_method payment_method not null,
  -- Polymorphic source (sale, due payment, rent return, purchase trip,
  -- expense, or investor repayment) — see the identical note on the
  -- local Drift table.
  source_type    text not null,
  source_id      uuid not null,
  description    text,
  date           timestamptz not null,
  created_at     timestamptz not null default clock_timestamp(),
  synced_at      timestamptz not null default clock_timestamp()
);

create table stock_movements (
  id           uuid primary key,
  shop_id      uuid not null references shops(id) on delete cascade,
  product_id   uuid not null references products(id),
  delta_qty    double precision not null, -- signed: positive = in, negative = out
  source_type  text not null,
  source_id    uuid,
  date         timestamptz not null,
  created_at   timestamptz not null default clock_timestamp(),
  synced_at    timestamptz not null default clock_timestamp()
);

create table investor_repayments (
  id             uuid primary key,
  shop_id        uuid not null references shops(id) on delete cascade,
  investor_id    uuid not null references investors(id),
  amount_minor   bigint not null check (amount_minor > 0),
  type           repayment_type not null,
  payment_method payment_method not null,
  date           timestamptz not null,
  created_at     timestamptz not null default clock_timestamp(),
  synced_at      timestamptz not null default clock_timestamp()
);

create table due_payments (
  id             uuid primary key,
  due_id         uuid not null references dues(id),
  amount_minor   bigint not null check (amount_minor > 0),
  payment_method payment_method not null,
  date           timestamptz not null,
  created_at     timestamptz not null default clock_timestamp(),
  synced_at      timestamptz not null default clock_timestamp()
);

create table audit_log_entries (
  id                uuid primary key,
  shop_id           uuid not null references shops(id) on delete cascade,
  user_id           uuid references auth.users(id),
  device_id         text,
  action            text not null,
  changed_table_name text not null,
  record_id         uuid not null,
  old_value_json    jsonb,
  new_value_json    jsonb,
  timestamp         timestamptz not null,
  synced_at         timestamptz not null default clock_timestamp()
);

-- ── Immutability triggers ────────────────────────────────────────────────

create trigger forbid_update_or_delete before update or delete on cash_ledger_entries
  for each row execute function forbid_update_or_delete();
create trigger forbid_update_or_delete before update or delete on stock_movements
  for each row execute function forbid_update_or_delete();
create trigger forbid_update_or_delete before update or delete on investor_repayments
  for each row execute function forbid_update_or_delete();
create trigger forbid_update_or_delete before update or delete on due_payments
  for each row execute function forbid_update_or_delete();
create trigger forbid_update_or_delete before update or delete on audit_log_entries
  for each row execute function forbid_update_or_delete();

create trigger set_synced_at before insert on cash_ledger_entries
  for each row execute function set_synced_at_on_insert();
create trigger set_synced_at before insert on stock_movements
  for each row execute function set_synced_at_on_insert();
create trigger set_synced_at before insert on investor_repayments
  for each row execute function set_synced_at_on_insert();
create trigger set_synced_at before insert on due_payments
  for each row execute function set_synced_at_on_insert();
create trigger set_synced_at before insert on audit_log_entries
  for each row execute function set_synced_at_on_insert();

-- ── Sync cursor indexes, plus the lookups these tables exist to serve ──

create index idx_cash_ledger_sync on cash_ledger_entries (shop_id, synced_at, id);
create index idx_cash_ledger_by_date on cash_ledger_entries (shop_id, date);
create index idx_cash_ledger_by_source on cash_ledger_entries (source_type, source_id);

create index idx_stock_movements_sync on stock_movements (shop_id, synced_at, id);
create index idx_stock_movements_by_product on stock_movements (product_id, date);

create index idx_investor_repayments_sync on investor_repayments (shop_id, synced_at, id);
create index idx_investor_repayments_by_investor on investor_repayments (investor_id);

create index idx_due_payments_by_due on due_payments (due_id);

create index idx_audit_log_sync on audit_log_entries (shop_id, synced_at, id);
create index idx_audit_log_by_record on audit_log_entries (changed_table_name, record_id);

-- ── RLS: owner can insert, nobody can update/delete (see migration 0001) ─

call apply_append_only_rls('cash_ledger_entries');
call apply_append_only_rls('stock_movements');
call apply_append_only_rls('investor_repayments');
call apply_append_only_rls('audit_log_entries');

-- due_payments has no shop_id of its own — scope through the parent due,
-- same pattern as product_images/purchase_items above, adapted for
-- append-only (select + owner-insert only, no update/delete policy).
alter table due_payments enable row level security;

create policy due_payments_select on due_payments
  for select using (
    exists (select 1 from dues d where d.id = due_payments.due_id and d.shop_id = my_shop_id())
  );
create policy due_payments_owner_insert on due_payments
  for insert with check (
    is_owner() and exists (select 1 from dues d where d.id = due_payments.due_id and d.shop_id = my_shop_id())
  );
