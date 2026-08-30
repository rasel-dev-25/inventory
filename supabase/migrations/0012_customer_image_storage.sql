create table customer_images (
  id          uuid primary key,
  customer_id uuid not null references customers(id) on delete cascade,
  local_path  text,
  remote_url  text,
  sort_order  int not null default 0,
  created_at  timestamptz not null default clock_timestamp(),
  synced_at   timestamptz not null default clock_timestamp()
);

alter table customer_images enable row level security;

create policy customer_images_select on customer_images
  for select to authenticated using (
    exists (
      select 1 from customers c
      where c.id = customer_images.customer_id
        and c.shop_id = my_shop_id()
    )
  );

create policy customer_images_owner_insert on customer_images
  for insert to authenticated with check (
    is_owner() and exists (
      select 1 from customers c
      where c.id = customer_images.customer_id
        and c.shop_id = my_shop_id()
    )
  );

create policy customer_images_owner_update on customer_images
  for update to authenticated using (
    is_owner() and exists (
      select 1 from customers c
      where c.id = customer_images.customer_id
        and c.shop_id = my_shop_id()
    )
  ) with check (
    is_owner() and exists (
      select 1 from customers c
      where c.id = customer_images.customer_id
        and c.shop_id = my_shop_id()
    )
  );

create policy customer_images_owner_delete on customer_images
  for delete to authenticated using (
    is_owner() and exists (
      select 1 from customers c
      where c.id = customer_images.customer_id
        and c.shop_id = my_shop_id()
    )
  );

grant select, insert, update, delete on customer_images to authenticated;

drop trigger if exists set_synced_at_on_update on customer_images;
create trigger set_synced_at_on_update before update on customer_images
  for each row execute function set_synced_at_on_update();

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'customer-images',
  'customer-images',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create or replace function customer_image_object_customer_id(object_name text)
returns uuid
language sql
immutable
set search_path = ''
as $$
  select case
    when (storage.foldername(object_name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
      then ((storage.foldername(object_name))[1])::uuid
    else null
  end;
$$;

create policy customer_images_storage_select
on storage.objects for select to authenticated
using (
  bucket_id = 'customer-images'
  and exists (
    select 1 from public.customers c
    where c.id = public.customer_image_object_customer_id(name)
      and c.shop_id = public.my_shop_id()
  )
);

create policy customer_images_storage_insert
on storage.objects for insert to authenticated
with check (
  bucket_id = 'customer-images'
  and public.is_owner()
  and exists (
    select 1 from public.customers c
    where c.id = public.customer_image_object_customer_id(name)
      and c.shop_id = public.my_shop_id()
  )
);

create policy customer_images_storage_update
on storage.objects for update to authenticated
using (
  bucket_id = 'customer-images'
  and public.is_owner()
  and exists (
    select 1 from public.customers c
    where c.id = public.customer_image_object_customer_id(name)
      and c.shop_id = public.my_shop_id()
  )
)
with check (
  bucket_id = 'customer-images'
  and public.is_owner()
  and exists (
    select 1 from public.customers c
    where c.id = public.customer_image_object_customer_id(name)
      and c.shop_id = public.my_shop_id()
  )
);

create policy customer_images_storage_delete
on storage.objects for delete to authenticated
using (
  bucket_id = 'customer-images'
  and public.is_owner()
  and exists (
    select 1 from public.customers c
    where c.id = public.customer_image_object_customer_id(name)
      and c.shop_id = public.my_shop_id()
  )
);

create or replace function apply_jsonb_upsert(p_table text, p_row jsonb) returns void
language plpgsql as $$
declare
  cols text;
  vals text;
  updates text;
  is_append_only boolean;
begin
  if p_table not in (
    'categories', 'products', 'product_images', 'customers', 'customer_images',
    'investors', 'investor_repayments', 'legacy_settlements',
    'purchase_trips', 'purchase_items', 'purchase_other_costs', 'sales',
    'dues', 'due_payments', 'rent_pricing_tiers', 'rent_transactions',
    'expenses', 'orders', 'fixed_assets', 'quick_captures',
    'cash_ledger_entries', 'stock_movements', 'audit_log_entries'
  ) then
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
