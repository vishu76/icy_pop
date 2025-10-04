import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../services/auth_service.dart';

void showTokenExpiryDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('Session Expired'),
      content: Text('Your session has expired. Please login again.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Get.find<AuthService>().logout();
            Get.offAllNamed('/login'); // Adjust to your login route
          },
          child: Text('OK'),
        ),
      ],
    ),
  );
}