import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ice_cream/utils/color.dart';
import 'package:pinput/pinput.dart';
import '../controllers/login_controller.dart';
import 'Selfie_Capture_Page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final LoginController _loginController = Get.put(LoginController());
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  File? _selfieImage;
  String _lastSentMobile = ''; // Track the last mobile number OTP was sent to

  // For OTP auto-fill
  final FocusNode _otpFocusNode = FocusNode();
  bool _isOtpSent = false;

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

    // Listen to OTP changes for auto-submit
    _loginController.otp.listen((otp) {
      if (otp.length == 6 && _isOtpSent) {
        // Auto-submit after 500ms
        Future.delayed(Duration(milliseconds: 500), () {
          _submitLogin();
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mobileController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _takeSelfie() async {
    final result = await Get.to<File?>(() => SelfieCapturePage());
    if (result != null) {
      setState(() {
        _selfieImage = result;
      });
    }
  }

  void _submitLogin() {
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

      if (!_isOtpSent) {
        Get.snackbar(
          'Error',
          'Please send OTP first',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (_loginController.otp.value.length != 6) {
        Get.snackbar(
          'Error',
          'Please enter 6-digit OTP',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final imageBytes = _selfieImage!.readAsBytesSync();
      final base64Image = base64Encode(imageBytes);
      _loginController.login(
        _mobileController.text,
        _loginController.otp.value,
        base64Image,
      );
    }
  }

  void _sendOtp() {
    if (_mobileController.text.isEmpty ||
        _mobileController.text.length != 10 ||
        !GetUtils.isPhoneNumber(_mobileController.text)) {
      Get.snackbar(
        'Error',
        'Please enter a valid 10-digit mobile number',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    _loginController.sendOtp();
    setState(() {
      _isOtpSent = true;
      _lastSentMobile = _mobileController.text; // Store the mobile number
    });
    _otpFocusNode.requestFocus();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade200 ,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              elevation: 0,
              color: Colors.white,
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
                        ),
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
                          elevation: 0,
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

                      // Mobile Number Field with Send OTP Button at right corner
                      // Mobile Number Field
                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: InputDecoration(
                          hintText: 'Enter mobile number',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.phone, color: primaryColor),
                          suffixIcon: Obx(() {
                            bool isEnabled = _loginController.mobileNumber.value.length == 10 &&
                                !_loginController.isLoading.value &&
                                _loginController.mobileError.value.isEmpty;

                            // Check if timer is active - disable if countdown > 0
                            bool isTimerActive = _isOtpSent && _loginController.countdown.value > 0;
                            bool isTappable = isEnabled && !isTimerActive;

                            // Show loading indicator when sending
                            if (_loginController.isLoading.value) {
                              return Padding(
                                padding: EdgeInsets.only(right: 16),
                                child: SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1,
                                    color: primaryColor,
                                  ),
                                ),
                              );
                            }

                            return Container(
                              padding: EdgeInsets.only(right: 16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: isTappable ? _sendOtp : null,
                                    child: Text(
                                      // If mobile number changed, show "Send" instead of timer/resend
                                      (_isOtpSent && _loginController.countdown.value > 0 &&
                                          _loginController.mobileNumber.value == _mobileController.text)
                                          ? '${_loginController.countdown.value}s'
                                          : (_isOtpSent && _loginController.mobileNumber.value == _mobileController.text
                                          ? 'Resend'
                                          : 'Send'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isTappable ? primaryColor : Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.pink, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          focusColor: Colors.pink,
                        ),
                        cursorColor: Colors.pink,
                        onChanged: (value) {
                          _loginController.validateMobile(value);

                          // Reset OTP state if mobile number changes
                          if (_isOtpSent && _lastSentMobile != value) {
                            setState(() {
                              _isOtpSent = false;
                            });
                            // Also clear the OTP field
                            _loginController.clearOtp();
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Mobile number cannot be empty';
                          }
                          if (!GetUtils.isPhoneNumber(value)) {
                            return 'Enter a valid mobile number';
                          }
                          if (value.length != 10) {
                            return 'Mobile number must be 10 digits';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 20),

                      // OTP Input Field
                      Text(
                        'Enter 6-Digit OTP',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      SizedBox(height: 12),

                      _buildOtpInput(),

                      SizedBox(height: 8),
                      Obx(() => Text(
                        _loginController.otpError.value,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      )),

                      SizedBox(height: 25),

                      // Login Button
                      ElevatedButton(
                        onPressed: _submitLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Obx(() {
                          return _loginController.isLoading.value
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            'Login',
                            style: GoogleFonts.fredoka(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
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

  Widget _buildOtpInput() {
    final defaultPinTheme = PinTheme(
      width: 45,
      height: 45,
      textStyle: GoogleFonts.fredoka(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: primaryColor!, width: 2),
      borderRadius: BorderRadius.circular(10),
    );

    final submittedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: primaryColor!, width: 2),
      borderRadius: BorderRadius.circular(10),
    );

    return Pinput(
      length: 6,
      focusNode: _otpFocusNode,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      submittedPinTheme: submittedPinTheme,
      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
      showCursor: true,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      onChanged: (value) {
        _loginController.updateOtp(value);
      },
      onCompleted: (value) {
        _loginController.updateOtp(value);
        if (_selfieImage != null && _isOtpSent) {
          _submitLogin();
        }
      },
    );
  }
}