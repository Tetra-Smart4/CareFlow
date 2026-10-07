import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  bool loading = false;
  String? error;
  void setLoading(bool value) {
    loading = value;
    notifyListeners();
  }

  void setError(String? value) {
    error = value;
    notifyListeners();
  }
}
