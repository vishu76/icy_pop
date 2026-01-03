import 'dart:convert';
import 'dart:developer';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ice_cream/utils/color.dart';
import 'package:ice_cream/views/login_page.dart';
import 'package:intl/intl.dart';
import '../controllers/dashbord_controller.dart';
import '../services/api_manager.dart';
import '../services/api_services.dart';
import '../services/auth_service.dart';
import '../utils/token_expiry_dialog.dart';
import 'loction_list_screen.dart';

class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardController _dashboardController = Get.put(DashboardController());
  final ApiManager _apiManager = Get.find<ApiManager>();
  final AuthService _authService = Get.find<AuthService>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void initState() {
    super.initState();
    _printAuthToken();
    fetchOrderDetail();
    _dashboardController.startLocationTracking();
  }

  Future<void> _printAuthToken() async {
    try {
      final token = await _apiManager.getToken();
      print("Current Auth Token: $token");

      if (token != null) {
        debugPrint("Dashboard Token: $token");
        Get.snackbar(
          'Debug Info',
          'Token: ${token.substring(0, 10)}...',
          duration: Duration(seconds: 3),
        );
      }
    } catch (e) {
      debugPrint("Error retrieving token: $e");
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
  Future<void> _selectDateRange(BuildContext context) async {
    final List<DateTime?>? results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
        selectedDayHighlightColor: Colors.pink[400],
        weekdayLabelTextStyle: GoogleFonts.fredoka(),
        dayTextStyle: GoogleFonts.fredoka(),
        controlsTextStyle: GoogleFonts.fredoka(fontWeight: FontWeight.w500),
        centerAlignModePicker: true,
        customModePickerIcon: const SizedBox(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2025, 12, 31),
        gapBetweenCalendarAndButtons: 0,
        okButton: Container(
          decoration: BoxDecoration(
            color: Colors.pink[400],
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Apply',
            style: GoogleFonts.fredoka(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        cancelButton: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Cancel',
            style: GoogleFonts.fredoka(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(15),
      value: [
        _dashboardController.fromDate.value,
        _dashboardController.toDate.value,
      ],
    );

    if (results != null && results.length == 2 && results[0] != null && results[1] != null) {
      _dashboardController.fromDate.value = results[0]!;
      _dashboardController.toDate.value = results[1]!;
      await fetchOrderDetail(); // Re-fetch with new range
    }
  }
  Future<void> fetchOrderDetail() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final token = await _apiManager.getToken();

      final DateFormat apiFormat = DateFormat('yyyy-MM-dd');
      final fromDate = apiFormat.format(_dashboardController.fromDate.value);
      final toDate = apiFormat.format(_dashboardController.toDate.value);

      await APIManager().apiRequest(
        Get.context!,
        API.dashboard,
        params: {
          "from_date": fromDate,
          "to_date": toDate,
        },
        onSuccess: (response) {
          final responseData = json.decode(response);
          //print('Dashboard Response: $responseData');

          if (responseData['status'] == 'Failed' &&
              responseData['Msg']?.contains('Token is expired') == true) {
            showTokenExpiryDialog(Get.context!);
            return;
          }

          if (responseData['status'] == 'success') {
            final List data = responseData['data'];
            List<int> parsedSales = List.generate(12, (_) => 0);
            _dashboardController.setRawProductSales(List<Map<String, dynamic>>.from(data));

            _dashboardController.addSalesForDate(_dashboardController.selectedDate.value, parsedSales);
          } else {
            // errorMessage.value = responseData['msg'] ?? 'Failed to fetch data';
            final errorMsg = responseData['response']?['Msg'] ??
                responseData['msg'] ??
                'No sales data found';
            errorMessage.value = errorMsg;
            log("API error: ${errorMessage.value}");
          }
        },
        onFailure: (error) {
          errorMessage.value = error.toString();
        },
        token: token,
      );
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: Text('IcyPopps',
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.pink[400],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: whiteColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Check your Ice Cream sales',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.pink[800],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Obx(() {
            final from = DateFormat('dd MMM yyyy').format(_dashboardController.fromDate.value);
            final to = DateFormat('dd MMM yyyy').format(_dashboardController.toDate.value);

            return Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.pink[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Date Range:\n$from to $to',
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.pink[800],
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _selectDateRange(context),
                    icon: Icon(Icons.calendar_today, color: Colors.pink[800]),
                    label: Text('Change',
                      style: GoogleFonts.fredoka(color: Colors.pink[800], fontWeight: FontWeight.w500, fontSize: 15),),
                  ),
                ],
              ),
            );
          }),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ElevatedButton.icon(
              onPressed: () {
                Get.toNamed('/orders');
              },
              icon: Icon(Icons.list_alt, color: Colors.white,),
              label: Text('View Requests',
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[300],
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ElevatedButton.icon(
              onPressed: () {
                Get.toNamed('/requests');
              },
              icon: Icon(Icons.request_page, color: Colors.white),
              label: Text('View Return',
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[300], // Different color to distinguish
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          Expanded(
            child: Obx(() {
              if (isLoading.value) {
                return Center(child: CircularProgressIndicator(color: Colors.pink[300]));
              }

              if (_dashboardController.rawProductSales.isEmpty) {
                return Center(
                  child: Text(
                    errorMessage.value.isNotEmpty
                        ? errorMessage.value
                        : 'No sales data available.',
                    style: GoogleFonts.fredoka(
                        fontSize: 16,
                        color: Colors.grey[700]
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: _dashboardController.rawProductSales.length,
                separatorBuilder: (context, index) => SizedBox(height: 5),
                itemBuilder: (context, index) {
                  final item = _dashboardController.rawProductSales[index];
                  final name = item['product_name'] ?? 'N/A';
                  final sold = item['total_sold_quantity'] ?? 0;

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      leading: CircleAvatar(
                        backgroundColor: Colors.pink[300],
                        child: Icon(Icons.icecream, color: Colors.white),
                      ),
                      title: Text(
                        name,
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.w600
                        ),
                      ),
                      subtitle: Text(
                        'Sold: $sold',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          color: Colors.grey[700]
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.pink[300],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.pink[300]),
                ),
                SizedBox(height: 10),
                Text(
                  'User Profile',
                  style: GoogleFonts.fredoka(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'user@example.com',
                  style: GoogleFonts.fredoka(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: Colors.pink[300]),
            title: Text('Dashboard',
              style: GoogleFonts.fredoka(),),
            onTap: () {
              Get.back();
            },
          ),


          ListTile(
            leading: Icon(Icons.location_on, color: Colors.pink[300]),
            title: Text('Locations',
              style: GoogleFonts.fredoka(),),
            onTap: () {
              Get.back();
              Get.to(() => LocationListScreen());
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.pink[300]),
            title: Text('Logout',
              style: GoogleFonts.fredoka(),),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}