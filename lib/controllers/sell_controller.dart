import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'dashbord_controller.dart';

class SellController extends GetxController {
  final DashboardController _dashboardController =
      Get.find<DashboardController>();


  void submitSales(List<int> sales) {
    _dashboardController.addSalesForDate(
      _dashboardController.selectedDate.value,
      sales,
    );
    Get.back();
    Get.snackbar(
      'Success',
      'Sales data saved successfully!',
      backgroundColor: Colors.pink[400],
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
