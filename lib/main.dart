import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:ice_cream/services/api_manager.dart';
import 'package:ice_cream/services/auth_service.dart';
import 'package:ice_cream/views/Selfie_Capture_Page.dart';

import 'package:ice_cream/views/login_page.dart';
import 'package:ice_cream/views/new_dashbord_screen.dart';
import 'package:ice_cream/views/order_list_screen.dart';
import 'package:ice_cream/views/request_list_screen.dart';
import 'package:ice_cream/views/sell_page.dart';
import 'package:ice_cream/views/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize shared preferences
    final sharedPreferences = await SharedPreferences.getInstance();
    // Register services
    Get.put(sharedPreferences);
    Get.put(ApiManager());
    await Get.putAsync(() => AuthService().init());
   /* await Geolocator.requestPermission();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'driver_tracking',
        channelName: 'Working Tracking',
        channelDescription: 'Tracks driver location',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),

      foregroundTaskOptions: ForegroundTaskOptions(
        autoRunOnBoot: true,
        allowWakeLock: true,
        eventAction: ForegroundTaskEventAction.repeat(60000),
        // eventAction: ForegroundTaskEventAction.nothing(),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),

    );*/
    // FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Request permissions and initialize the service.
      _requestPermissions();
      _initService();
    });
     runApp(const MyApp());
  } catch (e, stackTrace) {
    log("🔥 Fatal error during initialization: $e");
    log("Stack trace: $stackTrace");
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: Text('Initialization failed: ${e.toString()}')),
      ),
    ));
  }
}
Future<void> _requestPermissions() async {
  // Android 13+, you need to allow notification permission to display foreground service notification.
  // iOS: If you need notification, ask for permission.
  final NotificationPermission notificationPermission = await FlutterForegroundTask.checkNotificationPermission();
  if (notificationPermission != NotificationPermission.granted) {
    await FlutterForegroundTask.requestNotificationPermission();
  }
  if (Platform.isAndroid) {
    // Android 12+, there are restrictions on starting a foreground service.
    // To restart the service on device reboot or unexpected problem, you need to allow below permission.
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
   /* // Use this utility only if you provide services that require long-term survival,
    // such as exact alarm service, healthcare service, or Bluetooth communication.
    // This utility requires the "android.permission.SCHEDULE_EXACT_ALARM" permission.
    // Using this permission may make app distribution difficult due to Google policy.
    if (!await FlutterForegroundTask.canScheduleExactAlarms) {
      // When you call this function, will be gone to the settings page.
      // So you need to explain to the user why set it.
      await FlutterForegroundTask.openAlarmsAndRemindersSettings();
    }*/
  }
}

void _initService() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'foreground_service',
      channelName: 'Foreground Service Notification',
      channelDescription: 'This notification appears when the foreground service is running.',
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      // eventAction: ForegroundTaskEventAction.repeat(5000),
      eventAction: ForegroundTaskEventAction.nothing(),
      autoRunOnBoot: true,
      autoRunOnMyPackageReplaced: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ice Cream Sales',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SplashScreen()),
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/dashboard', page: () => NewDashbordScreen()),
        GetPage(name: '/sell', page: () => SellPage()),
        GetPage(name: '/selfie', page: () => SelfieCapturePage()),
        GetPage(name: '/orders', page: () => OrderListScreen()),
        GetPage(name: '/requests', page: () => RequestListScreen()),
      ],
      builder: (context, child) {
        return AuthWrapper(child: child!);
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = Get.find<AuthService>();

  @override
  void initState() {
    super.initState();

    _authService.isAuthenticated.listen((isAuthenticated) {
      _handleAuthStateChange(isAuthenticated);
    });
  }

  void _handleAuthStateChange(bool isAuthenticated) {
    final currentRoute = Get.currentRoute;

    if (currentRoute == '/' || currentRoute == '/login') return;

    if (!isAuthenticated) {
      Get.offAllNamed('/login');
    } else if (currentRoute == '/login') {
      Get.offAllNamed('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}