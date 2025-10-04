import 'dart:async';
import 'dart:developer';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

void startLocationTracking(ServiceInstance service) {
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('Location services disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        log('Location permissions not granted.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      log('Background Location: ${position.latitude}, ${position.longitude}');

      // Optionally send location data to the main app
      service.invoke("updateLocation", {
        "latitude": position.latitude,
        "longitude": position.longitude,
      });

    } catch (e) {
      log('Error in background service: $e');
    }
  });
}
