import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

enum HTTPMethod { GET, POST, PUT, DELETE }

class ConnectionDetector {
  static Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true; // Internet is available
      }
    } catch (_) {
      // Internet is not available
    }
    return false;
  }
}

class ConfigManager {
  static String baseURL = 'https://uatadmin.icypopps.com/api/';
  // static String baseURL = 'https://admin.icypopps.com/api/';
  static String apiVersion = '';
  static Duration timeout = Duration();

  static void loadConfiguration(String configString) {
    Map config = jsonDecode(configString);
    var env = config['environment'];
    baseURL = config[env]['hostUrl'];
    apiVersion = config['version'];
    timeout = Duration(seconds: config[env]['timeout']);
    print('Configuration loaded: $configString');
  }

  static String getBaseURL() {
    return baseURL;

  }
}

// api/api_endpoints.dart
enum API {
  // General
  wheelCartOrderList,
  wheelCartOutOrderDetail,
  todayswheelcartdetail,
  wheelCartIn,
  wheelCartLiveLocation,
  dashboard,
  sendOtpEndpoint,
  viewRequest,
  approveRequest,
  acceptedCartQuantity,
  captainlogout,
  returnCartQuantity,

  // Other APIs as required...
}

class APIManager {
  static final APIManager _instance = APIManager._privateConstructor();

  APIManager._privateConstructor();

  factory APIManager() {
    return _instance;
  }
  //String? userId =  UserManager().getUserId() ; // Modify the method as per your UserManager
  Future<String> apiEndPoint(API api, {Map<String, dynamic>? queryParams}) async {
    var apiPathString = "";

    switch (api) {
      case API.wheelCartOrderList:
        apiPathString = "wheelcartmaster/mob-wheel-cart-order-list";
        break;
      case API.wheelCartOutOrderDetail:
        apiPathString = "wheelcartmaster/captain-ecart-out-order-detail";
        break;
      case API.wheelCartIn:
        apiPathString = "wheelcartmaster/captain-ecart-in";
        break;
      case API.captainlogout:
        apiPathString = "adminmaster/captain-logout";
        break;
      case API.wheelCartLiveLocation:
        apiPathString = "wheelcartmaster/add-wheel-cart-location";
        break;
      case API.todayswheelcartdetail:
        apiPathString = "wheelcartmaster/todays-wheel-cart-detail";
        break;
      case API.sendOtpEndpoint:
        apiPathString = "adminmaster/captain-login-send-otp";
        break;
      case API.dashboard:
        apiPathString = "wheelcartmaster/wheel-cart-dashboard";
        break;
      case API.viewRequest:
        apiPathString = "wheelcartmaster/captain-ecart-order-returned-list";
        break;
      case API.approveRequest:
        apiPathString = "wheelcartmaster/captain-approve-cart-load-status";
        break;
        case API.returnCartQuantity:
        apiPathString = "wheelcartmaster/captain-return-cart-quantity";
        break;
        case API.acceptedCartQuantity:
        apiPathString = "wheelcartmaster/captain-accept-cart-qty";
        break;
      default:
        apiPathString = "HomeheaderResponse";
    }

    print("URL:");
    print("${ConfigManager.getBaseURL() + apiPathString}");
    return ConfigManager.getBaseURL() + apiPathString;
  }

  HTTPMethod apiHTTPMethod(API api) {
    switch (api) {
      case API.wheelCartOrderList:
      case API.wheelCartOutOrderDetail:

      case API.wheelCartIn:
      case API.acceptedCartQuantity:
      case API.returnCartQuantity:
      case API.wheelCartLiveLocation:
      case API.dashboard:
      case API.viewRequest:
      case API.captainlogout:
      case API.sendOtpEndpoint:
      case API.approveRequest:
        return HTTPMethod.POST;
      default:
        return HTTPMethod.GET;
    }
  }

  void _handleTokenExpiry(BuildContext context) {
    // Clear auth state
    Get.find<AuthService>().logout();

    // Navigate to login with a dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Session Expired'),
          content: Text('Your session has expired. Please login again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.offAllNamed('/login'); // Adjust to your login route
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  bool _isTokenExpiredResponse(http.Response response) {
    try {
      final responseData = json.decode(response.body);
      return response.statusCode == 401 ||
          (responseData['status'] == 'Failed' &&
              responseData['Msg']?.contains('Token is expired') == true);
    } catch (e) {
      return false;
    }
  }
  // Inside APIManager class

  Future<void> apiRequest(
      BuildContext context,
      API api, {
        required dynamic params,
        required Function onSuccess,
        required Function onFailure,
        String? contactid,
        Map<String, dynamic>? queryParams,
        String? token,
      }) async {
    final isConnected = await ConnectionDetector.checkInternetConnection();

    if (!isConnected) {
      onFailure("Please check your Internet Connection.");
      return;
    }

    try {
      final String url = await apiEndPoint(api, queryParams: queryParams);
      var response;

      Map<String, String> headers = {};

      if (token != null && token.isNotEmpty) {
        print("token : $token");
        headers['Authorization'] = 'Bearer $token';
      }

      print("Request URL: $url");
      print("Request Headers: $headers");
      print("Request Params: $params");

      if (apiHTTPMethod(api) == HTTPMethod.GET) {
        response = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 30));
      } else {
        // Special case for wheelCartIn API
        if (api == API.wheelCartIn) {
          headers['Content-Type'] = 'application/json';

          response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(params),
          )
              .timeout(const Duration(seconds: 30));
        } else {
          // Default Multipart request
          var request = http.MultipartRequest("POST", Uri.parse(url));
          request.headers.addAll(headers);

          if (params != null) {
            params.forEach((key, value) {
              if (value != null) {
                request.fields[key] = value.toString();
              }
            });
          }

          final streamedResponse = await request.send();
          response = await http.Response.fromStream(streamedResponse);
        }
      }

      // Handle token expiry
      /*if (response.statusCode == 401) {
        final responseBody = json.decode(response.body);
        if (responseBody['Msg']?.contains('Token is expired') ?? false) {
          _handleTokenExpiry(context);
          return;
        }
      }*/

      if (_isTokenExpiredResponse(response)) {
        _handleTokenExpiry(context);
        return;
      }
      print("response statusCode");
      print(response.statusCode);
      if (response.statusCode == 200) {
        onSuccess(response.body);
      } else {
        onFailure('Error: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        onSuccess(response.body);
        print("params: ${params.toString()}");
      } else {
        onFailure('Error: ${response.statusCode}');
        print("params: ${params.toString()}");
      }
    } catch (e) {
      if (e is TimeoutException) {
        onFailure("Request timed out. Please try again later.");
      } else {
        onFailure("Request failed: $e");
      }
    }
  }
}