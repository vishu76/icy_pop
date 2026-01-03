import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:location/location.dart';

class LocationMonitor {
  static final LocationMonitor _instance = LocationMonitor._internal();
  factory LocationMonitor() => _instance;
  LocationMonitor._internal();

  final Location _location = Location();
  Timer? _checkTimer;
  bool _serviceDialogShown = false;
  bool _permissionDialogShown = false;
  bool _isInitialCheck = true;

  void startMonitoring() {
    // Check immediately
    _checkLocationStatusAndPermission();

    // Check every 3 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkLocationStatusAndPermission();
    });
  }

  Future<void> _checkLocationStatusAndPermission() async {
    try {
      // First check if we have location permission
      bool hasPermission = await _checkLocationPermission();

      print('Location Permission Status: $hasPermission');

      if (!hasPermission) {
        // No permission - show permission dialog
        if (!_permissionDialogShown) {
          _permissionDialogShown = true;
          _serviceDialogShown = false; // Reset service dialog flag

          // Wait a bit for initial navigation if it's the first check
          if (_isInitialCheck) {
            await Future.delayed(const Duration(milliseconds: 3000));
            _isInitialCheck = false;
          }

          _showPermissionDialog();
        }
        return;
      }

      // We have permission, now check if location service is enabled
      final serviceEnabled = await _location.serviceEnabled();
      print('Location Service Enabled: $serviceEnabled');

      if (!serviceEnabled && !_serviceDialogShown) {
        _serviceDialogShown = true;
        _permissionDialogShown = false; // Reset permission dialog flag

        // Wait a bit for initial navigation if it's the first check
        if (_isInitialCheck) {
          await Future.delayed(const Duration(milliseconds: 1500));
          _isInitialCheck = false;
        }

        _showLocationServiceDialog();
      } else if (serviceEnabled) {
        // Both permission granted and service enabled - reset all flags
        _serviceDialogShown = false;
        _permissionDialogShown = false;
        _isInitialCheck = false;
      }

    } catch (e) {
      print('Error checking location/permission: $e');
    }
  }

  Future<bool> _checkLocationPermission() async {
    try {
      // Get current permission status using location package
      var permissionStatus = await _location.hasPermission();
      print('Raw Permission Status: $permissionStatus');

      // Check if permission is granted
      bool isGranted = permissionStatus == PermissionStatus.granted ||
          permissionStatus == PermissionStatus.grantedLimited;

      return isGranted;
    } catch (e) {
      print('Error in _checkLocationPermission: $e');
      return false;
    }
  }

  void _showPermissionDialog() {
    // Use a delayed check to ensure Get.context is available
    Future.delayed(Duration.zero, () {
      if (Get.isDialogOpen ?? false) return;
      if (Get.context == null) return;

      Get.dialog(
        WillPopScope(
          onWillPop: () async {
            // Don't allow back button - force user to deal with permission
            return false;
          },
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.location_disabled, color: Colors.orange, size: 20),
                SizedBox(width: 10),
                Text('Location Permission Required', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This app needs access to your location to work properly.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Text(
                      'The app cannot function without location permission. '
                          'Please grant permission to continue.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    print('Requesting location permission...');
                    // Request location permission
                    var permissionStatus = await _location.requestPermission();
                    print('Permission request result: $permissionStatus');

                    if (permissionStatus == PermissionStatus.granted ||
                        permissionStatus == PermissionStatus.grantedLimited) {
                      _permissionDialogShown = false;
                      Get.back();
                      // Now check if location service is enabled
                      await Future.delayed(const Duration(milliseconds: 500));
                      _checkLocationStatusAndPermission();
                    } else {
                      // Permission denied - show message
                      Get.snackbar(
                        'Permission Denied',
                        'Please enable location permission in app settings',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 5),
                      );
                    }
                  },
                  child: const Text(
                    'GRANT LOCATION PERMISSION',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.7),
      );
    });
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  void _showLocationServiceDialog() {
    // Use a delayed check to ensure Get.context is available
    Future.delayed(Duration.zero, () {
      if (Get.isDialogOpen ?? false) return;
      if (Get.context == null) return;

      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.location_off, color: Colors.red, size: 30),
                SizedBox(width: 10),
                Text('Location Services Off', style: TextStyle(fontSize: 22)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your device\'s location services are turned off.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Please enable location services to use:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureItem('Real-time location tracking'),
                  _buildFeatureItem('Accurate sales recording'),
                  _buildFeatureItem('GPS-based delivery tracking'),
                  _buildFeatureItem('Route navigation'),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Text(
                      'Note: Location must be enabled with "High Accuracy" mode '
                          'for best results.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    print('Requesting location service...');
                    // Try to enable location service
                    final enabled = await _location.requestService();

                    if (enabled) {
                      _serviceDialogShown = false;
                      Get.back();
                      Get.snackbar(
                        'Success',
                        'Location services enabled',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                    } else {
                      // Show instruction to enable manually
                      Get.dialog(
                        AlertDialog(
                          title: const Text('Manual Setup Required'),
                          content: const Text(
                            'Please enable location services manually:\n\n'
                                '1. Go to Device Settings\n'
                                '2. Tap on "Location"\n'
                                '3. Turn ON location services\n'
                                '4. Set mode to "High Accuracy"\n\n'
                                'Return to the app after enabling location.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'TURN ON LOCATION SERVICES',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.7),
      );
    });
  }

  void stopMonitoring() {
    _checkTimer?.cancel();
  }
}