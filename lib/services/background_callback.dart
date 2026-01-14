import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:ice_cream/services/database.dart';
 import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import '../utils/token_expiry_dialog.dart';
import 'api_manager.dart';
import 'background_api_manager.dart';
import 'foreground_task_handler.dart';
import 'location_service.dart';
import 'notification_helper.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final startTime = DateTime.now();
    log('⚡ [${startTime.toIso8601String()}] Task STARTED: $task');

    try {
      // Initialize only if needed
      if (!Get.isRegistered<SharedPreferences>()) {
        WidgetsFlutterBinding.ensureInitialized();
        final sharedPreferences = await SharedPreferences.getInstance();
        Get.put(sharedPreferences, permanent: true);
        Get.put(ApiManager(), permanent: true);
      }

      if (task == "fetchLocationTask") {
        log('📍 Starting location fetch process...');

        final permission = await Geolocator.checkPermission();
        if (permission != LocationPermission.always &&
            permission != LocationPermission.whileInUse) {
          log('⚠️ Location permission not granted: $permission');
          return Future.value(true);
        }

        log('🛰️ Requesting current position...');
        Position position = await LocationService.getCurrentLocation();

        log('User Location for api: ${position.latitude}, ${position.longitude}');
        log('🌍 Location acquired: ${position.latitude}, ${position.longitude}');

        final dbResult = await DatabaseHelper.instance.insertLocation(
          position.latitude,
          position.longitude,
        );

        log(dbResult > 0
            ? '💾 Saved to database (ID: $dbResult)'
            : '❌ Failed to save to database');

        final cartUserId = Get.find<SharedPreferences>().getString('cart_user_id') ?? 'test_user';
        await sendLocationToAPI(
          cartUserId: cartUserId,
          wheelCartNumber: "MH12BC1230",
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    } catch (e, stack) {
      log('❌ TASK ERROR: $e');
      log('🔍 Stack trace: $stack');
      return Future.value(false); // Return false to trigger backoff
    } finally {
      final duration = DateTime.now().difference(startTime);
      log('✅ Task COMPLETED in ${duration.inMilliseconds}ms');
    }

    return Future.value(true);
  });
}

Future<void> sendLocationToAPI({
  required String cartUserId,
  required String wheelCartNumber,
  required double latitude,
  required double longitude,
}) async {
  try {
    // 1. Get the authentication token
    // final _apiManager = Get.find<ApiManager>();
    final _apiManager = BackgroundApiManager(); // direct instance
    final token = await _apiManager.getToken();
    // print('Token for location: $token');
    // if (token == null || token.isEmpty) {
    //   log('No authentication token available');
    //   return;
    // }
    // log('🔹 Using token: ${token.substring(0, 10)}...');
    // 2. Prepare the request
    final url = Uri.parse("https://uatadmin.icypopps.com/api/wheelcartmaster/add-wheel-cart-location");
    var request = http.MultipartRequest('POST', url);

    // 3. Add headers (including authorization)
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    // 4. Add form fields
    String locationDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    request.fields.addAll({
      "cart_user_id": cartUserId,
      "wheel_cart_number": wheelCartNumber,
      "location_date": locationDate,
      "longitude": longitude.toString(),
      "latitude": latitude.toString(),
    });
    // 5. Send request
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final decoded = jsonDecode(responseBody);
    // final status = decoded['status'];
    final n = decoded['n'];
    final msg = decoded['msg'] ?? '';
    if (kDebugMode) {
      print('Status Code: ${response.statusCode}');
    }
    if(response.statusCode == 200){
      // success
      if (kDebugMode) {
        print('Location sent successfully: $responseBody');
      }
      if (n == 1) {
        if (kDebugMode) {
          print('Vishu Driver Tracking');
        }
       }else if (n == 2) {
        if (kDebugMode) {
          print('Vishu Stop Tracking');
        }
        // STOP FOREGROUND SERVICE HERE
        if (await FlutterForegroundTask.isRunningService) {
          await FlutterForegroundTask.stopService();
        }
        await showStopTrackingNotification(
          '$msg',
        );
      } else {
        if (kDebugMode) {
          print('Vishu Success with unexpected n: $n');
        }
      }
    }else if(response.statusCode == 401){
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.remove('auth_token');
      // field
      if (kDebugMode) {
        print('API Failed: $msg');
      }
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
      await showStopTrackingNotification(
        '$msg',
      );
    }else{
      // another
      if (kDebugMode) {
        print(' Unknown status: $response.statusCode');
      }
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
      await showStopTrackingNotification(
         'Tracking stopped. Unknown Status: ${response.statusCode}',
      );
    }
  } catch (e, stack) {
    if (kDebugMode) {
      print('Exception in sendLocationToAPI: $e');
    }
  }


}
