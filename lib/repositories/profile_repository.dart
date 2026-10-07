import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  SupabaseClient get client => Supabase.instance.client;

  /// Returns the profile belonging to the currently
  /// authenticated Supabase user.
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = client.auth.currentUser;

    if (user == null) {
      return null;
    }

    final result = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return result;
  }

  /// Returns all profiles.
  ///
  /// Kept for compatibility with the existing service layer.
  Future<List<Map<String, dynamic>>> list({String? orderBy}) async {
    final query = client.from('profiles').select();

    final result = orderBy == null ? await query : await query.order(orderBy);

    return List<Map<String, dynamic>>.from(result);
  }
}
