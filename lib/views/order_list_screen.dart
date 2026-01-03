import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controllers/order_list_controller.dart';
import '../models/order_list.dart';

class OrderListScreen extends StatelessWidget {
  final OrderListController _controller = Get.put(OrderListController());

  OrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = Get.arguments as Map<String, dynamic>?;
      if (arguments != null && arguments['refresh'] == true) {
        _controller.fetchOrders();
      }
    });
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        title: Text('Wheel Cart Requests',
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
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: Colors.pink[300],));
        }

        return Column(
          children: [
            if (_controller.errorMessage.value.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                 /*   Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _controller.errorMessage.value,
                            style: GoogleFonts.fredoka(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),*/
                    if (_controller.tokenExpired.value)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink[400],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            // Navigate to login screen
                            // You may use Get.offAll() or similar depending on your flow
                            Get.offAllNamed('/login');
                          },
                          icon: const Icon(Icons.login),
                          label: const Text("Login Again"),
                        ),
                      ),
                  ],
                ),
              ),
              /*Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _controller.errorMessage.value,
                        style: GoogleFonts.fredoka(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),*/
            Expanded(
              child: RefreshIndicator(
                color: Colors.pink[300],
                onRefresh: _controller.fetchOrders,
                child: _controller.orders.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_rounded, size: 64, color: Colors.pink[200]),
                      const SizedBox(height: 10),
                      Text(
                        'No orders found',
                        style: GoogleFonts.fredoka(
                            fontSize: 18,
                            color: Colors.grey
                        ),
                      ),
                      /*TextButton(
                        onPressed: () => _showApiResponse(context),
                        child: const Text('View API Response'),
                      ),*/
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: _controller.orders.length,
                  itemBuilder: (context, index) {
                    final order = _controller.orders[index];
                    return _buildOrderCard(order);
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showApiResponse(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Response'),
        content: SingleChildScrollView(
          child: Text(
            _controller.apiResponse.value.isEmpty
                ? 'No response data available'
                : _controller.apiResponse.value,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Clipboard.setData(
                ClipboardData(text: _controller.apiResponse.value),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Response copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(WheelCartOrder order) {
    final dateFormat = DateFormat('dd-MM-yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _controller.navigateToOrderDetail(order.encryptedSeriesId),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        order.cartSeries,
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: order.orderStatus.toLowerCase() == 'accepted'
                              ? Colors.green
                              : order.orderStatus.toLowerCase() == 'refilled'
                              ? Colors.blue
                              : order.orderStatus.toLowerCase() == 'returned'
                              ? Colors.orange
                              : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        order.orderStatus,
                        style: GoogleFonts.fredoka(
                          color: order.orderStatus.toLowerCase() == 'accepted'
                              ? Colors.green
                              : order.orderStatus.toLowerCase() == 'refilled'
                              ? Colors.blue
                              : order.orderStatus.toLowerCase() == 'returned'
                              ? Colors.orange
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Cart Number', Icons.confirmation_number, order.cartNumber),
                _buildInfoRow('Person', Icons.person_outline, order.cartPersonName),
                _buildInfoRow('Warehouse', Icons.store, order.warehouseName),
                _buildInfoRow('Address', Icons.location_on_outlined, order.address),
                const SizedBox(height: 12),
                Divider(
                  color: Colors.grey[200],
                  thickness: 1,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.blueGrey[500]),
                        const SizedBox(width: 4),
                        Text(
                          order.cartDate,
                          style: GoogleFonts.fredoka(
                            color: Colors.blueGrey[600]
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Total: ${currencyFormat.format(order.totalAmount)}',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.blueGrey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Created: ${dateFormat.format(order.createdAt)} by ${order.createdName}',
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey[500]),
          const SizedBox(width: 8),
          Text('$label: ',
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.fredoka(
                color: Colors.blueGrey[800],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
