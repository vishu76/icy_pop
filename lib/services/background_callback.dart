import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:ice_cream/services/database.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'api_manager.dart';
import 'location_service.dart';

/*void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    log('⚡ WorkManager - Task STARTED: ${task} at ${DateTime.now()}');

    try {
      WidgetsFlutterBinding.ensureInitialized();
      final sharedPreferences = await SharedPreferences.getInstance();
      Get.put(sharedPreferences);
      Get.put(ApiManager(), permanent: true);

      log('🔹 SharedPreferences initialized');

      try {
        final apiManager = Get.find<ApiManager>();
        log('✅ ApiManager initialized successfully');
      } catch (e) {
        log('❌ Failed to initialize ApiManager: $e');
        return Future.value(false);
      }

      if (task == "fetchLocationTask") {
        log('🔹 Location tracking task identified');

        LocationPermission permission = await Geolocator.checkPermission();
        log('🔹 Location permission status: $permission');

        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          log('❌ Location permission denied');
          return Future.value(true);
        }

        log('🔹 Getting current position...');
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 10),
        );
        log('📍 Location obtained: ${position.latitude}, ${position.longitude}');

        log('🔹 Saving to local database...');
        int result = await DatabaseHelper.instance.insertLocation(
            position.latitude,
            position.longitude
        );

        if (result > 0) {
          log('💾 Location saved to database (ID: $result)');

          final cartUserId = sharedPreferences.getString('cart_user_id');
          final wheelCartNumber = "MH12BC1230"; // Hardcoded for testing

          log('Calling sendLocationToAPI...');
          await sendLocationToAPI(
            cartUserId: cartUserId ?? 'test_user',
            wheelCartNumber: wheelCartNumber,
            latitude: position.latitude,
            longitude: position.longitude,
          );
        } else {
          log('❌ Failed to save location to database');
        }
      }
    } catch (e, stack) {
      log('❌ ERROR in callbackDispatcher: $e');
      log('Stack trace: $stack');
    }

    log('✅ WorkManager - Task COMPLETED');
    return Future.value(true);
  });
}*/

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

/*void callbackDispatcher() {
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

        // Check permissions
        final permission = await Geolocator.checkPermission();
        if (permission != LocationPermission.always &&
            permission != LocationPermission.whileInUse) {
          log('⚠️ Location permission not granted: $permission');
          return Future.value(true);
        }

        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
        } catch(e) {
          print(e);
        }
        final hasPermission = await Geolocator.checkPermission();

        if (hasPermission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
          // Send to API...
        } else {
          log("❌ Background location permission not granted.");
        }


        // Get location
        log('🛰️ Requesting current position...');
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ).timeout(Duration(seconds: 10), onTimeout: () {
          log('⏱️ Location request timed out');
          throw TimeoutException('Location request timeout');
        });

        log('🌍 Location acquired: ${position.latitude}, ${position.longitude}');

        // Save to database
        final dbResult = await DatabaseHelper.instance.insertLocation(
          position.latitude,
          position.longitude,
        );
        log(dbResult > 0
            ? '💾 Saved to database (ID: $dbResult)'
            : '❌ Failed to save to database');

        // Send to API
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
}*/

Future<void> sendLocationToAPI({
  required String cartUserId,
  required String wheelCartNumber,
  required double latitude,
  required double longitude,
}) async {
  log('🚀 STARTING sendLocationToAPI');

  try {
    // 1. Get the authentication token
    final _apiManager = Get.find<ApiManager>();
    final token = await _apiManager.getToken();
    print('Token for location: $token');

    if (token == null || token.isEmpty) {
      log('❌ No authentication token available');
      return;
    }

    log('🔹 Using token: ${token.substring(0, 10)}...');

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

    log('📤 Sending request with:');
    log('  - Headers: ${request.headers}');
    log('  - Body: ${request.fields}');

    // 5. Send request
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    log('🔹 Response:');
    log('Status Code: ${response.statusCode}');
    log('Body: $responseBody');

    if (response.statusCode == 200) {
      log('✅ Location sent successfully');
    } else {
      log('❌ Failed to send location (${response.statusCode})');
      if (response.statusCode == 401) {
        log('⚠️ Token might be expired or invalid');
        // Consider refreshing token here if needed
      }
    }
  } catch (e, stack) {
    log('❌ Error in sendLocationToAPI: $e');
    log('Stack trace: $stack');
  }
}
