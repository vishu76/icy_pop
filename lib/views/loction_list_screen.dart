import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart'; // Add this package for geocoding
import 'package:ice_cream/services/api_manager.dart';
import 'package:ice_cream/services/auth_service.dart';
import 'package:ice_cream/services/database.dart';
import 'package:ice_cream/views/login_page.dart';

class LocationListScreen extends StatefulWidget {
  @override
  _LocationListScreenState createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  List<Map<String, dynamic>> _locationData = [];
  final AuthService _authService = Get.find<AuthService>();
  final ApiManager _apiManager = Get.find<ApiManager>();
  Map<int, String> _locationNames = {}; // Store location names by index

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

    // Get location names for all coordinates
    _getLocationNames();
  }

  Future<void> _getLocationNames() async {
    for (int i = 0; i < _locationData.length; i++) {
      try {
        double lat = _locationData[i]['latitude'];
        double lon = _locationData[i]['longitude'];

        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);

        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks.first;
          String locationName = _buildLocationName(placemark);

          setState(() {
            _locationNames[i] = locationName;
          });
        } else {
          setState(() {
            _locationNames[i] = 'Unknown Location';
          });
        }
      } catch (e) {
        print('Error getting location name for index $i: $e');
        setState(() {
          _locationNames[i] = 'Unable to fetch location';
        });
      }
    }
  }

  String _buildLocationName(Placemark placemark) {
    List<String> addressParts = [];

    if (placemark.street != null && placemark.street!.isNotEmpty) {
      addressParts.add(placemark.street!);
    }
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      addressParts.add(placemark.subLocality!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      addressParts.add(placemark.locality!);
    }
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      addressParts.add(placemark.administrativeArea!);
    }
    if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
      addressParts.add(placemark.postalCode!);
    }

    return addressParts.isNotEmpty ? addressParts.join(', ') : 'Unknown Location';
  }

  String _formatTimestamp(String timestamp) {
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  Future<void> _logout() async {
    try {
      await _apiManager.clearToken();
      await _authService.logout();
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Stored Locations',
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple[400],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: _locationData.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No locations stored',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _locationData.length,
        itemBuilder: (context, index) {
          double lat = _locationData[index]['latitude'];
          double lon = _locationData[index]['longitude'];
          String timestamp = _locationData[index]['timestamp'] ?? "";
          String locationName = _locationNames[index] ?? 'Fetching location...';

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            //elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on,
                  color: Colors.purple[400],
                  size: 20,
                ),
              ),
            /*  title: Text(
                locationName,
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),*/
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(
                    'Coordinates: ${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Time: ${_formatTimestamp(timestamp)}',
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            /*  trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
              onTap: () {
                // You can add onTap functionality here
                // For example, show location on map or detailed view
              },*/
            ),
          );
        },
      ),
    );
  }
}