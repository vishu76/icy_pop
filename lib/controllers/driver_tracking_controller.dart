import 'package:flutter_foreground_task/flutter_foreground_task.dart';
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
    if (await FlutterForegroundTask.isRunningService) return;

    await FlutterForegroundTask.startService(
      notificationTitle: 'Driver Online',
      notificationText: 'Location tracking active',
      callback: startCallback,
    );
  }

  Future<void> stopTracking() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
    await showStopTrackingNotification(
      'Tracking has been stopped.',
    );
  }
}
