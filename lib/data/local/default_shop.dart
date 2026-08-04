/// This app is single-shop-per-device — every table still carries a
/// `shopId` column (so the Postgres mirror's RLS policies have something
/// to scope on once this device syncs), but locally there is only ever
/// one [Shops] row for the lifetime of a given database file.
///
/// Because of that, the `onCreate` seed migration can safely create this
/// one row itself with a fixed, well-known id, rather than waiting for an
/// owner-onboarding flow to create it — the alternative (seed nothing at
/// `onCreate`, seed everything during onboarding) would need every
/// shop-scoped seed row (default categories, default rent tiers) to wait
/// on onboarding too, and there is no reason to couple "the app has a
/// database" to "the owner finished typing their shop's name" for a
/// single-shop app. Onboarding's job becomes simply renaming this row and
/// capturing auth, not creating it from scratch.
///
/// **If this app ever needs to support more than one shop per device**,
/// this assumption needs revisiting — the fixed id would need to become a
/// real "create a shop" flow. Out of scope today; the working plan treats
/// this as explicitly single-shop.
const defaultShopId = 'shop-default';
