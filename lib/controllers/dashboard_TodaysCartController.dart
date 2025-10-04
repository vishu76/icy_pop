import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ice_cream/services/api_manager.dart';
import '../models/CartDataModel.dart';
import '../services/api_services.dart';

class TodaysCartController extends GetxController {
  final ApiManager _apiManager = Get.find<ApiManager>();
  final Rx<CartDataModel?> cartData = Rx<CartDataModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Observables for UI
  final RxString cartNumber = ''.obs;
  final RxString address = ''.obs;
  final RxString date = ''.obs;
  final RxInt totalQuantity = 0.obs;
  final RxInt refillQuantity = 0.obs;
  final RxInt returnQuantity = 0.obs;

  final List<TextEditingController> acceptQtyControllers = [];
  final List<TextEditingController> refillQtyControllers = [];
  final List<TextEditingController> returnQtyControllers = [];

  // Getters for products
  List<StockProduct> get stockProducts => cartData.value?.data.stockProductData ?? [];
  List<RefillProduct> get refillProducts => cartData.value?.data.refilledProductData ?? [];
  List<ReturnProduct> get returnProducts => cartData.value?.data.returnlist ?? [];

  @override
  void onInit() {
    super.onInit();
    // Initialize controllers when data is loaded
    ever(cartData, (cart) {
      if (cart != null) {
        _initializeQuantityControllers();
      }
    });
  }

  void _initializeQuantityControllers() {
    // Clear existing controllers
    for (var controller in acceptQtyControllers) {
      controller.dispose();
    }
    for (var controller in refillQtyControllers) {
      controller.dispose();
    }
    for (var controller in returnQtyControllers) {
      controller.dispose();
    }

    acceptQtyControllers.clear();
    refillQtyControllers.clear();
    returnQtyControllers.clear();

    // Initialize controllers for each product type with proper pre-filling
    for (var product in stockProducts) {
      // Pre-fill with full quantity for accept
      acceptQtyControllers.add(TextEditingController(
        text: product.quantity.toString(),
      ));
    }

    for (var product in refillProducts) {
      // Pre-fill with full quantity for refill
      refillQtyControllers.add(TextEditingController(
        text: product.quantity.toString(),
      ));
    }

    for (var product in returnProducts) {
      // Pre-fill with full quantity for return
      returnQtyControllers.add(TextEditingController(
        text: product.quantity.toString(),
      ));
    }

    print('[DEBUG] Controllers initialized - Accept: ${acceptQtyControllers.length}, Refill: ${refillQtyControllers.length}, Return: ${returnQtyControllers.length}');
  }
  Future<void> fetchTodaysCartDetail() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final token = await _apiManager.getToken();

      await APIManager().apiRequest(
        Get.context!,
        API.todayswheelcartdetail, // Make sure this endpoint exists in your API class
        params: {}, // Add any required parameters
        onSuccess: (response) {
          final responseData = json.decode(response);
          if (responseData['status'] == 'success') {
            final cartDataModel = CartDataModel.fromJson(responseData);
            cartData.value = cartDataModel;

            // Update observables
            cartNumber.value = cartDataModel.data.cartNumber;
            address.value = cartDataModel.data.address;
            date.value = cartDataModel.data.convertedDate;

            // Calculate quantities
            totalQuantity.value = _calculateTotalQuantity();
            refillQuantity.value = _calculateRefillQuantity();
            returnQuantity.value = _calculateReturnQuantity();

          } else {
            errorMessage.value = responseData['msg'] ?? 'Failed to fetch cart details';
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

  // ACCEPT CART API CALL
  Future<void> submitCartAcceptance() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final token = await _apiManager.getToken();
      final cart = cartData.value!.data;

      // Prepare product list with accepted quantities
      List<Map<String, dynamic>> productList = [];

      for (int i = 0; i < stockProducts.length; i++) {
        var product = stockProducts[i];
        String enteredQuantity = acceptQtyControllers[i].text;
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
        'cart_req_id': cart.id.toString(),
        'product_list': json.encode(productList),
      };

      print('[DEBUG] Submitting cart acceptance: ${json.encode(params)}');

      await APIManager().apiRequest(
        Get.context!,
        API.acceptedCartQuantity,
        params: params,
        token: token,
        onSuccess: (response) {
          final responseData = json.decode(response);
          if (responseData['status'] == 'success') {
            Get.snackbar(
              'Success',
              responseData['msg'] ?? 'Cart accepted successfully',
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            // Refresh cart data after acceptance
            fetchTodaysCartDetail();
          } else {
            errorMessage.value = responseData['msg'] ?? 'Failed to accept cart';
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

  // REFILL CART API CALL
  Future<void> submitRefillData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final token = await _apiManager.getToken();
      final cart = cartData.value!.data;

      // Prepare refill product list with accepted quantities
      List<Map<String, dynamic>> productList = [];

      for (int i = 0; i < refillProducts.length; i++) {
        var product = refillProducts[i];
        String enteredQuantity = refillQtyControllers[i].text;
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
        'cart_req_id': cart.id.toString(),
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
            // Refresh cart data after refill
            fetchTodaysCartDetail();
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

  // RETURN CART API CALL
  Future<void> submitReturnData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final token = await _apiManager.getToken();
      final cart = cartData.value!.data;

      // Prepare product list with return quantities
      List<Map<String, dynamic>> productList = [];
      bool allZero = true;

      for (int i = 0; i < returnProducts.length; i++) {
        var product = returnProducts[i];
        String enteredQuantity = returnQtyControllers[i].text;
        int returnQuantity = enteredQuantity.isEmpty
            ? product.quantity
            : int.tryParse(enteredQuantity) ?? product.quantity;

        // Ensure return quantity doesn't exceed available quantity
        returnQuantity = returnQuantity.clamp(0, product.quantity);

        // Check if at least one product has non-zero quantity
        if (returnQuantity > 0) {
          allZero = false;
        }

        productList.add({
          'pr_id': product.id,
          'product_id': product.productId,
          'quantity': product.quantity,
          'accepted_quantity': returnQuantity // Using accepted_quantity field for return
        });
      }

      // If all return quantities are 0, send empty product list
      if (allZero) {
        productList = [];
      }

      final params = {
        'cart_req_id': cart.id.toString(),
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
              responseData['msg'] ?? 'Cart returned successfully',
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            // Refresh cart data for next cart
            fetchTodaysCartDetail();
          } else {
            errorMessage.value = responseData['msg'] ?? 'Failed to return cart';
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

  // Helper methods for quantity calculations
  int _calculateTotalQuantity() {
    if (cartData.value == null) return 0;
    int total = 0;
    for (var product in cartData.value!.data.stockProductData) {
      total += product.quantity;
    }
    return total;
  }

  int _calculateRefillQuantity() {
    if (cartData.value == null) return 0;
    int total = 0;
    for (var product in cartData.value!.data.refilledProductData) {
      total += product.quantity;
    }
    return total;
  }

  int _calculateReturnQuantity() {
    if (cartData.value == null) return 0;
    int total = 0;
    for (var product in cartData.value!.data.returnlist) {
      total += product.quantity;
    }
    return total;
  }

  // Method to update product quantity in real-time
  void updateProductQuantity(int index, String fieldName, String value, String type) {
    try {
      print('Updating $fieldName for product index $index with value $value in $type section');
      // You can add additional validation or business logic here
    } catch (e) {
      print('Error updating product quantity: $e');
    }
  }

  // Method to refresh cart data
  Future<void> refreshCartData() async {
    await fetchTodaysCartDetail();
  }

  @override
  void onClose() {
    // Dispose all controllers
    for (var controller in acceptQtyControllers) {
      controller.dispose();
    }
    for (var controller in refillQtyControllers) {
      controller.dispose();
    }
    for (var controller in returnQtyControllers) {
      controller.dispose();
    }
    super.onClose();
  }
}