import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../models/out_order.dart';
import '../services/api_manager.dart';
import '../services/api_services.dart';

class RequestOrderDetailController extends GetxController {
  final ApiManager _apiManager = Get.find<ApiManager>();
  final Rx<OutOrderData?> orderDetail = Rx<OutOrderData?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final Map<int, bool> acceptedProducts = <int, bool>{}.obs;
  final Map<int, String> rejectedProducts = <int, String>{}.obs;
  Map<String, TextEditingController> quantityControllers = {};
  final Map<int, int> productStatuses = <int, int>{}.obs;


  void acceptProduct({required int productId}) {
    acceptedProducts[productId] = true;
    rejectedProducts.remove(productId);
    update();
  }

  void rejectProduct({required int productId, required String reason}) {
    rejectedProducts[productId] = reason;
    acceptedProducts.remove(productId);
    update();
  }


  Future<void> submitAcceptedQuantities() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final token = await _apiManager.getToken();
      final order = orderDetail.value!;

      // Prepare product list with accepted quantities
      List<Map<String, dynamic>> productList = [];

      for (var product in order.stockProductData) {
        // Get the accepted quantity from the text field
        // If no quantity is entered, use the original quantity
        String enteredQuantity = quantityControllers['${product.id}']?.text ?? '';
        int acceptedQuantity = enteredQuantity.isEmpty
            ? product.quantity
            : int.tryParse(enteredQuantity) ?? product.quantity;

        // Ensure accepted quantity doesn't exceed available quantity
        acceptedQuantity = acceptedQuantity.clamp(0, product.quantity);

        productList.add({
          'pr_id': product.id,
          'product_id': product.productId, // Assuming you have productId in ProductData
          'quantity': product.quantity,
          'accepted_quantity': acceptedQuantity
        });
      }

      final params = {
        'cart_req_id': order.cartSeries, // Using cartSeries as cart_req_id
        'product_list': json.encode(productList),
      };

      print('[DEBUG] Submitting accepted quantities: ${json.encode(params)}');

      await APIManager().apiRequest(
        Get.context!,
        API.acceptedCartQuantity, // You'll need to add this to your API class
        params: params,
        token: token,
        onSuccess: (response) {
          final responseData = json.decode(response);
          if (responseData['status'] == 'success') {
            Get.snackbar(
              'Success',
              responseData['msg'] ?? 'Order accepted successfully',
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            // Navigate back or to another screen
            Get.back();
          } else {
            errorMessage.value = responseData['msg'] ?? 'Failed to accept order';
            Get.snackbar(
              'Error',
              errorMessage.value,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
        onFailure: (error) {
          errorMessage.value = error.toString();
          Get.snackbar(
            'Error',
            'Failed to submit: $error',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
      );
    } catch (e) {
      errorMessage.value = 'Error: $e';
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> submitProductStatus({
    required int productId,
    required int status,
  }) async {
    try {
      print('[DEBUG] Starting submitProductStatus for product $productId with status $status');
      isLoading.value = true;
      errorMessage.value = '';

      final token = await _apiManager.getToken();
      print('[DEBUG] Token retrieved successfully');

      final order = orderDetail.value!;
      print('[DEBUG] Order details: ${order.cartSeries}');

      final params = {
        'wheel_cart_series_id': order.cartSeries,
        'status': status.toString(),
      };
      print('[DEBUG] Request params: $params');

      // Print complete URL for verification
      print('[DEBUG] Complete URL: ${ConfigManager.baseURL}${API.approveRequest}');

      await APIManager().apiRequest(
        Get.context!,
        API.approveRequest,
        params: params,
        token: token,
        onSuccess: (response) {
          print('[DEBUG] API Response: $response');
          print('Token: $token');
          try {
            final responseData = json.decode(response);
            print('[DEBUG] Parsed response: $responseData');

            if (responseData['status'] == 'success') {
              print('[DEBUG] API call successful');
              Get.snackbar(
                'Success',
                responseData['msg'] ?? 'Action completed successfully',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );

              // Determine where to navigate based on status
              /*if (status == 1) {
                // Accepted - Navigate to OrderListScreen
                Get.offAllNamed('/orders');
              } else if (status == 2) {
                // Rejected - Navigate to RequestListScreen
                Get.offAllNamed('/requests');
              }*/

            } else {
              errorMessage.value = responseData['msg'] ?? 'Failed to update status';
              print('[ERROR] API returned failure: ${errorMessage.value}');
              Get.snackbar(
                'Error',
                errorMessage.value,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }
          } catch (e) {
            print('[ERROR] Failed to parse response: $e');
            errorMessage.value = 'Failed to parse server response';
            Get.snackbar(
              'Error',
              'Failed to process server response',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
        onFailure: (error) {
          print('[ERROR] API request failed: $error');
          print('[DEBUG] Request details:');
          print('- URL: ${ConfigManager.baseURL}${API.approveRequest}');
          print('- Params: $params');

          errorMessage.value = 'Failed to connect to server (Error: $error)';
          Get.snackbar(
            'Connection Error',
            'Could not reach server. Please try again.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
      );
    } catch (e, stackTrace) {
      print('[CRITICAL] Unexpected error: $e');
      print('[STACK TRACE] $stackTrace');
      errorMessage.value = 'Unexpected error occurred';
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      print('[DEBUG] Operation completed');
      isLoading.value = false;
    }
  }

  Future<void> fetchOrderDetail(String encryptedSeriesId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      orderDetail.value = null;

      final token = await _apiManager.getToken();

      await APIManager().apiRequest(
        Get.context!,
        API.wheelCartOutOrderDetail,
        params: {'wheel_cart_series_id': encryptedSeriesId},
        onSuccess: (response) {
          final responseData = json.decode(response);
          if (responseData['status'] == 'success') {
            orderDetail.value = OutOrderData.fromJson(responseData['data']);
          } else {
            errorMessage.value = responseData['msg'] ?? 'Failed to fetch order details';
          }
        },
        onFailure: (error) {
          errorMessage.value = error.toString();
        },
        token: token,
      );
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
