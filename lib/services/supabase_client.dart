import 'package:supabase_flutter/supabase_flutter.dart';

/// Single Supabase entry point. Call initSupabase() once in main() before runApp.
///
/// `anonKey` was deprecated in favour of `publishableKey`. This is a parameter
/// rename only — the dart-define name is unchanged, so existing build commands
/// keep working:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// Separately, Supabase is moving from legacy anon JWTs to the newer
/// `sb_publishable_...` key format. A legacy key still works here; check the
/// API keys page in your project dashboard before rotating the value itself.
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
}

/// Shorthand used across services.
SupabaseClient get supabase => Supabase.instance.client;
