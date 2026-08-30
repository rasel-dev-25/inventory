-- 0015_storage_usage_rpc.sql
--
-- RPC for calculating a shop's cloud storage usage (across product-images,
-- customer-images, and fixed-asset-images buckets) and database record counts.

create or replace function get_shop_storage_usage()
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_shop_id uuid;
  v_product_bytes bigint := 0;
  v_product_count bigint := 0;
  v_customer_bytes bigint := 0;
  v_customer_count bigint := 0;
  v_asset_bytes bigint := 0;
  v_asset_count bigint := 0;
  v_total_bytes bigint := 0;
  v_products_count bigint := 0;
  v_customers_count bigint := 0;
  v_sales_count bigint := 0;
  v_dues_count bigint := 0;
  v_orders_count bigint := 0;
  v_expenses_count bigint := 0;
  v_purchases_count bigint := 0;
  v_total_records bigint := 0;
begin
  v_shop_id := public.my_shop_id();
  if v_shop_id is null then
    raise exception 'caller has no shop membership';
  end if;

  -- 1. Product Images
  select
    coalesce(sum((o.metadata->>'size')::bigint), 0),
    count(o.id)
  into v_product_bytes, v_product_count
  from storage.objects o
  where o.bucket_id = 'product-images'
    and exists (
      select 1 from public.products p
      where p.id = public.product_image_object_product_id(o.name)
        and p.shop_id = v_shop_id
    );

  -- 2. Customer Images
  select
    coalesce(sum((o.metadata->>'size')::bigint), 0),
    count(o.id)
  into v_customer_bytes, v_customer_count
  from storage.objects o
  where o.bucket_id = 'customer-images'
    and exists (
      select 1 from public.customers c
      where c.id = public.customer_image_object_customer_id(o.name)
        and c.shop_id = v_shop_id
    );

  -- 3. Fixed Asset Images
  select
    coalesce(sum((o.metadata->>'size')::bigint), 0),
    count(o.id)
  into v_asset_bytes, v_asset_count
  from storage.objects o
  where o.bucket_id = 'fixed-asset-images'
    and exists (
      select 1 from public.fixed_assets a
      where a.id = public.fixed_asset_image_object_asset_id(o.name)
        and a.shop_id = v_shop_id
    );

  v_total_bytes := v_product_bytes + v_customer_bytes + v_asset_bytes;

  -- 4. Shop Record Counts
  select count(*) into v_products_count from public.products where shop_id = v_shop_id and deleted_at is null;
  select count(*) into v_customers_count from public.customers where shop_id = v_shop_id and deleted_at is null;
  select count(*) into v_sales_count from public.sales where shop_id = v_shop_id and deleted_at is null;
  select count(*) into v_dues_count from public.dues where shop_id = v_shop_id and deleted_at is null;
  select count(*) into v_orders_count from public.orders where shop_id = v_shop_id and deleted_at is null;
  select count(*) into v_expenses_count from public.expenses where shop_id = v_shop_id and deleted_at is null;
  select count(*) into v_purchases_count from public.purchase_trips where shop_id = v_shop_id and deleted_at is null;

  v_total_records := v_products_count + v_customers_count + v_sales_count + v_dues_count + v_orders_count + v_expenses_count + v_purchases_count;

  return jsonb_build_object(
    'cloud_storage', jsonb_build_object(
      'total_bytes', v_total_bytes,
      'quota_bytes', 1073741824, -- 1 GB Supabase Free Tier quota
      'product_images', jsonb_build_object('bytes', v_product_bytes, 'count', v_product_count),
      'customer_images', jsonb_build_object('bytes', v_customer_bytes, 'count', v_customer_count),
      'fixed_asset_images', jsonb_build_object('bytes', v_asset_bytes, 'count', v_asset_count)
    ),
    'database', jsonb_build_object(
      'total_records', v_total_records,
      'products_count', v_products_count,
      'customers_count', v_customers_count,
      'sales_count', v_sales_count,
      'dues_count', v_dues_count,
      'orders_count', v_orders_count,
      'expenses_count', v_expenses_count,
      'purchases_count', v_purchases_count
    )
  );
end;
$$;

revoke all on function public.get_shop_storage_usage() from public;
revoke execute on function public.get_shop_storage_usage() from anon;
grant execute on function public.get_shop_storage_usage() to authenticated;
