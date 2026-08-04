import '../local/default_shop.dart';

/// Translates the `shopId` field of a row's JSON representation between
/// this device's fixed local id (`defaultShopId` — see
/// `lib/data/local/default_shop.dart`, a plain string, not a UUID) and
/// the real backend shop UUID assigned by `create_shop_and_owner`
/// (`supabase/migrations/0006_owner_onboarding_rpc.sql`) once onboarding
/// completes.
///
/// This is the concrete fix for the gap flagged in the M1 auth PR: local
/// rows are seeded under `defaultShopId` at `onCreate`
/// (`lib/data/local/app_database.dart`'s `_seed`), long before a real
/// backend shop exists, so a local row's `shopId` can never literally
/// equal the backend one. Rather than rewriting every local row's
/// `shopId` in place once onboarding finishes (a real migration touching
/// every table, for a value nothing local actually branches on), the
/// substitution happens once, at the two points where a row actually
/// crosses the local/remote boundary — pushed by [SyncPushService],
/// pulled by [SyncPullService] — so every other part of the app can keep
/// treating `defaultShopId` as this device's one true shop id.
abstract final class ShopIdBridge {
  /// Rewrites a JSON row's `shopId`/`shop_id` key from the local id to
  /// the real backend shop id before it is sent to `apply_outbox_event`
  /// — the RPC's RLS checks compare the row's `shop_id` against
  /// `my_shop_id()`, which only ever returns the real backend id.
  static Map<String, Object?> toRemote(
    Map<String, Object?> row, {
    required String localKey,
    required String remoteShopId,
  }) {
    if (row[localKey] != defaultShopId) return row;
    return {...row, localKey: remoteShopId};
  }

  /// The mirror-image substitution for a row just pulled down from
  /// Supabase, before it is written into the local Drift database —
  /// every local foreign key ultimately traces back to the single
  /// `defaultShopId` [Shops] row seeded at `onCreate`, not to whatever
  /// real UUID the backend assigned.
  static Map<String, Object?> toLocal(
    Map<String, Object?> row, {
    required String remoteKey,
    required String remoteShopId,
  }) {
    if (row[remoteKey] != remoteShopId) return row;
    return {...row, remoteKey: defaultShopId};
  }
}
