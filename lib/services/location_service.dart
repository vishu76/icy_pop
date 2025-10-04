import 'dart:developer';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class LocationService {
  static Future<void> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("❌ Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        _showPermissionDialog();
        throw Exception("❌ Location permissions are denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showPermissionDialog();
      throw Exception("❌ Location permissions are permanently denied.");
    }
  }

  static void _showPermissionDialog() {
    Get.defaultDialog(
      title: "Location Permission Required",
      middleText:
          "This app requires location access to function properly. Please enable it in settings.",
      textConfirm: "Open Settings",
      textCancel: "Exit",
      onConfirm: () {
        Geolocator.openAppSettings();
      },
      onCancel: () {
        Get.back(); // Exit dialog
      },
      barrierDismissible: false, // Prevent closing without action
    );
  }

  static Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
