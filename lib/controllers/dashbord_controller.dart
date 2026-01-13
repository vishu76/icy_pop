import 'dart:async';
import 'dart:developer';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:workmanager/workmanager.dart';
import '../services/background_callback.dart';
import '../services/database.dart';
import '../services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardController extends GetxController {
  var selectedDate = DateTime.now().subtract(Duration(days: 1)).obs;
  final Map<DateTime, List<int>> salesData = {};
  // final LocationService _locationService = LocationService();
  var dashboardData = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> rawProductSales = <Map<String, dynamic>>[].obs;
  final Rx<DateTime> fromDate = DateTime.now().obs;
  final Rx<DateTime> toDate = DateTime.now().obs;
  // Timer? _backgroundTaskTimer;

  @override
  void onInit() {
    super.onInit();
  //  _initializeWorkManager();
  }

  @override
  void onClose() {
    // _backgroundTaskTimer?.cancel();
    super.onClose();
  }

  void setRawProductSales(List<Map<String, dynamic>> data) {
    rawProductSales.value = data;
  }

  void onDateSelected(DateTime date) {
    selectedDate.value = date;
  }

  void addSalesForDate(DateTime date, List<int> sales) {
    DateTime normDate = DateTime(date.year, date.month, date.day);
    salesData[normDate] = sales;
    log(salesData.toString());
  }

  List<int> getDummySalesData() {
    return [10, 5, 15, 8, 20, 0, 12, 7, 3, 18, 9, 11];
  }

  List<int> getSalesForSelectedDate() {
    DateTime today = DateTime.now();
    DateTime normToday = DateTime(today.year, today.month, today.day);
    DateTime normSelected = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
    );

    if (normSelected.isBefore(normToday)) {
      return getDummySalesData();
    }

    return salesData[normSelected] ?? List.filled(12, 0);
  }

  DateTime getDisplayedDate() {
    DateTime today = DateTime.now();
    DateTime normToday = DateTime(today.year, today.month, today.day);
    DateTime normSelected = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
    );

    if (normSelected.isBefore(normToday)) {
      return normSelected;
    }
    return normSelected;
  }

/*  Future<void> _initializeWorkManager() async {
    try {
      // Cancel any existing tasks first
      await Workmanager().cancelAll();

      // Initialize WorkManager
      await Workmanager().initialize(
        callbackDispatcher, // The top-level function
        isInDebugMode: true,
      );

      log('✅ WorkManager initialized successfully');

      // Register the periodic task
*//*      await Workmanager().registerPeriodicTask(
        "locationTask",
        "fetchLocationTask",
        frequency: Duration(minutes: 1),
        initialDelay: Duration(seconds: 10),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );*//*

      log('✅ Periodic task registered (every 1 minute)');

    } catch (e, stack) {
      log('❌ Error initializing WorkManager: $e');
      log('Stack trace: $stack');
    }
  }*/

/*  void startLocationTracking() {
    log('🔄 Starting location tracking...');

    // Start WorkManager for background tasks
    _initializeWorkManager();

    // Also track location in foreground periodically
    _backgroundTaskTimer?.cancel();
    _backgroundTaskTimer = Timer.periodic(Duration(minutes: 15), (timer) async {
      try {
        log('📍 Foreground location update triggered');

        // Get current location
        Position position = await LocationService.getCurrentLocation();
        log('📍 Current Location: ${position.latitude}, ${position.longitude}');

        // Save to database
        final dbResult = await DatabaseHelper.instance.insertLocation(
          position.latitude,
          position.longitude,
        );

        if (dbResult > 0) {
          log('💾 Location saved to database (ID: $dbResult)');

          // Send to API immediately in foreground
          final sharedPreferences = await SharedPreferences.getInstance();
          final cartUserId = sharedPreferences.getString('cart_user_id') ?? 'test_user';
          final wheelCartNumber = "MH12BC1230";

          // Call the sendLocationToAPI function directly
          await sendLocationToAPI(
            cartUserId: cartUserId,
            wheelCartNumber: wheelCartNumber,
            latitude: position.latitude,
            longitude: position.longitude,
          );
        }
      } catch (error) {
        log('❌ Error obtaining location in foreground: $error');
      }
    });
  }

  void stopLocationTracking() {
    _backgroundTaskTimer?.cancel();
    Workmanager().cancelAll();
    log('🛑 Location tracking stopped');
  }*/

}