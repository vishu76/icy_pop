import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/driver_state.dart';
import 'background_callback.dart';
import 'database.dart';

class DriverLocationService {
  StreamSubscription<Position>? _subscription;
  DriverState _state = DriverState.offline;

  Future<void> setState(DriverState newState) async {
    if (_state == newState) return;
    _state = newState;

    await _stopTracking();

    if (_state == DriverState.onlineIdle) {
      _startLowPowerTracking();
    } else if (_state == DriverState.onTrip) {
      _startHighAccuracyTracking();
    }
  }

  // ---------------- IDLE (LOW POWER) ----------------
  void _startLowPowerTracking() {
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 300, // meters
      ),
    ).listen(_onLocation);
  }

  // ---------------- TRIP (HIGH ACCURACY) ----------------
  void _startHighAccuracyTracking() {
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
      ),
    ).listen(_onLocation);
  }

  Future<void> _onLocation(Position position) async {
    // final connectivity = await Connectivity().checkConnectivity();
    // if (connectivity == ConnectivityResult.none) return;
    print('Location Sending VISHU: Latitude: ${position.latitude} , Longitude: ${position.longitude}');
    // Save to database
    final dbResult = await DatabaseHelper.instance.insertLocation(
      position.latitude,
      position.longitude,
    );
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
    // await ApiService.sendLocation(
    //   lat: position.latitude,
    //   lng: position.longitude,
    //   speed: position.speed,
    // );
  }

  Future<void> _stopTracking() async {
    await _subscription?.cancel();
    _subscription = null;
  }
  Future<void> dispose() async {
    await _stopTracking();
  }
  Future<void> startForegroundService() async {
    await FlutterForegroundTask.startService(
      notificationTitle: 'Driver Online',
      notificationText: 'Location tracking is active',
    );
  }
  Future<void> stopForegroundService() async {
    await FlutterForegroundTask.stopService();
  }
}
