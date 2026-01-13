import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class BackgroundApiManager {
  String? _token;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token ??= prefs.getString('auth_token');
    return _token;
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<Map<String, dynamic>> postRequest(
      String endpoint,
      Map<String, dynamic> body, {
        bool requiresAuth = true,
      }) async {
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
      throw Exception('Unauthorized');
    }

    final responseData = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else {
      throw Exception(responseData['msg'] ?? 'Request failed');
    }
  }
}
