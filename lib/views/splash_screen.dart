import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final AuthService _authService = Get.find<AuthService>();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // First check if token exists and is valid
      final isValid = await _authService.validateToken();

      // Then check if user is logged in (includes token validation)
      final isLoggedIn = await _authService.isLoggedIn();

      // Wait for minimum splash duration (2 seconds)
      await Future.delayed(Duration(seconds: 2));

      // Navigate based on auth status
      Get.offAllNamed(isLoggedIn && isValid ? '/dashboard' : '/login');
      // Get.offAllNamed('/orders');
      //Get.offAllNamed('/dashboard');
    } catch (e) {
      // If any error occurs, go to login screen
      Get.offAllNamed('/dashboard');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.icecream,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                'Ice Cream Sales',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Sweetening your day, one scoop at a time!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}