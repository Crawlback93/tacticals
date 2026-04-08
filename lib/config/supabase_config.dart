// Supabase configuration
// IMPORTANT: Use ONLY the "anon public" key here (Supabase Dashboard → Settings → API).
// NEVER use the service_role key in client-side code — it bypasses Row Level Security.
//
// Values are injected at build time via --dart-define.
// For local development copy .env.example → .env and use the launch config in .vscode/launch.json.
class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
