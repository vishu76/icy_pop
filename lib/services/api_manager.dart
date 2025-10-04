import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

class ApiManager extends GetxService { // Changed to extend GetxService
  String? _token;

  Future<Map<String, dynamic>> getRequest(
      String endpoint, {
        bool requiresAuth = true,
      }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (requiresAuth) 'Authorization': 'Bearer ${await getToken()}',
      };

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
      );

      if (response.statusCode == 401) {
        await clearToken();
        throw Exception('Session expired. Please login again.');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw Exception(responseData['msg'] ?? 'Request failed');
      }
    } catch (e) {
      if (e.toString().contains('401')) {
        await clearToken();
      }
      throw Exception('Failed to make request: $e');
    }
  }

  Future<void> setToken(String token) async {
    _token = token;
    await Get.find<SharedPreferences>().setString('auth_token', token);
  }

  Future<String?> getToken() async {
    _token ??= Get.find<SharedPreferences>().getString('auth_token');
    return _token;
  }

  Future<void> clearToken() async {
    _token = null;
    await Get.find<SharedPreferences>().remove('auth_token');
  }

  Future<Map<String, dynamic>> postRequest(
      String endpoint,
      Map<String, dynamic> body, {
        bool requiresAuth = true,
      }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (requiresAuth) 'Authorization': 'Bearer ${await getToken()}',
      };

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 401) {
        await clearToken();
        Get.find<AuthService>().isAuthenticated.value = false;
        throw Exception('Session expired. Please login again.');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw Exception(responseData['msg'] ?? 'Request failed');
      }
    } catch (e) {
      if (e.toString().contains('401')) {
        await clearToken();
        Get.find<AuthService>().isAuthenticated.value = false;
      }
      throw Exception('Failed to make request: $e');
    }
  }
}