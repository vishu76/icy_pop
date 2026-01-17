import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import '../services/backgroundlocation_callback.dart';
import '../services/notification_helper.dart';

class DriverTrackingController {
  static final DriverTrackingController instance =
  DriverTrackingController._internal();

  DriverTrackingController._internal();

  Future<bool> isTrackingActive() async {
    return await FlutterForegroundTask.isRunningService;
  }

  Future<void> startTracking() async {
    try{
      // final ok = await canStartLocationFGS();
      // if (!ok) return;
      // await showStopTrackingNotification(
      //   'Location is turned off. Please enable GPS.',
      // );
      if (await FlutterForegroundTask.isRunningService) return;
      await FlutterForegroundTask.startService(
        notificationTitle: 'Driver Online',
        notificationText: 'Location tracking active',
        callback: startCallback,
      );
    }catch(e){
      if (kDebugMode) {
        print("trip: $e");
      }

    }

  }

  Future<void> stopTracking() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
    await showStopTrackingNotification(
      'Tracking has been stopped.',
    );
  }
  Future<bool> canStartLocationFGS() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final req = await Geolocator.requestPermission();
      if (req == LocationPermission.denied ||
          req == LocationPermission.deniedForever) {
        return false;
      }
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }

    return true;
  }

}
