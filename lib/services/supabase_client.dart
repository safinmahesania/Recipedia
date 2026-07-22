import 'package:supabase_flutter/supabase_flutter.dart';

/// Single Supabase entry point. Call initSupabase() once in main() before runApp.
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
}

/// Shorthand used across services.
SupabaseClient get supabase => Supabase.instance.client;
