import 'dart:developer';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:workmanager/workmanager.dart';
import '../services/background_callback.dart';
import '../services/location_service.dart';

class DashboardController extends GetxController {
  var selectedDate = DateTime.now().subtract(Duration(days: 1)).obs;
  final Map<DateTime, List<int>> salesData = {};
  final LocationService _locationService = LocationService();
  var dashboardData = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> rawProductSales = <Map<String, dynamic>>[].obs;
  final Rx<DateTime> fromDate = DateTime.now().obs;
  final Rx<DateTime> toDate = DateTime.now().obs;

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

  void startLocationTracking() {
    log('Entered the start Location tracking');
    Future.delayed(Duration(minutes: 1), () async {
      callbackDispatcher();
      Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: true,
      );
      try {
        Position position = await LocationService.getCurrentLocation();
        callbackDispatcher();
        log('User Location: ${position.latitude}, ${position.longitude}');
      } catch (error) {
        log('Error obtaining location: $error');
      }
      startLocationTracking();
    });
  }
}
