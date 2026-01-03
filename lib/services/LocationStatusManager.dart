// location_status_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';

class LocationStatusManager extends GetxController {
  static LocationStatusManager get instance => Get.find();

  final RxBool _isLocationEnabled = false.obs;
  final RxBool _showDialog = false.obs;
  final RxBool _isChecking = false.obs;

  bool get isLocationEnabled => _isLocationEnabled.value;
  bool get showDialog => _showDialog.value;

  final Location _location = Location();
  Timer? _checkTimer;

  @override
  void onInit() {
    super.onInit();
    _startLocationMonitoring();
  }

  void _startLocationMonitoring() {
    // Check immediately
    _checkLocationStatus();

    // Check every 2 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkLocationStatus();
    });
  }

  Future<void> _checkLocationStatus() async {
    if (_isChecking.value) return;

    _isChecking.value = true;
    try {
      final enabled = await _location.serviceEnabled();
      _isLocationEnabled.value = enabled;

      if (!enabled && !_showDialog.value) {
        _showDialog.value = true;
        _showLocationDialog();
      } else if (enabled) {
        _showDialog.value = false;
      }
    } catch (e) {
      print("Error checking location status: $e");
    } finally {
      _isChecking.value = false;
    }
  }

  void _showLocationDialog() {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text("Location Required", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, size: 50, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                "Location services are turned off. Please enable location to track your sales and deliveries.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Features that require location:",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "• Sales tracking\n• Delivery locations\n• Route optimization\n• Attendance marking",
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _openLocationSettings();
              },
              child: const Text("TURN ON LOCATION"),
            ),
            TextButton(
              onPressed: () {
                _checkLocationStatus(); // Check again before closing
                _showDialog.value = false;
                Get.back();
              },
              child: const Text("CONTINUE WITHOUT LOCATION"),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _openLocationSettings() async {
    try {
      final enabled = await _location.requestService();

      if (enabled) {
        _showDialog.value = false;
        Get.back();
        Get.snackbar(
          "Success",
          "Location services enabled",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "Attention",
          "Please enable location from device settings",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not open location settings",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Manual check from any screen if needed
  Future<bool> checkLocationManually() async {
    final enabled = await _location.serviceEnabled();
    _isLocationEnabled.value = enabled;
    return enabled;
  }

  @override
  void onClose() {
    _checkTimer?.cancel();
    super.onClose();
  }
}