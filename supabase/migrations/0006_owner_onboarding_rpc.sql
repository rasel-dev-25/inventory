-- 0006_owner_onboarding_rpc.sql
--
-- Closes the known limitation flagged in 0002_shops_and_members_rls.sql:
-- shop creation and the first shop_members row were two separate
-- client-issued statements — racy under concurrent onboarding, and able
-- to leave an orphaned, ownerless shop behind if the second statement
-- failed after the first succeeded. create_shop_and_owner() does both
-- inside one Postgres function body, which runs as a single transaction:
-- either both rows exist afterward, or neither does.

create or replace function create_shop_and_owner(p_shop_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_shop_id uuid;
begin
  if exists (select 1 from shop_members where user_id = auth.uid()) then
    raise exception 'user % already belongs to a shop', auth.uid();
  end if;

  v_shop_id := gen_random_uuid();

  insert into shops (id, name) values (v_shop_id, p_shop_name);
  insert into shop_members (shop_id, user_id, role) values (v_shop_id, auth.uid(), 'owner');

  return v_shop_id;
end;
$$;

-- Only a signed-in user may call this (never anon) — replaces the
-- client-side two-statement flow the shops_insert / shop_members
-- bootstrap policies were originally written to support.
revoke all on function create_shop_and_owner(text) from public;
grant execute on function create_shop_and_owner(text) to authenticated;

-- ── Owner invites an already-registered user as staff ──────────────────
--
-- Client code can never query auth.users directly (there is no
-- RLS-visible view of it), so looking a user up by the email they signed
-- up with has to happen inside a security-definer function. Only
-- callable by the current shop's owner, for their own shop — enforced in
-- the function body itself, not just relied on client-side (matches
-- PermissionFailure's own doc comment: the server check is the real
-- boundary, the client-side failure is only the UX signal).
create or replace function add_staff_member_by_email(p_shop_id uuid, p_email text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  if not (is_owner() and p_shop_id = my_shop_id()) then
    raise exception 'only the shop owner may add staff';
  end if;

  select id into v_user_id from auth.users where lower(email) = lower(p_email);

  if v_user_id is null then
    raise exception 'no account found for %', p_email;
  end if;

  if exists (select 1 from shop_members where user_id = v_user_id) then
    raise exception 'user % already belongs to a shop', p_email;
  end if;

  insert into shop_members (shop_id, user_id, role) values (p_shop_id, v_user_id, 'staff');
end;
$$;

revoke all on function add_staff_member_by_email(uuid, text) from public;
grant execute on function add_staff_member_by_email(uuid, text) to authenticated;
