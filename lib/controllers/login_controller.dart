// login_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_manager.dart';

class LoginController extends GetxController {
  final ApiManager _apiManager = ApiManager();
  final RxBool isLoading = false.obs;
  final RxString mobileNumber = ''.obs;
  final RxString otp = ''.obs;
  final RxString mobileError = ''.obs;
  final RxString otpError = ''.obs;

  // For OTP auto-fill
  final RxBool isOtpValid = false.obs;
  final RxBool isResendEnabled = false.obs;
  final RxInt countdown = 60.obs;

  Future<void> login(String mobile, String otp, String selfieImage) async {
    try {
      isLoading.value = true;

      final response = await _apiManager.postRequest(
        ApiConstants.loginEndpoint,
        {
          'mobilenumber': mobile,
          'otp': otp,
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
        await prefs.setString('user_name', response['data']['name'] ?? '');
        await prefs.setString('user_email', response['data']['email'] ?? '');
        await prefs.setString('user_mobile', response['data']['mobilenumber']?.toString() ?? '');

        print("Data");
print(jsonEncode(response['data']));
        Get.offNamed('/dashboard');
        Get.snackbar('Success', response['msg'] ,
            snackPosition: SnackPosition.BOTTOM,backgroundColor: Colors.green);
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

  // Validate mobile number
  void validateMobile(String value) {
    mobileNumber.value = value;

    if (value.isEmpty) {
      mobileError.value = 'Please enter mobile number';
    } else if (!GetUtils.isPhoneNumber(value)) {
      mobileError.value = 'Please enter a valid mobile number';
    } else if (value.length != 10) {
      mobileError.value = 'Mobile number must be 10 digits';
    } else {
      mobileError.value = '';
    }
  }

  // Update OTP
  void updateOtp(String value) {
    otp.value = value;
    isOtpValid.value = value.length == 6;

    if (value.isEmpty) {
      otpError.value = 'Please enter OTP';
    } else if (value.length != 6) {
      otpError.value = 'OTP must be 6 digits';
    } else {
      otpError.value = '';
    }
  }

  // Send OTP API call
  Future<void> sendOtp() async {
    if (mobileError.value.isNotEmpty || mobileNumber.value.length != 10) {
      Get.snackbar('Error', 'Please enter a valid mobile number',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    try {
      isLoading.value = true;

      final response = await _apiManager.postRequest(
        ApiConstants.sendOtpEndpoint, // You need to define this in your API constants
        {'mobile_number': mobileNumber.value},
        requiresAuth: false,
      );
print("response");
print(response['status']);
print(response['msg']);
      if (response['status'] == 'success') {
        Get.snackbar('Success', 'OTP sent successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white);

        // Start countdown for resend
        startCountdown();
      } else {
        Get.snackbar('Error', response['msg'] ?? 'Failed to send OTP',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Start countdown timer for resend OTP
  void startCountdown() {
    isResendEnabled.value = false;
    countdown.value = 60;

    Timer.periodic(Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        isResendEnabled.value = true;
        timer.cancel();
      }
    });
  }

  // Clear OTP
  void clearOtp() {
    otp.value = '';
    otpError.value = '';
    isOtpValid.value = false;
  }
}