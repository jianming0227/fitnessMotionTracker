import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // -----------------------------------------------------------------------
  // TODO: Replace these placeholder values with your real Supabase project
  // URL and anon key from: https://app.supabase.com → Project Settings → API
  // -----------------------------------------------------------------------
  static const String _supabaseUrl = 'https://kridzoqafghzdzlatqdl.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtyaWR6b3FhZmdoemR6bGF0cWRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzNDEzMjcsImV4cCI6MjA4OTkxNzMyN30.w9tD0ME9t3zxXM35Mhe8vCRaKBKiJwS-EjQaJlnv5dg';

  /// Must be called once at app startup (before runApp).
  static Future<void> init() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // ── Auth ─────────────────────────────────────────────────────────────────

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async => client.auth.signOut();

  User? get currentUser => client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  Future<void> upsertProfile(Map<String, dynamic> data) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await client.from('profiles').upsert({'id': userId, ...data});
  }

  // ── Remote Workout Logs ───────────────────────────────────────────────────

  Future<void> syncWorkoutSession(Map<String, dynamic> data) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await client.from('workout_sessions').upsert({'user_id': userId, ...data});
  }

  Future<List<Map<String, dynamic>>> fetchWorkoutHistory({int limit = 20}) async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final response = await client
        .from('workout_sessions')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }
}
