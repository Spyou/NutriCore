import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomThemeFlushbar {
  String title;
  String message;
  CustomThemeFlushbar({required this.title, required this.message});
  static void show({required String title, required String message}) {
    Flushbar(
      title: title,
      message: message,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.black87,
      messageColor: Colors.white,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(16),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          offset: const Offset(0, 2),
          blurRadius: 6,
        ),
      ],
    ).show(Get.context!);
  }
}
