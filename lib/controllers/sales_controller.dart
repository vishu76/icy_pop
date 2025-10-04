// controllers/sales_controller.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_manager.dart';
import '../services/api_services.dart';

class SalesController extends GetxController {
  final ApiManager _apiManager = Get.find<ApiManager>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  Future<void> addSales({
    required String cartSeries,
    required String cartId,
    required String warehouseId,
    required List<Map<String, dynamic>> productList,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final token = await _apiManager.getToken();

      final requestBody = {
        "cart_series": cartSeries,
        "cart_id": cartId,
        "warehouse_id": warehouseId,
        "product_list": productList,
      };

      await APIManager().apiRequest(
        Get.context!,
        API.wheelCartIn,
        params: requestBody,
        onSuccess: (response) {
          final responseData = json.decode(response);
          if (responseData['status'] == 'success') {
            Get.back(); // Close the dialog
            Get.snackbar(
              'Success',
              'Sales added successfully',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          } else {
            throw Exception(responseData['msg'] ?? 'Failed to add sales');
          }
        },
        onFailure: (error) {
          throw Exception(error.toString());
        },
        token: token,
      );
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}