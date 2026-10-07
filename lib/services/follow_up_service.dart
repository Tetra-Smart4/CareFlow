import '../repositories/follow_up_repository.dart';

class FollowUpService {
  final FollowUpRepository repository = FollowUpRepository();
  Future<List<Map<String, dynamic>>> load() => repository.list();
}
