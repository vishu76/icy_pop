// controllers/request_list_controller.dart
import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import '../models/order_list.dart'; // Reusing the same model
import '../services/api_manager.dart';
import '../services/api_services.dart';
import '../services/auth_service.dart';
import '../views/order_request_details.dart';
import '../views/out_order_details.dart';

class RequestListController extends GetxController {
  final RxList<WheelCartOrder> requests = <WheelCartOrder>[].obs;
  final ApiManager _apiManager = Get.find<ApiManager>();
  final AuthService _authService = Get.find<AuthService>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString apiResponse = ''.obs;

  Future<void> fetchRequests() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      requests.clear();
      apiResponse.value = '';

      log("Starting to fetch requests...");

      final token = await _apiManager.getToken();
      log("Using token: ${token?.substring(0, 10)}...");

      Map<String, dynamic> requestBody = {
        "cart_status": "Out",
      };

      await APIManager().apiRequest(
        Get.context!,
        API.viewRequest,
        params: requestBody,
        token: token,
        onSuccess: (response) {
          log("API Success Response: $response");
          apiResponse.value = response;

          try {
            final responseData = json.decode(response);
            log("Decoded response data: $responseData");

            if (responseData['status'] == 'success') {
              final List<dynamic> data = responseData['data'] ?? [];
              log("Found ${data.length} requests in response");

              if (data.isEmpty) {
                errorMessage.value = 'No pending requests found';
                log("Empty data array received");
              } else {
                requests.value = data.map((json) => WheelCartOrder.fromJson(json)).toList();
                log("Successfully parsed ${requests.length} requests");
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
      log("Unexpected error in fetchRequests: $e");
    } finally {
      isLoading.value = false;
      log("Fetch completed. Requests: ${requests.length}, Error: ${errorMessage.value}");
    }
  }

  void navigateToRequestDetail(String encryptedSeriesId) {
    Get.to(() => RequestOrderDetailScreen(), arguments: encryptedSeriesId);
  }

  @override
  void onInit() {
    fetchRequests();
    super.onInit();
  }
}