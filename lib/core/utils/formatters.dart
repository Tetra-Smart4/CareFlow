class Formatters {
  static String currency(num value) => '₹${value.toStringAsFixed(0)}';
  static String time(String raw) => raw;
}
