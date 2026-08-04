/// Connection info for the M1 sync backend's Supabase project — see
/// ARCHITECTURE.md's "Supabase (Postgres) schema" section for the schema
/// itself and `supabase/migrations/` for what's actually live.
///
/// The anon/publishable key is safe to ship in the client binary by
/// design: it identifies the project, not a privileged credential. Every
/// permission decision is enforced server-side by row-level security
/// (`supabase/migrations/0001`-`0007`), never by keeping this key
/// secret — see `apply_standard_rls`/`apply_append_only_rls` in
/// `0001_foundations.sql`.
abstract final class SupabaseConfig {
  static const url = 'https://dzplxtidfsoovmocgikc.supabase.co';

  /// The modern `sb_publishable_...` key (see `Supabase.initialize`'s
  /// `publishableKey` parameter) — functionally identical to the legacy
  /// JWT-based anon key for our purposes (still just identifies the
  /// project; RLS is still the real permission boundary), but the one
  /// `supabase_flutter` 2.16 doesn't deprecate.
  static const publishableKey =
      'sb_publishable_BoBKPAzDQFuUzqCjbGG6FA_gnDiotgn';
}
