
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';


class LocationPermissionManager {
  static final LocationPermissionManager instance =
  LocationPermissionManager._internal();

  LocationPermissionManager._internal();

  bool _dialogVisible = false;

  /// Call this when:
  /// - App starts
  /// - Driver taps "Go Online"
  Future<bool> ensureLocationReady() async {
    // 1️⃣ Permission check
    final permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        _showPermissionDialog();
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showPermissionDialog(openSettings: true);
      return false;
    }

    // 2️⃣ GPS service check
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showGpsDialog();
      return false;
    }

    return true;
  }

  void _showPermissionDialog({bool openSettings = false}) {
    if (_dialogVisible || Get.context == null) return;
    _dialogVisible = true;

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Location permission is required for driver tracking.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Get.back();
                _dialogVisible = false;

                if (openSettings) {
                  await Geolocator.openAppSettings();
                } else {
                  await Geolocator.requestPermission();
                }
              },
              child: const Text('ENABLE'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showGpsDialog() {
    if (_dialogVisible || Get.context == null) return;
    _dialogVisible = true;

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('Location Services Off'),
          content: const Text(
            'Please enable GPS to continue driver tracking.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Get.back();
                _dialogVisible = false;
                await Geolocator.openLocationSettings();
              },
              child: const Text('TURN ON GPS'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}
