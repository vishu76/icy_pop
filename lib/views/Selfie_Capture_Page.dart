import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ice_cream/utils/color.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

class SelfieCapturePage extends StatefulWidget {
  const SelfieCapturePage({Key? key}) : super(key: key);

  @override
  State<SelfieCapturePage> createState() => _SelfieCapturePageState();
}

class _SelfieCapturePageState extends State<SelfieCapturePage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;
  bool _hasCameraError = false;
  XFile? _capturedImage;
  bool _isFrontCamera = true;
  File? _processedImageFile;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _hasCameraError = true;
        });
        return;
      }

      // Find front camera
      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
      );

      _initializeControllerFuture = _controller!.initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isCameraInitialized = true;
          _isFrontCamera = _controller!.description.lensDirection == CameraLensDirection.front;
        });
      }).catchError((error) {
        if (!mounted) return;
        setState(() {
          _hasCameraError = true;
        });
      });
    } catch (e) {
      setState(() {
        _hasCameraError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<File> _flipImageHorizontally(File originalImage) async {
    final originalBytes = await originalImage.readAsBytes();
    final originalImageDecoded = img.decodeImage(originalBytes);

    if (originalImageDecoded == null) {
      return originalImage;
    }

    // Flip the image horizontally
    final flippedImage = img.flipHorizontal(originalImageDecoded);

    // Save the flipped image to a temporary file
    final flippedBytes = img.encodePng(flippedImage);
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/flipped_selfie_${DateTime.now().millisecondsSinceEpoch}.png');
    await tempFile.writeAsBytes(flippedBytes);

    return tempFile;
  }

  Future<void> _takeSelfie() async {
    if (_controller == null || !_isCameraInitialized) return;

    try {
      final image = await _controller!.takePicture();

      // For front camera, flip the image to match the preview
      if (_isFrontCamera) {
        final flippedImageFile = await _flipImageHorizontally(File(image.path));
        setState(() {
          _capturedImage = XFile(flippedImageFile.path);
          _processedImageFile = flippedImageFile;
        });
      } else {
        setState(() {
          _capturedImage = image;
          _processedImageFile = File(image.path);
        });
      }
    } catch (e) {
      print("Error taking picture: $e");
      Get.snackbar(
        'Error',
        'Failed to take picture',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _submitSelfie() {
    if (_capturedImage != null && _processedImageFile != null) {
      // Here you would typically upload the processed image to your server
      // For now, we'll just navigate to the dashboard
      Get.back(result: _processedImageFile);
    } else {
      Get.snackbar(
        'Error',
        'Please take a selfie first',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _retakeSelfie() {
    setState(() {
      _capturedImage = null;
      _processedImageFile = null;
    });
  }

  void _retryCamera() {
    setState(() {
      _hasCameraError = false;
      _isCameraInitialized = false;
      _capturedImage = null;
      _processedImageFile = null;
    });
    _initializeCamera();
  }

  // Widget to show camera preview with correct orientation
  Widget _cameraPreviewWidget() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: primaryColor,
            ),
            SizedBox(height: 10),
            Text(
              'Loading camera...',
              style: GoogleFonts.fredoka(),
            ),
          ],
        ),
      );
    }

    // For front camera, apply horizontal transformation to fix mirror effect
    if (_isFrontCamera) {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(3.14159265359), // 180 degrees in radians
        child: CameraPreview(_controller!),
      );
    } else {
      return CameraPreview(_controller!);
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 80,
                      color: primaryColor,
                    ),
                    SizedBox(height: 20),
                    Text(
                      _capturedImage != null ? 'Your Selfie' : 'Take a Selfie',
                      style: GoogleFonts.fredoka(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(height: 20),

                    if (_hasCameraError)
                      Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Camera not available',
                            style: GoogleFonts.fredoka(
                              fontSize: 18,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _retryCamera,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Retry',
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        height: 300,
                        width: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor!, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _capturedImage != null
                              ? Image.file(
                            File(_capturedImage!.path),
                            fit: BoxFit.fill,
                          )
                              : _cameraPreviewWidget(),
                        ),
                      ),

                    SizedBox(height: 20),
                    if (!_hasCameraError)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (_capturedImage == null)
                            ElevatedButton(
                              onPressed: _isCameraInitialized ? _takeSelfie : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                
                              ),
                              child: Text(
                                'Take Selfie',
                                style: GoogleFonts.fredoka(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: _retakeSelfie,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                
                              ),
                              child: Text(
                                'Retake',
                                style: GoogleFonts.fredoka(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ElevatedButton(
                            onPressed: _capturedImage != null ? _submitSelfie : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _capturedImage != null ? Colors.green : Colors.grey,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              
                            ),
                            child: Text(
                              'Submit',
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}