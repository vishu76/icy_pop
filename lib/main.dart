import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ice_cream/services/LocationMonitor.dart';
import 'package:ice_cream/services/api_manager.dart';
import 'package:ice_cream/services/auth_service.dart';
import 'package:ice_cream/services/background_callback.dart';
import 'package:ice_cream/views/Selfie_Capture_Page.dart';

import 'package:ice_cream/views/login_page.dart';
import 'package:ice_cream/views/new_dashbord_screen.dart';
import 'package:ice_cream/views/order_list_screen.dart';
import 'package:ice_cream/views/request_list_screen.dart';
import 'package:ice_cream/views/sell_page.dart';
import 'package:ice_cream/views/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';


// Updated LocationMonitor class to check BOTH permission and service


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


    // Start location monitoring (checks both permission and service)
    print('Starting location monitoring...');
    LocationMonitor().startMonitoring();

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
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: Text('Initialization failed: ${e.toString()}')),
      ),
    ));
  }
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