import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ice_cream/services/api_manager.dart'; // Import your ApiManager
import 'package:ice_cream/services/auth_service.dart'; // Import your AuthService
import 'package:ice_cream/services/database.dart';
import 'package:ice_cream/views/login_page.dart'; // Import your login page

class LocationListScreen extends StatefulWidget {
  @override
  _LocationListScreenState createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  List<Map<String, dynamic>> _locationData = [];
  final AuthService _authService = Get.find<AuthService>(); // Get AuthService instance
  final ApiManager _apiManager = Get.find<ApiManager>(); // Get ApiManager instance

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  void _fetchLocations() async {
    List<Map<String, dynamic>> locations =
    await DatabaseHelper.instance.getLocation();
    setState(() {
      _locationData = locations;
    });
  }

  Future<void> _logout() async {
    try {
      // Clear the token from ApiManager
      await _apiManager.clearToken();

      // Update authentication state
      await _authService.logout();

      // Navigate to login screen and clear all previous routes
      Get.offAll(() => LoginPage());
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to logout: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stored Locations'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _locationData.length,
        itemBuilder: (context, index) {
          double lat = _locationData[index]['latitude'];
          double lon = _locationData[index]['longitude'];
          String timestamp = _locationData[index]['timestamp'] ?? "";
          return ListTile(
            title: Text('Lat: $lat, Lon: $lon'),
            subtitle: Text('Timestamp: $timestamp'),
          );
        },
      ),
    );
  }
}