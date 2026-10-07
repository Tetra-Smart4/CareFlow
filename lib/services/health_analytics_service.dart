import '../repositories/analytics_repository.dart';

class HealthAnalyticsService {
  final AnalyticsRepository repository = AnalyticsRepository();
  Future<List<Map<String, dynamic>>> load() => repository.list();
}
