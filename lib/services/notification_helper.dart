import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

Future<void> showStopTrackingNotification(String message) async {
  const androidDetails = AndroidNotificationDetails(
    'tracking_alerts',
    'Tracking Alerts',
    channelDescription: 'Driver tracking alerts',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@drawable/ic_notification',
  );

  const details = NotificationDetails(android: androidDetails);

  await _notifications.show(
    1001,
    'Tracking Stopped',
    message,
    details,
  );
}
