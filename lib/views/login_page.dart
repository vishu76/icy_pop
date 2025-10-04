import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ice_cream/utils/color.dart';
import '../controllers/login_controller.dart';
import 'Selfie_Capture_Page.dart'; // Import the selfie capture page

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final LoginController _loginController = Get.put(LoginController());
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  File? _selfieImage; // Store the captured selfie

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_animationController);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Function to open selfie capture page and get the result
  Future<void> _takeSelfie() async {
    final result = await Get.to<File?>(() => SelfieCapturePage());

    if (result != null) {
      setState(() {
        _selfieImage = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Icon(
                                Icons.icecream,
                                size: 80,
                                color: primaryColor,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      Text(
                          'Login',
                          style: GoogleFonts.fredoka(
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                          )
                      ),
                      SizedBox(height: 20),

                      // Selfie capture section
                      Text(
                        'Verify Your Identity',
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          color: primaryColor,
                        ),
                      ),
                      SizedBox(height: 10),

                      if (_selfieImage != null)
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: primaryColor!, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(48),
                            child: Image.file(
                              _selfieImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.account_circle,
                          size: 80,
                          color: Colors.grey,
                        ),

                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _takeSelfie,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          _selfieImage != null ? 'Retake Selfie' : 'Take Selfie',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: GoogleFonts.fredoka(color: primaryColor),
                          prefixIcon: Icon(Icons.email, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email cannot be empty';
                          }
                          if (!GetUtils.isEmail(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: GoogleFonts.fredoka(color: primaryColor),
                          prefixIcon: Icon(Icons.lock, color: primaryColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: primaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password cannot be empty';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            if (_selfieImage == null) {
                              Get.snackbar(
                                'Error',
                                'Please take a selfie first',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                              return;
                            }
                            final imageBytes = _selfieImage!.readAsBytesSync();
                            final base64Image = base64Encode(imageBytes);
                            _loginController.login(
                              _emailController.text,
                              _passwordController.text,
                              base64Image, // Pass the selfie image to the controller
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: Obx(() {
                          return _loginController.isLoading.value
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                              'Login',
                              style: GoogleFonts.fredoka(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              )
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}