import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  SupabaseClient get client => Supabase.instance.client;
  Future<AuthResponse> signIn(String email, String password) =>
      client.auth.signInWithPassword(email: email, password: password);
  Future<AuthResponse> signUp(String email, String password) =>
      client.auth.signUp(email: email, password: password);
  Future<void> signOut() => client.auth.signOut();
  User? get currentUser => client.auth.currentUser;
}
