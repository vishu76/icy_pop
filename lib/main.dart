import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ice_cream/services/api_manager.dart';
import 'package:ice_cream/services/auth_service.dart';
import 'package:ice_cream/services/background_callback.dart';
import 'package:ice_cream/views/Selfie_Capture_Page.dart';
import 'package:ice_cream/views/dashbord_screen.dart';
import 'package:ice_cream/views/login_page.dart';
import 'package:ice_cream/views/new_dashbord_screen.dart';
import 'package:ice_cream/views/order_list_screen.dart';
import 'package:ice_cream/views/request_list_screen.dart';
import 'package:ice_cream/views/sell_page.dart';
import 'package:ice_cream/views/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'services/location_service.dart';

/*void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  // Initialize shared preferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Register services
  Get.put(sharedPreferences);
  Get.put(ApiManager());
  await Get.putAsync(() => AuthService().init());

  try {
    await LocationService.requestLocationPermission();
  } catch (e) {
    log("❌ Location permission required: $e");
    return; // Stop app from running if permission is denied
  }

  const frequency = Duration(seconds: 5);

  Workmanager().registerPeriodicTask(
    "uniqueTaskName",
    "fetchLocationTask",
    // frequency: const Duration(minutes: 15),
    frequency: frequency,
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    // existingWorkPolicy: ExistingWorkPolicy.keep,
    existingWorkPolicy: ExistingWorkPolicy.replace,
    initialDelay: const Duration(seconds: 3),
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: Duration(minutes: 5),
  ).then((value) {
    log("✅ Periodic task registered to run every ${frequency.inSeconds} seconds");
    log("✅ WorkManager task registered");
  });

  runApp(const MyApp());
}*/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize shared preferences
    final sharedPreferences = await SharedPreferences.getInstance();

    // Register services
    Get.put(sharedPreferences);
    Get.put(ApiManager());
    await Get.putAsync(() => AuthService().init());

    // Initialize Workmanager
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );

    // Request location permission (handle failure gracefully)
    try {
      await LocationService.requestLocationPermission();
    } catch (e) {
      log("⚠️ Location permission not granted: $e");
      // Continue running the app even if permission is denied
    }

    const frequency = Duration(seconds: 5);

    Workmanager().registerPeriodicTask(
      "uniqueTaskName",
      "fetchLocationTask",
      frequency: frequency,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      initialDelay: const Duration(seconds: 3),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: Duration(minutes: 5),
    ).then((value) {
      log("✅ Periodic task registered");
    }).catchError((e) {
      log("❌ Failed to register periodic task: $e");
    });

    runApp(const MyApp());
  } catch (e, stackTrace) {
    log("🔥 Fatal error during initialization: $e");
    log("Stack trace: $stackTrace");
    // You might want to show an error screen here
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: Text('Initialization failed: ${e.toString()}')),
      ),
    ));
  }
}

/*Future<void> initializeWorkManager() async {
  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );
    log('✅ WorkManager initialized successfully');
  } catch (e, stack) {
    log('❌ WorkManager initialization failed: $e');
    log('Stack trace: $stack');
    // Consider retrying or showing user feedback
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) {
      final timestamp = DateTime.now().toIso8601String();
      log('[$timestamp] $message');
    }
  };

  if (Platform.isAndroid) {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );

    // Verify the plugin is registered
    const channel = MethodChannel('be.tramckrijte.workmanager/background_channel_work_manager');
    try {
      await channel.invokeMethod('backgroundChannelInitialized');
    } catch (e) {
      log('Plugin verification failed - will retry in 3 seconds: $e');
      await Future.delayed(Duration(seconds: 3));
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: true,
      );
    }
  }
  // Initialize Workmanager
  await initializeWorkManager();

  // Initialize dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  Get.put(sharedPreferences);
  Get.put(ApiManager());
  await Get.putAsync(() => AuthService().init());

  // Request location permissions
  try {
    await LocationService.requestLocationPermission();
    log('✅ Location permissions granted');
  } catch (e) {
    log('❌ Location permission error: $e');
    return;
  }

  // Register periodic task
  const testFrequency = Duration(minutes: 7); // Testing with 5 seconds
  const initialDelay = Duration(seconds: 3);

  log('⏳ Registering periodic task with ${testFrequency.inSeconds}s interval...');

  await Workmanager().registerPeriodicTask(
    "locationTrackerTask",
    "fetchLocationTask",
    frequency: testFrequency,
    initialDelay: initialDelay,
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: false, // Disabled for testing
      requiresStorageNotLow: false, // Disabled for testing
    ),
    existingWorkPolicy: ExistingWorkPolicy.replace,
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: Duration(seconds: 10), // Shorter backoff for testing
  ).then((_) {
    log('✅ Periodic task registered successfully');
    log('   - Frequency: every ${testFrequency.inSeconds} seconds');
    log('   - Initial delay: ${initialDelay.inSeconds} seconds');
  }).catchError((error) {
    log('❌ Failed to register periodic task: $error');
  });

  runApp(const MyApp());
}*/


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
       // GetPage(name: '/dashboard', page: () => DashboardPage()),
        GetPage(name: '/dashboard', page: () => NewDashbordScreen()),
        GetPage(name: '/sell', page: () => SellPage()),
        GetPage(
          name: '/selfie',
          page: () => SelfieCapturePage(),
        ),
        GetPage(
          name: '/orders',
          page: () => OrderListScreen(),
        ),
        GetPage(
          name: '/requests',
          page: () => RequestListScreen(),
        ),
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

    // Skip if we're already on these routes
    if (currentRoute == '/' || currentRoute == '/login') return;

    if (!isAuthenticated) {
      // Navigate to login if not authenticated
      Get.offAllNamed('/login');
    } else if (currentRoute == '/login') {
      // If authenticated but on login page, go to dashboard
      Get.offAllNamed('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
