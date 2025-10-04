import 'package:get/get.dart';
import 'api_manager.dart';

class AuthService extends GetxService {
  final ApiManager _apiManager = Get.find<ApiManager>();
  final RxBool isAuthenticated = false.obs;

  Future<bool> validateToken() async {
    final token = await _apiManager.getToken();

    // Check if token is present and not empty
    return token != null && token.isNotEmpty;
  }


  Future<AuthService> init() async {
    // Check if token exists on app start
    final token = await _apiManager.getToken();
    isAuthenticated.value = token != null;
    return this;
  }

  Future<bool> isLoggedIn() async {
    return isAuthenticated.value;
  }

  Future<void> logout() async {
    await _apiManager.clearToken();
    isAuthenticated.value = false;
  }

  Future<bool> isTokenValid() async {
    final token = await _apiManager.getToken();
    return token != null && token.isNotEmpty;
  }
}