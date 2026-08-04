-- 0002_shops_and_members_rls.sql
--
-- `shops` and `shop_members` don't fit `apply_standard_rls` (they aren't
-- "a business table scoped by a shop_id column pointing elsewhere" —
-- `shops.id` *is* the shop id, and `shop_members` is the membership table
-- itself), so they need bespoke policies. Supabase's own advisory system
-- flagged these two tables as RLS-disabled immediately after migration
-- 0001 — this migration closes that gap before any other table is added.
--
-- Known limitation, flagged rather than silently resolved: the INSERT
-- policy on shop_members below implements a bootstrap rule (the first
-- person to claim a fresh shop becomes its owner) sufficient for a
-- single-shop app, but the real owner-onboarding flow is a later M1 task
-- (auth screens haven't been built yet). Revisit these two policies once
-- that flow exists — they may need to move server-side into an Edge
-- Function so shop creation and the first membership row are created
-- atomically rather than as two separate client-issued statements.

alter table shops enable row level security;
alter table shop_members enable row level security;

-- Anyone signed in can see the shop(s) they belong to.
create policy shops_select on shops
  for select using (id = my_shop_id());

-- Any authenticated user can create a shop — this is the first step of
-- onboarding, before any shop_members row exists for them yet, so it
-- cannot be scoped by my_shop_id() (which depends on membership existing).
create policy shops_insert on shops
  for insert with check (auth.role() = 'authenticated');

-- Only the current owner can rename their own shop.
create policy shops_update on shops
  for update using (is_owner() and id = my_shop_id())
  with check (is_owner() and id = my_shop_id());

-- A member can see their own membership row, and everyone in a shop can
-- see the shop's full member list (an owner needs this to manage staff;
-- staff seeing who else has access is not sensitive).
create policy shop_members_select on shop_members
  for select using (user_id = auth.uid() or shop_id = my_shop_id());

-- Bootstrap rule: a user may insert themselves as the owner of a shop
-- that has no members yet (the shop they just created in the statement
-- before this one). Once a shop has an owner, only that owner may add
-- more members (staff or otherwise).
create policy shop_members_insert on shop_members
  for insert with check (
    (
      user_id = auth.uid()
      and role = 'owner'
      and not exists (select 1 from shop_members m where m.shop_id = shop_members.shop_id)
    )
    or (is_owner() and shop_id = my_shop_id())
  );

-- Only the owner can change a member's role or remove them; a member
-- cannot promote themselves.
create policy shop_members_update on shop_members
  for update using (is_owner() and shop_id = my_shop_id())
  with check (is_owner() and shop_id = my_shop_id());

create policy shop_members_delete on shop_members
  for delete using (is_owner() and shop_id = my_shop_id());
