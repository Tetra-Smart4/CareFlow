class Payment {
  final String id;
  final String billId;
  final double amount;
  final String method;
  final String status;
  const Payment({
    required this.id,
    required this.billId,
    required this.amount,
    required this.method,
    required this.status,
  });
}
