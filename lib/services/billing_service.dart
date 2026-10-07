import '../repositories/billing_repository.dart';

class BillingService {
  final BillingRepository repository = BillingRepository();
  Future<List<Map<String, dynamic>>> load() => repository.list();
}
