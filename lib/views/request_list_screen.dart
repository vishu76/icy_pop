// views/request_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controllers/request_list_controller.dart';
import '../models/order_list.dart';

class RequestListScreen extends StatelessWidget {
  final RequestListController _controller = Get.put(RequestListController());

  RequestListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[50], // Different background color
      appBar: AppBar(
        title: Text(
          'Wheel Cart Returns',
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple[400], // Different app bar color
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
          return Center(
              child: CircularProgressIndicator(color: Colors.purple[300]));
        }

        return Column(
          children: [
            if (_controller.errorMessage.value.isNotEmpty)
              Container(
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
              ),
            Expanded(
              child: RefreshIndicator(
                color: Colors.purple[300],
                onRefresh: _controller.fetchRequests,
                child: _controller.requests.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.request_page,
                          size: 64, color: Colors.purple[200]),
                      const SizedBox(height: 10),
                      Text(
                        'No pending requests',
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: _controller.requests.length,
                  itemBuilder: (context, index) {
                    final request = _controller.requests[index];
                    return _buildRequestCard(request);
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildRequestCard(WheelCartOrder request) {
    final dateFormat = DateFormat('dd-MM-yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _controller.navigateToRequestDetail(request.encryptedSeriesId),
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
                        request.cartSeries,
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
                          color: request.orderStatus.toLowerCase() == 'accepted'
                              ? Colors.green
                              : request.orderStatus.toLowerCase() == 'refilled'
                              ? Colors.blue
                              : request.orderStatus.toLowerCase() == 'returned'
                              ? Colors.orange
                              : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        request.orderStatus,
                        style: GoogleFonts.fredoka(
                          color: request.orderStatus.toLowerCase() == 'accepted'
                              ? Colors.green
                              : request.orderStatus.toLowerCase() == 'refilled'
                              ? Colors.blue
                              : request.orderStatus.toLowerCase() == 'returned'
                              ? Colors.orange
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Cart Number', Icons.confirmation_number, request.cartNumber),
                _buildInfoRow('Person', Icons.person_outline, request.cartPersonName),
                _buildInfoRow('Warehouse', Icons.store, request.warehouseName),
                _buildInfoRow('Address', Icons.location_on_outlined, request.address),
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
                          request.cartDate,
                          style: GoogleFonts.fredoka(
                              color: Colors.blueGrey[600]),
                        ),
                      ],
                    ),
                    Text(
                      'Total: ${currencyFormat.format(request.totalAmount)}',
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
                      'Created: ${dateFormat.format(request.createdAt)} by ${request.createdName}',
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