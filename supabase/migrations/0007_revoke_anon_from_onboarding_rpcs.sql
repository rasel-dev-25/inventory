-- 0007_revoke_anon_from_onboarding_rpcs.sql
--
-- Supabase's default privileges grant EXECUTE directly to the `anon`
-- role for every new function in `public` (not via the PUBLIC
-- pseudo-role), so 0006's `revoke all ... from public` did not actually
-- remove anon's access — confirmed via has_function_privilege('anon', ...)
-- returning true after that migration, and flagged independently by
-- Supabase's own security advisor (anon_security_definer_function_executable).
-- These two functions create a shop / add a shop member and must only
-- ever be callable by a signed-in user. Verified live after this fix: an
-- unauthenticated REST call to create_shop_and_owner now gets
-- "permission denied for function create_shop_and_owner" (42501) instead
-- of executing.

revoke execute on function create_shop_and_owner(text) from anon;
revoke execute on function add_staff_member_by_email(uuid, text) from anon;
