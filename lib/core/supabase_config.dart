/// Supabase project credentials.
///
/// SETUP:
/// 1. Create a project at https://supabase.com (free tier).
/// 2. Go to Project Settings → API → copy URL and anon/public key.
/// 3. Replace the placeholder values below.
/// 4. Run the SQL schema in docs/supabase_schema.sql on your Supabase project.
class SupabaseConfig {
  /// Your Supabase project URL, e.g. https://xyzabcdef.supabase.co
  static const String url = 'https://YOUR_PROJECT.supabase.co';

  /// Your Supabase anon/public key (safe to ship in client apps).
  static const String anonKey = 'YOUR_ANON_KEY';

  /// Returns true when real credentials have been configured.
  static bool get isConfigured =>
      url != 'https://YOUR_PROJECT.supabase.co' &&
      anonKey != 'YOUR_ANON_KEY';
}
