import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'backgroundlocation_callback.dart';
import 'database.dart';
import 'background_callback.dart';
import 'notification_helper.dart';

class LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _subscription;

   @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // This starts when the service starts, even if the app is killed
     final enabled = await Geolocator.isLocationServiceEnabled();
     if (!enabled) {
       await showStopTrackingNotification(
         'Location is turned off. Please enable GPS.',
       );
       await FlutterForegroundTask.stopService();
       return;
     }
    _startTracking();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isStoppedBySystem) async {
    await _subscription?.cancel();
    _subscription = null;
  }
@override
  Future<void> onRepeatEvent(DateTime timestamp) async {
   if (kDebugMode) {
     print('Foreground service alive at $timestamp');
   }
  }
  @override
  void onNotificationPressed() {
    if (kDebugMode) {
      print('Foreground Notification Pressed');
    }
  }
  @override
  void onReceiveData(Object data) {
    super.onReceiveData(data);
    if (kDebugMode) {
      print('Foreground Data Received $data');
    }
  }
  @override
  void onNotificationButtonPressed(String id) {
    super.onNotificationButtonPressed(id);
    if (kDebugMode) {
      print('Foreground Notification Button Pressed: $id');
    }
  }
  @override
  void onNotificationDismissed() {
     super.onNotificationDismissed();
     if (kDebugMode) {
       print('Foreground Notification Dismissed');
     }
  }
  void _startTracking() {
    if (_subscription != null) return;
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
      ),
    ).listen((position) async {
      print('Vishu Foreground Location: ${position.latitude}, ${position.longitude}');
      final sharedPreferences = await SharedPreferences.getInstance();
      final cartUserId = sharedPreferences.getString('cart_user_id') ?? 'test_user';
      await DatabaseHelper.instance.insertLocation(
        position.latitude,
        position.longitude,
      );
      await sendLocationToAPI(
        cartUserId: cartUserId,
        wheelCartNumber: 'MH12BC1230',
        latitude: position.latitude,
        longitude: position.longitude,
      );
    },onError: (error) async {
      // HANDLE GPS OFF / ERROR
      print("start tracking Error: $error");
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        await showStopTrackingNotification(
          'Location is turned off. Tap to enable GPS.',
        );
        if (await FlutterForegroundTask.isRunningService) {
          await FlutterForegroundTask.stopService();
        }
      }else{
        await showStopTrackingNotification(
          'Location Error: $error',
        );
      }
    }
    );
  }
  Future<void> startDriverTracking() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) return;
    await FlutterForegroundTask.startService(
      notificationTitle: 'Driver Online',
      notificationText: 'Location tracking active',
      callback: startCallback,
    );
  }
  Future<void> stopDriverTracking() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (!isRunning) return;
    await FlutterForegroundTask.stopService();
    await showStopTrackingNotification(
      'Tracking has been stopped.',
    );
  }
}
