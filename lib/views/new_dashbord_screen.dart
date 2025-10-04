import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ice_cream/utils/color.dart';
import 'package:ice_cream/views/login_page.dart';
import 'package:intl/intl.dart';
import '../controllers/dashboard_TodaysCartController.dart';
import '../controllers/dashbord_controller.dart';
import '../models/CartDataModel.dart';
import '../services/api_manager.dart';
import '../services/api_services.dart';
import '../services/auth_service.dart';
import '../utils/token_expiry_dialog.dart';
import 'loction_list_screen.dart';

class NewDashbordScreen extends StatefulWidget {
  @override
  State<NewDashbordScreen> createState() => _NewDashbordScreenState();
}

class _NewDashbordScreenState extends State<NewDashbordScreen> {
  // Use Get.find with fallback to Get.put for safety
  late final DashboardController _dashboardController;
  late final TodaysCartController _cartController;
  final ApiManager _apiManager = Get.find<ApiManager>();
  final AuthService _authService = Get.find<AuthService>();

  final List<TextEditingController> _acceptQtyControllers = [];
  final List<TextEditingController> _refillQtyControllers = [];
  final List<TextEditingController> _returnQtyControllers = [];

  // State variables to control the flow
  final RxBool _isCartAccepted = false.obs;
  final RxBool _isRefillCompleted = false.obs;

  // Timer for auto-refresh
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();

    // Initialize controllers safely
    _initializeControllers();

    _printAuthToken();
    fetchOrderDetail();
    _dashboardController.startLocationTracking();

    // Start auto-refresh timer
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    // Cancel existing timer if any
    _autoRefreshTimer?.cancel();

    // Start new timer that triggers every 1 minute
    _autoRefreshTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      print('[AUTO-REFRESH] Fetching cart details...');
      fetchOrderDetail();
    });
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }


  void _initializeControllers() {
    // Initialize DashboardController
    try {
      _dashboardController = Get.find<DashboardController>();
    } catch (e) {
      _dashboardController = Get.put(DashboardController());
    }

    // Initialize TodaysCartController
    try {
      _cartController = Get.find<TodaysCartController>();
    } catch (e) {
      _cartController = Get.put(TodaysCartController());
    }

    // Initialize text controllers when cart data is available
    ever(_cartController.cartData, (cart) {
      if (cart != null) {
        _initializeTextControllers();
        _checkOrderStatus();
      }
    });
  }

  void _checkOrderStatus() {
    final cartData = _cartController.cartData.value;
    if (cartData != null) {
      final orderStatus = cartData.data.orderproductstatus;
      print("Order Status from API: $orderStatus");

      // Set workflow state based on order status
      if (orderStatus == "1") {
        _isCartAccepted.value = false;
        _isRefillCompleted.value = false;
      } else if (orderStatus == "3") {
        _isCartAccepted.value = true;
        _isRefillCompleted.value = false;
      } else if (orderStatus == "5") {
        _isCartAccepted.value = true;
        _isRefillCompleted.value = true;
      }
    }
  }

  bool get hasRefillData {
    return _cartController.cartData.value?.data.refilledProductData.isNotEmpty ?? false;
  }

  // Update the products list getter for each section
  List<dynamic> get acceptProducts {
    return _cartController.cartData.value?.data.stockProductData ?? [];
  }

  List<RefillProduct> get refillProducts {
    return _cartController.cartData.value?.data.refilledProductData ?? [];
  }

  List<ReturnProduct> get returnProducts {
    return _cartController.cartData.value?.data.returnlist ?? [];
  }

  void _initializeTextControllers() {
    // Clear existing controllers
    for (var controller in _acceptQtyControllers) {
      controller.dispose();
    }
    for (var controller in _refillQtyControllers) {
      controller.dispose();
    }
    for (var controller in _returnQtyControllers) {
      controller.dispose();
    }

    _acceptQtyControllers.clear();
    _refillQtyControllers.clear();
    _returnQtyControllers.clear();

    // Initialize controllers for products from API
    final acceptProducts = _cartController.stockProducts;
    final refillProducts = _cartController.refillProducts;
    final returnProducts = _cartController.returnProducts;

    print('[DEBUG] Initializing controllers - Accept: ${acceptProducts.length}, Refill: ${refillProducts.length}, Return: ${returnProducts.length}');

    // Pre-fill accept controllers with product quantities
    for (int i = 0; i < acceptProducts.length; i++) {
      final product = acceptProducts[i];
      _acceptQtyControllers.add(TextEditingController(
        text: product.quantity.toString(), // Pre-fill with product quantity
      ));
    }

    // Pre-fill refill controllers with product quantities
    for (int i = 0; i < refillProducts.length; i++) {
      final product = refillProducts[i];
      _refillQtyControllers.add(TextEditingController(
        text: product.quantity.toString(), // Pre-fill with product quantity
      ));
    }

    // Pre-fill return controllers with product quantities
    for (int i = 0; i < returnProducts.length; i++) {
      final product = returnProducts[i];
      _returnQtyControllers.add(TextEditingController(
        text: product.quantity.toString(), // Pre-fill with product quantity
      ));
    }
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    for (var controller in _acceptQtyControllers) {
      controller.dispose();
    }
    for (var controller in _refillQtyControllers) {
      controller.dispose();
    }
    for (var controller in _returnQtyControllers) {
      controller.dispose();
    }
    super.dispose();
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

  Future<void> fetchOrderDetail() async {
    try {
      await _cartController.fetchTodaysCartDetail();
      // Re-initialize text controllers when data is refreshed
      if (_cartController.cartData.value != null) {
        _initializeTextControllers();
        _checkOrderStatus();
      }
    } catch (e) {
      print('Error in fetchOrderDetail: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
      body: Stack(
        children: [
          CustomRefreshIndicator(
            onRefresh: () async {
              print('[PULL-REFRESH] Manual refresh triggered');
              await fetchOrderDetail();
            },
            builder: (BuildContext context, Widget child, IndicatorController controller) {
              return Stack(
                children: [
                  // Your main content
                  child,

                  // Refresh indicator that responds to drag
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedBuilder(
                      animation: controller,
                      builder: (context, child) {
                        // Calculate opacity and height based on controller value
                        final double opacity = controller.isLoading ? 1.0 : controller.value.clamp(0.0, 1.0);
                        final double height = controller.isLoading ? 60.0 : 40.0 * controller.value;

                        return Opacity(
                          opacity: opacity,
                          child: Container(
                            height: height,
                           // color: Colors.pink[50],
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Animated spinner
                                  controller.isLoading
                                      ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.pink[400]!),
                                    ),
                                  )
                                      : Transform.rotate(
                                    angle: controller.value * 2 * 3.14159, // Rotate based on drag
                                    child: Icon(
                                      Icons.refresh,
                                      color: Colors.pink[400],
                                      size: 20,
                                    ),
                                  ),
                             /*     SizedBox(width: 12),
                                  Text(
                                    controller.isLoading ? 'Refreshing...' : 'Pull to refresh',
                                    style: GoogleFonts.fredoka(
                                      color: Colors.pink[600],
                                      fontSize: 14,
                                    ),
                                  ),*/
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Today's Cart Details",
                      style: GoogleFonts.fredoka(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.pink[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
            
                  // Quantity Summary Row
                  _buildQuantitySummary(),
            
                  const SizedBox(height: 14),
            
                  // Cart Details Card
                  _buildCartDetails(),
            
                  const SizedBox(height: 14),
            
                  // Main Content Section
                  Obx(() {
                    // Show loading or error states
                    if (_cartController.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
            
                    if (_cartController.errorMessage.value.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _cartController.errorMessage.value,
                          style: GoogleFonts.fredoka(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
            
                    // Get order status from API
                    final orderStatus = _cartController.cartData.value?.data.orderproductstatus;
                    print("Order Status for UI: $orderStatus");
            
                    // Check if cart is returned (status 0)
                    if (orderStatus == "0") {
                      return _buildReturnedCartSection();
                    }
            
                    // Show content based on order status
                    if (orderStatus == "1") {
                      return _buildAcceptSection();
                    } else if (orderStatus == "3") {
                      return _buildRefillSection();
                    } else if (orderStatus == "5") {
                      return _buildReturnSection();
                    } else {
                      // Fallback: use the original workflow logic
                      if (!_isCartAccepted.value) {
                        return _buildAcceptSection();
                      } else if (!_isRefillCompleted.value && hasRefillData) {
                        return _buildRefillSection();
                      } else {
                        return _buildReturnSection();
                      }
                    }
                  }),
            
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Floating Button - Only show if order status is not 0
          Obx(() {
            final orderStatus = _cartController.cartData.value?.data.orderproductstatus;
            if (orderStatus == "0") {
              return SizedBox(); // Hide button for returned cart
            }

            return Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildFloatingButton(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFloatingButton() {
    return Obx(() {
      // Get order status from API
      final orderStatus = _cartController.cartData.value?.data.orderproductstatus;
      print("Order Status for Button: $orderStatus");

      String buttonText;
      Color buttonColor;

      // Set button based on order status
      if (orderStatus == "1") {
        buttonText = 'Accept Cart';
        buttonColor = Colors.pink[400]!;
      } else if (orderStatus == "3") {
        buttonText = 'Refill Cart';
        buttonColor = Colors.blue[400]!;
      } else if (orderStatus == "5") {
        buttonText = 'Return Cart';
        buttonColor = Colors.orange[400]!;
      } else {
        // Fallback: use the original workflow logic
        if (!_isCartAccepted.value) {
          buttonText = 'Accept Cart';
          buttonColor = Colors.pink[400]!;
        } else if (!_isRefillCompleted.value && hasRefillData) {
          buttonText = 'Refill Cart';
          buttonColor = Colors.blue[400]!;
        } else {
          buttonText = 'Return Cart';
          buttonColor = Colors.orange[400]!;
        }
      }

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _cartController.isLoading.value ? null : () {
            if (orderStatus == "1") {
              _handleAcceptCart();
            } else if (orderStatus == "3") {
              _handleRefillCart();
            } else if (orderStatus == "5") {
              _handleReturnCart();
            } else {
              // Fallback: use the original workflow logic
              if (!_isCartAccepted.value) {
                _handleAcceptCart();
              } else if (!_isRefillCompleted.value && hasRefillData) {
                _handleRefillCart();
              } else {
                _handleReturnCart();
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: buttonColor.withOpacity(0.3),
          ),
          child: Text(
            buttonText,
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildReturnedCartSection() {
    return Column(
      children: [
        // Message that cart is returned
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Today's cart is returned",
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),

        // Blurred product list based on the last status before return
        _buildBlurredProductList(),
      ],
    );
  }

  Widget _buildBlurredProductList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                'Cart Products (Returned)',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 300,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Stack(
            children: [
              // Blurred product table
              _buildProductTableForReturned(),

              // Overlay with blur effect
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_turned_in,
                            size: 40, color: Colors.green),
                        SizedBox(height: 8),
                        Text(
                          'Cart Returned',
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'All operations completed',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductTableForReturned() {
    // Determine which products to show based on available data
    List<dynamic> products = [];
    String headerText = 'Returned Products';
    Color headerColor = Colors.grey[600]!;

    if (returnProducts.isNotEmpty) {
      products = returnProducts;
    } else if (refillProducts.isNotEmpty) {
      products = refillProducts;
    } else if (acceptProducts.isNotEmpty) {
      products = acceptProducts;
    }

    return Opacity(
      opacity: 0.7,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: headerColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Table Header
              Container(
                decoration: BoxDecoration(
                  color: headerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Product Name',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: headerColor,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Quantity',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: headerColor,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Status',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: headerColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Table Rows
              Expanded(
                child: products.isEmpty
                    ? Center(
                  child: Text(
                    'No products available',
                    style: GoogleFonts.fredoka(
                      color: Colors.grey[600],
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: index < products.length - 1
                              ? BorderSide(color: Colors.grey[200]!)
                              : BorderSide.none,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                product.productName,
                                style: GoogleFonts.fredoka(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                product.quantity.toString(),
                                style: GoogleFonts.fredoka(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => _buildQuantityContainer(
              'Total Quantity',
              _cartController.totalQuantity.value.toString(),
              Colors.pink[50]!,
              Colors.pink[800]!,
            )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() => _buildQuantityContainer(
              'Refill Quantity',
              _cartController.refillQuantity.value.toString(),
              Colors.blue[50]!,
              Colors.blue[800]!,
            )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() => _buildQuantityContainer(
              'Return Quantity',
              _cartController.returnQuantity.value.toString(),
              Colors.orange[50]!,
              Colors.orange[800]!,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildCartDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadowColor: Colors.pink.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.pink[50]!,
                Colors.pink[100]!.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cart Details',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.pink[800],
                      ),
                    ),
                    // Show order status badge
                    Obx(() {
                      String? orderStatus = _cartController.cartData.value?.data.orderproductstatus;
                      if (orderStatus != null) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(orderStatus),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(orderStatus),
                            style: GoogleFonts.fredoka(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }
                      return SizedBox();
                    }),
                  ],
                ),
                const SizedBox(height: 6),
                Obx(() => _buildDetailRow(
                  Icons.confirmation_number,
                  'Cart Number',
                  _cartController.cartNumber.value,
                )),
                Obx(() => _buildDetailRow(
                  Icons.calendar_today,
                  'Date',
                  _cartController.date.value,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "0":
        return Colors.green[400]!;
      case "1":
        return Colors.pink[400]!;
      case "3":
        return Colors.blue[400]!;
      case "5":
        return Colors.orange[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case "0":
        return 'Returned';
      case "1":
        return 'To Accept';
      case "3":
        return 'To Refill';
      case "5":
        return 'To Return';
      default:
        return 'Unknown';
    }
  }

  Widget _buildAcceptSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                'Products to Accept',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 300,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildProductTable('accept'),
        ),
      ],
    );
  }

  Widget _buildRefillSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                'Products to Refill',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 300,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildProductTable('refill'),
        ),
      ],
    );
  }

  Widget _buildReturnSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                'Products to Return',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 300,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildProductTable('return'),
        ),
      ],
    );
  }

  Widget _buildProductTable(String type) {
    return Obx(() {
      List<dynamic> products;
      String headerText;
      String quantityColumn;
      String inputColumn;
      Color headerColor;
      List<TextEditingController> controllers;

      switch (type) {
        case 'accept':
          products = acceptProducts;
          headerText = 'Products to Accept';
          quantityColumn = 'Quantity';
          inputColumn = 'Accept Qty';
          headerColor = Colors.pink[800]!;
          controllers = _cartController.acceptQtyControllers;
          break;
        case 'refill':
          products = refillProducts;
          headerText = 'Products to Refill';
          quantityColumn = 'Req Qty';
          inputColumn = 'Refill Qty';
          headerColor = Colors.blue[800]!;
          controllers = _cartController.refillQtyControllers;
          break;
        case 'return':
          products = returnProducts;
          headerText = 'Products to Return';
          quantityColumn = 'Req Qty';
          inputColumn = 'Return Qty';
          headerColor = Colors.orange[800]!;
          controllers = _cartController.returnQtyControllers;
          break;
        default:
          products = [];
          headerText = 'Products';
          quantityColumn = 'Quantity';
          inputColumn = 'Qty';
          headerColor = Colors.pink[800]!;
          controllers = [];
      }

      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: headerColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Table Header
              Container(
                decoration: BoxDecoration(
                  color: headerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Product Name',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: headerColor,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          quantityColumn,
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: headerColor,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          inputColumn,
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: headerColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Table Rows
              Expanded(
                child: products.isEmpty
                    ? Center(
                  child: Text(
                    'No products available',
                    style: GoogleFonts.fredoka(
                      color: Colors.grey[600],
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: index < products.length - 1
                              ? BorderSide(color: Colors.grey[200]!)
                              : BorderSide.none,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                product.productName,
                                style: GoogleFonts.fredoka(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                product.quantity.toString(),
                                style: GoogleFonts.fredoka(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: headerColor.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: TextField(
                                  controller: controllers.isNotEmpty && index < controllers.length
                                      ? controllers[index]
                                      : null,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                    border: InputBorder.none,
                                    hintText: '0',
                                    hintStyle: GoogleFonts.fredoka(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  style: GoogleFonts.fredoka(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    final fieldName = type == 'accept'
                                        ? 'accept_qty'
                                        : (type == 'refill' ? 'refill_qty' : 'return_qty');
                                    _cartController.updateProductQuantity(index, fieldName, value, type);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _handleAcceptCart() async {
    try {
      await _cartController.submitCartAcceptance();
      Get.snackbar(
        'Success',
        'Cart accepted successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      _isCartAccepted.value = true;

      // Skip refill section if no refill data
      if (!hasRefillData) {
        _isRefillCompleted.value = true;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to accept cart: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _handleRefillCart() async {
    try {
      await _cartController.submitRefillData();
      Get.snackbar(
        'Success',
        'Cart refilled successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      _isRefillCompleted.value = true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to refill cart: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _handleReturnCart() async {
    try {
      await _cartController.submitReturnData();
      Get.snackbar(
        'Success',
        'Cart returned successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      // Reset for next cart
      _isCartAccepted.value = false;
      _isRefillCompleted.value = false;

      // Refresh cart data for next cart
      await _cartController.refreshCartData();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to return cart: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildQuantityContainer(String title, String quantity, Color bgColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: textColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            quantity,
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.fredoka(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.pink[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.fredoka(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
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
            title: Text('Dashboard', style: GoogleFonts.fredoka()),
            onTap: () {
              Get.back();
            },
          ),
          ListTile(
            leading: Icon(Icons.location_on, color: Colors.pink[300]),
            title: Text('Locations', style: GoogleFonts.fredoka()),
            onTap: () {
              Get.back();
              Get.to(() => LocationListScreen());
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.pink[300]),
            title: Text('Logout', style: GoogleFonts.fredoka()),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}