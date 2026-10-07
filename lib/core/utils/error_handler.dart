import 'package:flutter/material.dart';

class ErrorHandler {
  static void show(BuildContext context, Object error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.toString())));
  }
}
