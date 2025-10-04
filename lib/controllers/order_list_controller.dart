// controllers/order_list_controller.dart
import 'dart:convert';
import 'dart:developer'; // For logging
import 'package:get/get.dart';
import '../models/order_list.dart';
import '../services/api_manager.dart';
import '../services/api_services.dart';
import '../services/auth_service.dart';
import '../utils/token_expiry_dialog.dart';
import '../views/out_order_details.dart';

class OrderListController extends GetxController {
  final RxList<WheelCartOrder> orders = <WheelCartOrder>[].obs;
  final ApiManager _apiManager = Get.find<ApiManager>();
  final AuthService _authService = Get.find<AuthService>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString apiResponse = ''.obs; // To store raw API response
  final RxBool tokenExpired = false.obs;

  Future<void> fetchOrders() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      orders.clear();
      apiResponse.value = '';

      log("Starting to fetch orders...");

      final token = await _apiManager.getToken();
      log("Using token: ${token?.substring(0, 10)}..."); // Log first 10 chars of token

      Map<String, dynamic> requestBody = {
        "cart_status": "Out",
      };

      await APIManager().apiRequest(
        Get.context!,
        API.wheelCartOrderList,
        params: requestBody,
        token: token,
        onSuccess: (response) {
          log("API Success Response: $response");
          apiResponse.value = response;

          try {
            final responseData = json.decode(response);
            log("Decoded response data: $responseData");

            log('going for token expiry');
            if (responseData['status'] == 'Failed' &&
                responseData['Msg']?.contains('Token is expired, login again') == true) {
              log('inside token expiry');
              showTokenExpiryDialog(Get.context!);
              return;
            }

            if (responseData['status'] == 'success') {
              final List<dynamic> data = responseData['data'] ?? [];
              log("Found ${data.length} orders in response");

              if (data.isEmpty) {
                errorMessage.value = 'API returned empty data array';
                log("Empty data array received");
              } else {
                orders.value = data.map((json) => WheelCartOrder.fromJson(json)).toList();
                log("Successfully parsed ${orders.length} orders");
              }
            } else {
              // errorMessage.value = responseData['msg'] ?? 'API returned non-success status';
              errorMessage.value = responseData['msg'] ?? responseData['response']['Msg'];
              log("API error: ${errorMessage.value}");
            }
          } catch (e) {
            errorMessage.value = 'Failed to parse API response: $e';
            log("JSON parsing error: $e");
          }
        },
        onFailure: (error) {
          errorMessage.value = error.toString();
          log("API request failed: $error");
        },
      );
    } catch (e) {
      errorMessage.value = 'Unexpected error: $e';
      log("Unexpected error in fetchOrders: $e");
    } finally {
      isLoading.value = false;
      log("Fetch completed. Orders: ${orders.length}, Error: ${errorMessage.value}");
    }
  }

  void navigateToOrderDetail(String encryptedSeriesId) {
    Get.to(() => OutOrderDetailScreen(), arguments: encryptedSeriesId);
  }


  @override
  void onInit() {
    fetchOrders();
    super.onInit();
  }
}