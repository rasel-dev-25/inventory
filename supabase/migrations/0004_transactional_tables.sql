-- 0004_transactional_tables.sql
--
-- Mirrors lib/data/local/tables/purchases.dart, sales.dart, dues.dart,
-- rent.dart, expenses.dart, orders.dart, assets.dart, quick_capture.dart.
-- All mutable (LWW via the shared updated_at trigger) — see migration
-- 0001. Cash/stock *effects* of these rows are mirrored separately into
-- the append-only ledger tables in migration 0005; these rows are the
-- editable records, not the ledger of what actually happened.

create table purchase_trips (
  id                   uuid primary key,
  shop_id              uuid not null references shops(id) on delete cascade,
  date                 timestamptz not null,
  transport_cost_minor bigint not null default 0 check (transport_cost_minor >= 0),
  cash_returned_minor  bigint not null default 0 check (cash_returned_minor >= 0),
  notes                text,
  created_at           timestamptz not null default clock_timestamp(),
  updated_at           timestamptz not null default clock_timestamp(),
  deleted_at           timestamptz,
  synced_at            timestamptz not null default clock_timestamp()
);

create table purchase_items (
  id                      uuid primary key,
  purchase_trip_id        uuid not null references purchase_trips(id) on delete cascade,
  shop_name               text not null,
  product_id              uuid not null references products(id),
  qty                     double precision not null check (qty > 0),
  unit_price_minor        bigint not null check (unit_price_minor >= 0),
  fund_source_type        fund_source_type not null,
  fund_source_investor_id uuid references investors(id),
  is_in_kind              boolean not null default false,
  created_at              timestamptz not null default clock_timestamp(),
  updated_at              timestamptz not null default clock_timestamp(),
  deleted_at              timestamptz,
  synced_at               timestamptz not null default clock_timestamp(),
  constraint purchase_items_fund_source_investor_id_requires_investor
    check (
      (fund_source_type = 'investor' and fund_source_investor_id is not null)
      or (fund_source_type = 'shop' and fund_source_investor_id is null)
    )
);

create table purchase_other_costs (
  id               uuid primary key,
  purchase_trip_id uuid not null references purchase_trips(id) on delete cascade,
  description      text not null,
  amount_minor     bigint not null check (amount_minor >= 0)
);

create table sales (
  id                        uuid primary key,
  shop_id                   uuid not null references shops(id) on delete cascade,
  product_id                uuid not null references products(id),
  qty                       double precision not null check (qty > 0),
  actual_sell_price_minor   bigint not null check (actual_sell_price_minor >= 0),
  cost_price_minor_at_sale  bigint not null check (cost_price_minor_at_sale >= 0),
  date                      timestamptz not null,
  customer_id               uuid references customers(id),
  payment_status            payment_status not null,
  payment_method            payment_method not null,
  fund_source_type          fund_source_type not null,
  fund_source_investor_id   uuid references investors(id),
  created_at                timestamptz not null default clock_timestamp(),
  updated_at                timestamptz not null default clock_timestamp(),
  deleted_at                timestamptz,
  synced_at                 timestamptz not null default clock_timestamp(),
  constraint sales_fund_source_investor_id_requires_investor
    check (
      (fund_source_type = 'investor' and fund_source_investor_id is not null)
      or (fund_source_type = 'shop' and fund_source_investor_id is null)
    )
);

create table dues (
  id                  uuid primary key,
  shop_id             uuid not null references shops(id) on delete cascade,
  customer_id         uuid not null references customers(id),
  source_type         due_source_type not null,
  -- Polymorphic (sale or rent transaction) — see the identical note on
  -- the local Drift table; Postgres can't express a conditional FK
  -- either, so this is enforced by whichever function writes it.
  source_id           uuid not null,
  original_amount_minor bigint not null check (original_amount_minor > 0),
  paid_amount_minor   bigint not null default 0 check (paid_amount_minor >= 0),
  promised_days       int,
  status              due_status not null,
  created_at          timestamptz not null default clock_timestamp(),
  updated_at          timestamptz not null default clock_timestamp(),
  deleted_at          timestamptz,
  synced_at           timestamptz not null default clock_timestamp(),
  constraint dues_paid_not_more_than_original check (paid_amount_minor <= original_amount_minor)
);

create table rent_pricing_tiers (
  id          uuid primary key,
  shop_id     uuid not null references shops(id) on delete cascade,
  max_pages   int not null check (max_pages > 0),
  days        int not null check (days > 0),
  price_minor bigint not null check (price_minor >= 0),
  sort_order  int not null default 0
);

create table rent_transactions (
  id                    uuid primary key,
  shop_id               uuid not null references shops(id) on delete cascade,
  book_product_id       uuid not null references products(id),
  customer_id           uuid not null references customers(id),
  start_date            timestamptz not null,
  due_date              timestamptz not null,
  deposit_minor         bigint not null default 0 check (deposit_minor >= 0),
  extra_day_charge_minor bigint check (extra_day_charge_minor >= 0),
  damage_charge_minor   bigint check (damage_charge_minor >= 0),
  status                rent_status not null,
  returned_date         timestamptz,
  created_at            timestamptz not null default clock_timestamp(),
  updated_at            timestamptz not null default clock_timestamp(),
  synced_at             timestamptz not null default clock_timestamp()
);

create table expenses (
  id           uuid primary key,
  shop_id      uuid not null references shops(id) on delete cascade,
  category     expense_category not null,
  amount_minor bigint not null check (amount_minor > 0),
  date         timestamptz not null,
  description  text,
  payment_method payment_method not null,
  created_at   timestamptz not null default clock_timestamp(),
  updated_at   timestamptz not null default clock_timestamp(),
  deleted_at   timestamptz,
  synced_at    timestamptz not null default clock_timestamp()
);

create table orders (
  id                uuid primary key,
  shop_id           uuid not null references shops(id) on delete cascade,
  customer_id       uuid not null references customers(id),
  item_description  text not null,
  requested_date    timestamptz not null,
  needed_by_date    timestamptz,
  status            order_status not null,
  fulfilled_date    timestamptz,
  created_at        timestamptz not null default clock_timestamp(),
  updated_at        timestamptz not null default clock_timestamp(),
  deleted_at        timestamptz,
  synced_at         timestamptz not null default clock_timestamp()
);

create table fixed_assets (
  id                uuid primary key,
  shop_id           uuid not null references shops(id) on delete cascade,
  name              text not null,
  value_minor       bigint not null check (value_minor >= 0),
  date_acquired     timestamptz not null,
  source_type       fixed_asset_source not null,
  source_product_id uuid references products(id),
  created_at        timestamptz not null default clock_timestamp(),
  updated_at        timestamptz not null default clock_timestamp(),
  deleted_at        timestamptz,
  synced_at         timestamptz not null default clock_timestamp()
);

create table quick_captures (
  id                 uuid primary key,
  shop_id            uuid not null references shops(id) on delete cascade,
  type               quick_capture_type not null,
  file_local_path    text not null,
  status             quick_capture_status not null,
  converted_to_type  text,
  converted_to_id    uuid,
  created_at         timestamptz not null default clock_timestamp(),
  synced_at          timestamptz not null default clock_timestamp()
);

-- ── updated_at triggers ─────────────────────────────────────────────────

create trigger set_updated_at before update on purchase_trips
  for each row execute function set_updated_at();
create trigger set_updated_at before update on purchase_items
  for each row execute function set_updated_at();
create trigger set_updated_at before update on sales
  for each row execute function set_updated_at();
create trigger set_updated_at before update on dues
  for each row execute function set_updated_at();
create trigger set_updated_at before update on rent_transactions
  for each row execute function set_updated_at();
create trigger set_updated_at before update on expenses
  for each row execute function set_updated_at();
create trigger set_updated_at before update on orders
  for each row execute function set_updated_at();
create trigger set_updated_at before update on fixed_assets
  for each row execute function set_updated_at();

-- purchase_other_costs, rent_pricing_tiers and quick_captures have no
-- updated_at column (small immutable-in-practice line items / config
-- rows) — quick_captures still gets synced_at stamped on insert.
create trigger set_synced_at before insert on quick_captures
  for each row execute function set_synced_at_on_insert();

-- ── Sync cursor indexes ─────────────────────────────────────────────────

create index idx_purchase_trips_sync on purchase_trips (shop_id, synced_at, id);
create index idx_purchase_items_by_trip on purchase_items (purchase_trip_id);
create index idx_purchase_other_costs_by_trip on purchase_other_costs (purchase_trip_id);
create index idx_sales_sync on sales (shop_id, synced_at, id);
create index idx_dues_sync on dues (shop_id, synced_at, id);
create index idx_rent_pricing_tiers_shop on rent_pricing_tiers (shop_id);
create index idx_rent_transactions_sync on rent_transactions (shop_id, synced_at, id);
create index idx_rent_transactions_active on rent_transactions (book_product_id, status);
create index idx_expenses_sync on expenses (shop_id, synced_at, id);
create index idx_orders_sync on orders (shop_id, synced_at, id);
create index idx_fixed_assets_sync on fixed_assets (shop_id, synced_at, id);
create index idx_quick_captures_sync on quick_captures (shop_id, synced_at, id);

-- ── RLS ──────────────────────────────────────────────────────────────────

call apply_standard_rls('purchase_trips');
call apply_standard_rls('sales');
call apply_standard_rls('dues');
call apply_standard_rls('rent_pricing_tiers');
call apply_standard_rls('rent_transactions');
call apply_standard_rls('expenses');
call apply_standard_rls('orders');
call apply_standard_rls('fixed_assets');
call apply_standard_rls('quick_captures');

-- purchase_items and purchase_other_costs have no shop_id of their own —
-- scope through the parent trip, same pattern as product_images above.
alter table purchase_items enable row level security;

create policy purchase_items_select on purchase_items
  for select using (
    exists (select 1 from purchase_trips t where t.id = purchase_items.purchase_trip_id and t.shop_id = my_shop_id())
  );
create policy purchase_items_owner_insert on purchase_items
  for insert with check (
    is_owner() and exists (select 1 from purchase_trips t where t.id = purchase_items.purchase_trip_id and t.shop_id = my_shop_id())
  );
create policy purchase_items_owner_update on purchase_items
  for update using (
    is_owner() and exists (select 1 from purchase_trips t where t.id = purchase_items.purchase_trip_id and t.shop_id = my_shop_id())
  ) with check (
    is_owner() and exists (select 1 from purchase_trips t where t.id = purchase_items.purchase_trip_id and t.shop_id = my_shop_id())
  );
create policy purchase_items_owner_delete on purchase_items
  for delete using (
    is_owner() and exists (select 1 from purchase_trips t where t.id = purchase_items.purchase_trip_id and t.shop_id = my_shop_id())
  );

alter table purchase_other_costs enable row level security;

create policy purchase_other_costs_select on purchase_other_costs
  for select using (
    exists (select 1 from purchase_trips t where t.id = purchase_other_costs.purchase_trip_id and t.shop_id = my_shop_id())
  );
create policy purchase_other_costs_owner_insert on purchase_other_costs
  for insert with check (
    is_owner() and exists (select 1 from purchase_trips t where t.id = purchase_other_costs.purchase_trip_id and t.shop_id = my_shop_id())
  );
create policy purchase_other_costs_owner_update on purchase_other_costs
  for update using (
    is_owner() and exists (select 1 from purchase_trips t where t.id = purchase_other_costs.purchase_trip_id and t.shop_id = my_shop_id())
  ) with check (
    is_owner() and exists (select 1 from purchase_trips t where t.id = purchase_other_costs.purchase_trip_id and t.shop_id = my_shop_id())
  );
create policy purchase_other_costs_owner_delete on purchase_other_costs
  for delete using (
    is_owner() and exists (select 1 from purchase_trips t where t.id = purchase_other_costs.purchase_trip_id and t.shop_id = my_shop_id())
  );
