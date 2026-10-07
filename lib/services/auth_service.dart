import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../repositories/auth_repository.dart';

class AuthService {
  final AuthRepository _repo = AuthRepository();
  Future<bool> signIn(String email, String password) async {
    if (!SupabaseConfig.isConfigured) return true;
    await _repo.signIn(email, password);
    return true;
  }

  Future<bool> signUp(String email, String password) async {
    if (!SupabaseConfig.isConfigured) return true;
    await _repo.signUp(email, password);
    return true;
  }

  Future<void> signOut() async {
    if (SupabaseConfig.isConfigured) await _repo.signOut();
  }

  User? get currentUser =>
      SupabaseConfig.isConfigured ? _repo.currentUser : null;
}
