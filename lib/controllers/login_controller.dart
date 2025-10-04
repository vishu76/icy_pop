// login_controller.dart
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import '../constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_manager.dart';

class LoginController extends GetxController {
  final ApiManager _apiManager = ApiManager();
  final RxBool isLoading = false.obs;

  Future<void> login(String email, String password,String selfieImage) async {

    try {
      isLoading.value = true;

      final response = await _apiManager.postRequest(
        ApiConstants.loginEndpoint,
        {
          'email': email,
          'password': password,
          'user_image': selfieImage,
        },
        requiresAuth: false,
      );

      if (response['status'] == 'success') {
        // Store the token
        await _apiManager.setToken(response['token']);
        // Store user data if needed
        final prefs = Get.find<SharedPreferences>();
        await prefs.setString('user_data', jsonEncode(response['data']));
        await prefs.setString('cart_user_id', response['data']['id'].toString());

        Get.offNamed('/dashboard');
       // Get.offNamed('/selfie');
      } else {
        Get.snackbar('', response['msg'] ?? 'Login failed',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}