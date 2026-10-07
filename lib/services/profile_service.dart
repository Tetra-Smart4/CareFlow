import '../repositories/profile_repository.dart';

class ProfileService {
  final ProfileRepository repository = ProfileRepository();

  /// Loads the profile of the currently authenticated user.
  ///
  /// Returns null when there is no authenticated user or
  /// when a matching profile does not exist.
  Future<Map<String, dynamic>?> getCurrentProfile() {
    return repository.getCurrentProfile();
  }

  /// Loads all profiles.
  ///
  /// Kept for compatibility with the existing service layer.
  Future<List<Map<String, dynamic>>> load() {
    return repository.list();
  }
}
