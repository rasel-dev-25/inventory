insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-images',
  'product-images',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create or replace function product_image_object_product_id(object_name text)
returns uuid
language sql
immutable
as $$
  select case
    when (storage.foldername(object_name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
      then ((storage.foldername(object_name))[1])::uuid
    else null
  end;
$$;

alter function public.product_image_object_product_id(text)
  set search_path = '';

create policy product_images_storage_select
on storage.objects for select to authenticated
using (
  bucket_id = 'product-images'
  and exists (
    select 1 from public.products p
    where p.id = public.product_image_object_product_id(name)
      and p.shop_id = public.my_shop_id()
  )
);

create policy product_images_storage_insert
on storage.objects for insert to authenticated
with check (
  bucket_id = 'product-images'
  and public.is_owner()
  and exists (
    select 1 from public.products p
    where p.id = public.product_image_object_product_id(name)
      and p.shop_id = public.my_shop_id()
  )
);

create policy product_images_storage_update
on storage.objects for update to authenticated
using (
  bucket_id = 'product-images'
  and public.is_owner()
  and exists (
    select 1 from public.products p
    where p.id = public.product_image_object_product_id(name)
      and p.shop_id = public.my_shop_id()
  )
)
with check (
  bucket_id = 'product-images'
  and public.is_owner()
  and exists (
    select 1 from public.products p
    where p.id = public.product_image_object_product_id(name)
      and p.shop_id = public.my_shop_id()
  )
);

create policy product_images_storage_delete
on storage.objects for delete to authenticated
using (
  bucket_id = 'product-images'
  and public.is_owner()
  and exists (
    select 1 from public.products p
    where p.id = public.product_image_object_product_id(name)
      and p.shop_id = public.my_shop_id()
  )
);

create or replace function set_synced_at_on_update() returns trigger
language plpgsql as $$
begin
  new.synced_at := greatest(old.synced_at + interval '1 microsecond', clock_timestamp());
  return new;
end;
$$;

alter function public.set_synced_at_on_update()
  set search_path = '';

drop trigger if exists set_synced_at_on_update on product_images;
create trigger set_synced_at_on_update before update on product_images
  for each row execute function set_synced_at_on_update();
