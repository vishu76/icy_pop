import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ice_cream/services/api_manager.dart';

import '../models/out_order.dart'; // This should now contain the new model structure

import '../services/api_services.dart';
import '../views/order_list_screen.dart';

class OutOrderDetailController extends GetxController {
  final ApiManager _apiManager = Get.find<ApiManager>();
  final Rx<OutOrderData?> orderDetail = Rx<OutOrderData?>(null); // Changed to OutOrderData
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Map<String, String> quantityErrors = <String, String>{}.obs;
  final Map<int, int> acceptedProducts = <int, int>{}.obs;
  final Map<int, String> rejectedProducts = <int, String>{}.obs;
  Map<String, TextEditingController> quantityControllers = {};
  final RxString selectedAction = 'Accept'.obs;
  final Map<String, TextEditingController> returnQuantityControllers = {};
  final Map<String, String> returnQuantityErrors = <String, String>{}.obs;
  // Add these methods
  void acceptProduct({required int productId, required int quantity}) {
    acceptedProducts[productId] = quantity;
    rejectedProducts.remove(productId);
    update();
  }

  void rejectProduct({required int productId, required String reason}) {
    rejectedProducts[productId] = reason;
    acceptedProducts.remove(productId);
    update();
  }

  @override
  void onInit() {
    super.onInit();
    // Initialize controllers when data is loaded
    ever(orderDetail, (order) {
      if (order != null) {
        _initializeQuantityControllers(order);
      }
    });
  }

  void _initializeQuantityControllers(OutOrderData order) {
    quantityControllers.clear();

    // Initialize for stock products
    for (var product in order.stockProductData) {
      quantityControllers['${product.id}'] = TextEditingController(
          text: product.acceptedQuantity.toString()
      );
    }

    // Initialize for refill products
    for (var product in order.refilledProductData) {
      quantityControllers['${product.id}'] = TextEditingController(
          text: product.acceptedQuantity.toString()
      );
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
            // Parse using the new response model
            final outOrderResponse = OutOrderResponse.fromJson(responseData);
            orderDetail.value = outOrderResponse.data;
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
  Future<void> submitAcceptedQuantities(String encryptedSeriesId) async {
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
        'cart_req_id': order.id, // Using cartSeries as cart_req_id
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
            fetchOrderDetail(encryptedSeriesId);
            // Navigate back or to another screen
            //Get.back();
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
// In your OutOrderDetailController
  Future<void> submitRefillQuantities(String encryptedSeriesId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final token = await _apiManager.getToken();
      final order = orderDetail.value!;

      // Prepare refill product list with accepted quantities
      List<Map<String, dynamic>> productList = [];

      for (var product in order.refilledProductData) {
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
          'product_id': product.productId,
          'quantity': product.quantity,
          'accepted_quantity': acceptedQuantity
        });
      }

      final params = {
        'cart_req_id': order.id,
        'product_list': json.encode(productList),
      };

      print('[DEBUG] Submitting refill quantities: ${json.encode(params)}');

      await APIManager().apiRequest(
        Get.context!,
        API.acceptedCartQuantity, // Same API as accept
        params: params,
        token: token,
        onSuccess: (response) {
          final responseData = json.decode(response);
          if (responseData['status'] == 'success') {
            Get.snackbar(
              'Success',
              responseData['msg'] ?? 'Refill submitted successfully',
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            fetchOrderDetail(encryptedSeriesId);
          } else {
            errorMessage.value = responseData['msg'] ?? 'Failed to submit refill';
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


  Future<void> returnCartQuantity(String encryptedSeriesId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final token = await _apiManager.getToken();
      final order = orderDetail.value!;

      // Prepare product list with accepted quantities
      List<Map<String, dynamic>> productList = [];
      bool allZero = true;

      for (var product in order.stockProductData) {
        // Get the accepted quantity from the text field
        String enteredQuantity = quantityControllers['${product.id}']?.text ?? '';
        int acceptedQuantity = enteredQuantity.isEmpty
            ? product.quantity
            : int.tryParse(enteredQuantity) ?? product.quantity;

        // Ensure accepted quantity doesn't exceed available quantity
        acceptedQuantity = acceptedQuantity.clamp(0, product.quantity);

        // Check if at least one product has non-zero quantity
        if (acceptedQuantity > 0) {
          allZero = false;
        }

        productList.add({
          'pr_id': product.id,
          'product_id': product.productId,
          'quantity': product.quantity,
          'accepted_quantity': acceptedQuantity
        });
      }

      // If all accepted quantities are 0, send empty product list
      if (allZero) {
        productList = [];
      }

      final params = {
        'cart_req_id': order.id,
        'product_list': json.encode(productList),
      };

      print('[DEBUG] Submitting return quantities: ${json.encode(params)}');

      await APIManager().apiRequest(
        Get.context!,
        API.returnCartQuantity,
        params: params,
        token: token,
        onSuccess: (response) {
          final responseData = json.decode(response);
          if (responseData['status'] == 'success') {
            Get.snackbar(
              'Success',
                'Order returned successfully',
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            Get.offAll(() => OrderListScreen(),
              arguments: {'refresh': true},
              predicate: (route) => route.isFirst,
            );
          } else {
            errorMessage.value = responseData['msg'] ?? 'Failed to return order';
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
  Future<void> submitCheckIn() async {
    try {
      print('[DEBUG] Starting submitCheckIn process');

      if (orderDetail.value == null) {
        print('[WARNING] orderDetail is null - aborting check-in');
        return;
      }

      isLoading.value = true;
      errorMessage.value = '';
      final order = orderDetail.value!;

      print('[DEBUG] Order details loaded - cartSeries: ${order.cartSeries}');
      print('[DEBUG] Warehouse ID: ${order.warehouseId}');

      // Get authentication token
      final token = await _apiManager.getToken();
      print('[DEBUG] Token retrieved (first 10 chars): ${token?.substring(0, 10)}...');

      // Prepare the request body with detailed logging
      print('[DEBUG] Preparing request body...');
      final requestBody = {
        'cart_series': order.cartSeries.toString(),
        'cart_id': order.id.toString(), // Use the main order ID instead of cart_id
        'warehouse_id': order.warehouseId.toString(),
        'product_list': order.stockProductData.map((product) {
          print('[DEBUG] Processing product ${product.id}');
          final controller = quantityControllers['${product.id}'];
          final acceptedQuantity = controller?.text ?? product.acceptedQuantity.toString();

          return {
            'product_id': product.productId.toString(),
            'accepted_quantity': acceptedQuantity,
            // Since there are no batches in the new response, we'll send empty batch list
            'batch_list': [],
          };
        }).toList(),
      };

      print('[DEBUG] Complete request body:');
      print(json.encode(requestBody));

      // Make the API call
      print('[DEBUG] Making API request to ${API.wheelCartIn}');

      await APIManager().apiRequest(
        Get.context!,
        API.wheelCartIn,
        params: requestBody,
        onSuccess: (response) {
          print('[DEBUG] API Response: $response');
          try {
            final responseData = json.decode(response);
            print('[DEBUG] Parsed response: $responseData');

            if (responseData['status'] == 'success') {
              print('[SUCCESS] Check-in completed successfully');
              Get.snackbar(
                'Success',
                'Order checked in successfully',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                duration: Duration(seconds: 3),
              );

              // Navigate back after successful operation
              print('[NAVIGATION] Returning to previous screen');
              Get.back();
            } else {
              errorMessage.value = responseData['msg'] ?? 'Failed to check in order';
              print('[ERROR] API returned failure: ${errorMessage.value}');
              Get.snackbar(
                responseData['status'] ?? 'Error',
                responseData['msg'] ?? 'Failed to submit check-in',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: Duration(seconds: 4),
              );
            }
          } catch (e) {
            print('[ERROR] Failed to parse response: $e');
            errorMessage.value = 'Failed to process server response';
            Get.snackbar(
              'Error',
              'Invalid server response',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
        onFailure: (error) {
          print('[ERROR] API request failed: $error');
          errorMessage.value = error.toString();
          Get.snackbar(
            'Connection Error',
            'Failed to connect to server',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
        token: token,
      );
    } catch (e, stackTrace) {
      print('[CRITICAL ERROR] Unhandled exception: $e');
      print('[STACK TRACE] $stackTrace');
      errorMessage.value = 'Unexpected error occurred';
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      print('[DEBUG] submitCheckIn process completed');
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    // Dispose all controllers
    quantityControllers.values.forEach((controller) => controller.dispose());
    super.onClose();
  }
}