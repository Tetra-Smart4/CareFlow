class HealthMetric {
  final String name;
  final double value;
  final String unit;
  final String trend;
  final String status;
  const HealthMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.trend,
    required this.status,
  });
}
