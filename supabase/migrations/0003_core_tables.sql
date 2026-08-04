-- 0003_core_tables.sql
--
-- Mutable reference and aggregate-root tables, mirroring
-- lib/data/local/tables/shared.dart, products.dart, customers.dart,
-- investors.dart. All resolved by guarded last-write-wins during sync
-- (see the working plan's SYNC design) via the shared updated_at trigger
-- from migration 0001 — never edited without that trigger firing.
--
-- id columns are `uuid` (client-generated UUIDv7, see ARCHITECTURE.md),
-- never a Postgres-generated identity — the client must be able to
-- reference a row's id before it has ever talked to the server.

create table categories (
  id         uuid primary key,
  shop_id    uuid not null references shops(id) on delete cascade,
  name       text not null,
  sort_order int not null default 0,
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp(),
  synced_at  timestamptz not null default clock_timestamp()
);

create table app_settings (
  shop_id    uuid not null references shops(id) on delete cascade,
  key        text not null,
  value      text not null,
  updated_at timestamptz not null default clock_timestamp(),
  synced_at  timestamptz not null default clock_timestamp(),
  primary key (shop_id, key)
);

create table products (
  id                        uuid primary key,
  shop_id                   uuid not null references shops(id) on delete cascade,
  name                      text not null,
  category                  text not null,
  cost_price_minor          bigint not null check (cost_price_minor >= 0),
  suggested_sell_price_minor bigint not null check (suggested_sell_price_minor >= 0),
  qty                       double precision not null default 0,
  fund_source_type          fund_source_type not null,
  fund_source_investor_id   uuid,
  is_rentable               boolean not null default false,
  barcode                   text,
  sku                       text,
  created_at                timestamptz not null default clock_timestamp(),
  updated_at                timestamptz not null default clock_timestamp(),
  deleted_at                timestamptz,
  synced_at                 timestamptz not null default clock_timestamp(),
  constraint products_fund_source_investor_id_requires_investor
    check (
      (fund_source_type = 'investor' and fund_source_investor_id is not null)
      or (fund_source_type = 'shop' and fund_source_investor_id is null)
    )
);

create table product_images (
  id                     uuid primary key,
  product_id             uuid not null references products(id) on delete cascade,
  local_path             text,
  remote_url             text,
  thumbnail_local_path   text,
  thumbnail_remote_url   text,
  sort_order             int not null default 0,
  created_at             timestamptz not null default clock_timestamp(),
  synced_at              timestamptz not null default clock_timestamp()
);

create table customers (
  id              uuid primary key,
  shop_id         uuid not null references shops(id) on delete cascade,
  name            text not null,
  address         text,
  contact         text,
  suspicion_flag  boolean not null default false,
  is_blocked      boolean not null default false,
  created_at      timestamptz not null default clock_timestamp(),
  updated_at      timestamptz not null default clock_timestamp(),
  deleted_at      timestamptz,
  synced_at       timestamptz not null default clock_timestamp()
);

create table investors (
  id                        uuid primary key,
  shop_id                   uuid not null references shops(id) on delete cascade,
  name                      text not null,
  contact                   text,
  investment_type           investment_type not null,
  profit_share_percent      double precision not null default 0,
  capital_return_term_days  int,
  profit_payout_cycle       profit_payout_cycle not null,
  notes                     text,
  created_at                timestamptz not null default clock_timestamp(),
  updated_at                timestamptz not null default clock_timestamp(),
  deleted_at                timestamptz,
  synced_at                 timestamptz not null default clock_timestamp()
);

create table legacy_settlements (
  id                               uuid primary key,
  shop_id                          uuid not null references shops(id) on delete cascade,
  investor_id                      uuid not null references investors(id) on delete cascade,
  total_historical_investment_minor bigint not null check (total_historical_investment_minor >= 0),
  total_already_returned_minor    bigint not null default 0 check (total_already_returned_minor >= 0),
  net_settlement_amount_minor     bigint not null,
  settlement_date                 timestamptz not null,
  notes                            text,
  status                           legacy_settlement_status not null,
  created_at                       timestamptz not null default clock_timestamp(),
  updated_at                       timestamptz not null default clock_timestamp(),
  synced_at                        timestamptz not null default clock_timestamp()
);

-- Foreign key added after products exists — products.fund_source_investor_id
-- points at investors, but investors is defined after products above, so
-- this constraint is added here rather than inline.
alter table products
  add constraint products_fund_source_investor_id_fkey
  foreign key (fund_source_investor_id) references investors(id);

-- ── updated_at triggers (mutable tables only — see migration 0001) ─────

create trigger set_updated_at before update on categories
  for each row execute function set_updated_at();
create trigger set_updated_at before update on app_settings
  for each row execute function set_updated_at();
create trigger set_updated_at before update on products
  for each row execute function set_updated_at();
create trigger set_updated_at before update on customers
  for each row execute function set_updated_at();
create trigger set_updated_at before update on investors
  for each row execute function set_updated_at();
create trigger set_updated_at before update on legacy_settlements
  for each row execute function set_updated_at();

-- product_images has no updated_at column (create-or-delete, never
-- edited in place — a changed photo is a new image row) but still needs
-- synced_at stamped fresh on insert for the pull cursor.
create trigger set_synced_at before insert on product_images
  for each row execute function set_synced_at_on_insert();

-- ── Sync cursor indexes: (shop_id, synced_at, id) — see the working ────
-- plan's pull-since-cursor design. product_images and app_settings are
-- keyed slightly differently (no independent shop_id-first business key
-- the same way, or a composite PK) but still benefit from a synced_at
-- index for the incremental pull query.

create index idx_categories_sync on categories (shop_id, synced_at, id);
create index idx_app_settings_sync on app_settings (shop_id, synced_at);
create index idx_products_sync on products (shop_id, synced_at, id);
create index idx_product_images_sync on product_images (product_id, synced_at, id);
create index idx_customers_sync on customers (shop_id, synced_at, id);
create index idx_investors_sync on investors (shop_id, synced_at, id);
create index idx_legacy_settlements_sync on legacy_settlements (shop_id, synced_at, id);

-- ── RLS: owner full access, staff read-only, per the simplified model ──

call apply_standard_rls('categories');
call apply_standard_rls('app_settings');
call apply_standard_rls('products');
call apply_standard_rls('customers');
call apply_standard_rls('investors');
call apply_standard_rls('legacy_settlements');

-- product_images has no shop_id column of its own (it hangs off
-- products), so it can't use apply_standard_rls directly — scope through
-- the parent product's shop instead.
alter table product_images enable row level security;

create policy product_images_select on product_images
  for select using (
    exists (select 1 from products p where p.id = product_images.product_id and p.shop_id = my_shop_id())
  );

create policy product_images_owner_insert on product_images
  for insert with check (
    is_owner() and exists (
      select 1 from products p where p.id = product_images.product_id and p.shop_id = my_shop_id()
    )
  );

create policy product_images_owner_update on product_images
  for update using (
    is_owner() and exists (select 1 from products p where p.id = product_images.product_id and p.shop_id = my_shop_id())
  ) with check (
    is_owner() and exists (select 1 from products p where p.id = product_images.product_id and p.shop_id = my_shop_id())
  );

create policy product_images_owner_delete on product_images
  for delete using (
    is_owner() and exists (select 1 from products p where p.id = product_images.product_id and p.shop_id = my_shop_id())
  );
