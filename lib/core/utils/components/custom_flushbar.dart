import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomThemeFlushbar {
  static void show({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    final context = Get.context;
    if (context == null) return;
    Flushbar(
      title: title,
      message: message,
      duration: duration,
      backgroundColor: Colors.black87,
      messageColor: Colors.white,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(16),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          offset: const Offset(0, 2),
          blurRadius: 6,
        ),
      ],
    ).show(context);
  }
}
