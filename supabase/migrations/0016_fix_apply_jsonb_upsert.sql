-- 0016_fix_apply_jsonb_upsert.sql
--
-- Fixes apply_jsonb_upsert so that partial updates (e.g. soft-delete, status
-- updates) on existing rows execute as direct UPDATE statements rather than
-- INSERT ON CONFLICT DO UPDATE. This prevents Postgres from rejecting the
-- INSERT due to NOT NULL constraints on other columns not present in the
-- partial update payload.

create or replace function apply_jsonb_upsert(p_table text, p_row jsonb) returns void
language plpgsql as $$
declare
  cols text;
  vals text;
  updates text;
  is_append_only boolean;
  row_id uuid;
  row_exists boolean;
begin
  if p_table not in (
    'categories', 'units', 'products', 'product_images', 'customers', 'customer_images',
    'investors', 'investor_repayments', 'legacy_settlements',
    'purchase_trips', 'purchase_items', 'purchase_other_costs', 'sales',
    'dues', 'due_payments', 'rent_pricing_tiers', 'rent_transactions',
    'expenses', 'orders', 'fixed_assets', 'fixed_asset_images',
    'quick_captures', 'cash_ledger_entries', 'stock_movements',
    'audit_log_entries'
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
    row_id := (p_row ->> 'id')::uuid;
    execute format('select exists (select 1 from public.%I where id = %L)', p_table, row_id) into row_exists;

    if row_exists then
      select string_agg(format('%I = %L', key, p_row ->> key), ', ')
        into updates
      from jsonb_object_keys(p_row) as key
      where key <> 'id';

      if updates is not null then
        execute format(
          'update public.%I set %s where id = %L',
          p_table, updates, row_id
        );
      end if;
    else
      execute format(
        'insert into public.%I (%s) values (%s) on conflict (id) do update set %s',
        p_table, cols, vals,
        (
          select string_agg(format('%I = %L', key, p_row ->> key), ', ')
          from jsonb_object_keys(p_row) as key
          where key <> 'id'
        )
      );
    end if;
  end if;
end;
$$;
