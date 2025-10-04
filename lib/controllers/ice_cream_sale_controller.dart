import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IceCreamSaleController extends GetxController {
  final int availableStock;

  RxInt sold = 0.obs;

  IceCreamSaleController({required this.availableStock});

  /// Updates the sold quantity. If the entered quantity exceeds [availableStock],
  /// it shows an error and resets [sold] to [availableStock].
  void updateSale(String value) {
    int sale = int.tryParse(value) ?? 0;
    if (sale > availableStock) {
      Get.snackbar(
        "Error",
        "You cannot sell more than the available stock ($availableStock).",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      sold.value = availableStock;
    } else {
      sold.value = sale;
    }
  }
}
