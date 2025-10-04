import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controllers/out_order_controller.dart';
import '../models/out_order.dart';

class OutOrderDetailScreen extends StatelessWidget {
  OutOrderDetailScreen({super.key});

  final OutOrderDetailController _controller =
  Get.put(OutOrderDetailController());
  final RxString selectedProductType = 'Stock Products'.obs;

  @override
  Widget build(BuildContext context) {
    final encryptedSeriesId = Get.arguments as String;
    bool _hasValidationErrors() {
      return _controller.quantityErrors.isNotEmpty ||
          _controller.returnQuantityErrors.isNotEmpty;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchOrderDetail(encryptedSeriesId);
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Order Details',
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

      floatingActionButton: Obx(() {
        if (_controller.orderDetail.value == null) return Container();
        final hasErrors = _hasValidationErrors();
        final hasZeroQuantities = _hasZeroQuantities();

        // Determine which button to show based on selected product type
        switch (selectedProductType.value) {
          case 'Stock Products':
          // Check if any stock product has acceptedQuantity == 0
            final hasUnacceptedProducts = _controller.orderDetail.value!.stockProductData
                .any((product) => product.acceptedQuantity == 0);

            return FloatingActionButton.extended(
              onPressed: hasErrors || !hasUnacceptedProducts || hasZeroQuantities
                  ? () {
                if (hasZeroQuantities) {
                 // _showZeroQuantityPopup();
                  Get.snackbar(
                    'Error',
                    'Quantity cannot be 0. Please enter a valid quantity for all products.',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              }
                  : () => _controller.submitAcceptedQuantities(encryptedSeriesId),
              label: Text(
                'Accept',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              backgroundColor: hasErrors || !hasUnacceptedProducts
                  ? Colors.grey
                  : Colors.green[600],
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            );

          case 'Refill Products':
          // Check if any refill product has acceptedQuantity == 0
            final hasUnacceptedRefillProducts = _controller.orderDetail.value!.refilledProductData
                .any((product) => product.acceptedQuantity == 0);

            return FloatingActionButton.extended(
              onPressed: hasErrors || !hasUnacceptedRefillProducts
                  ? () {
                if (hasZeroQuantities) {
                 // _showZeroQuantityPopup();
                  Get.snackbar(
                    'Error',
                    'Quantity cannot be 0. Please enter a valid quantity for all products.',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              }
                  : () => _controller.submitRefillQuantities(encryptedSeriesId),
              label: Text(
                'Refill',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              backgroundColor: hasErrors || !hasUnacceptedRefillProducts || hasZeroQuantities
                  ? Colors.grey
                  : Colors.blue[600],
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            );

          case 'Return Products':
            return FloatingActionButton.extended(
              onPressed: hasErrors ? null : () => _controller.returnCartQuantity(encryptedSeriesId),
              label: Text(
                'Return',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              backgroundColor: hasErrors ? Colors.grey : Colors.orange[600],
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            );
          default:
            return FloatingActionButton.extended(
              onPressed: (){},
              label: Text(
                'Submit Check-In',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.pink[400],
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            );
        }
      }),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.pink[400],
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading Order Details...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        if (_controller.orderDetail.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No order details available',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        final order = _controller.orderDetail.value!;
        final currencyFormat = NumberFormat.currency(symbol: '₹');

        return SingleChildScrollView(
          padding:
          const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Card
              Card(
                elevation: 2,
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order Summary',
                              style: GoogleFonts.fredoka(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.pink[800],
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
                        _buildDetailRow(
                            Icons.numbers, 'Order Series', order.cartSeries),
                        _buildDetailRow(Icons.confirmation_number,
                            'Cart Number', order.cartNumber),
                        _buildDetailRow(
                            Icons.person, 'Person', order.cartPersonName),
                        _buildDetailRow(
                            Icons.warehouse, 'Warehouse', order.warehouseName),
                        _buildDetailRow(
                            Icons.location_on, 'Address', order.address),
                        _buildDetailRow(
                            Icons.calendar_today, 'Date', order.cartDate),
                        _buildDetailRow(
                          Icons.currency_rupee_outlined,
                          'Total Amount',
                          currencyFormat.format(order.totalAmount),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Product Type Selector with Dropdown
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Products',
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                  Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          borderRadius: BorderRadius.circular(12),
                          value: selectedProductType.value,
                          icon: Icon(Icons.arrow_drop_down,
                              color: Colors.pink[400]),
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              selectedProductType.value = newValue;
                            }
                          },
                          items: [
                            DropdownMenuItem(
                              value: 'Stock Products',
                              child: Text(
                                'Stock (${order.stockProductData.length})',
                                style: GoogleFonts.fredoka(),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Refill Products',
                              child: Text(
                                'Refill (${order.refilledProductData.length})',
                                style: GoogleFonts.fredoka(),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Return Products',
                              child: Text(
                                'Return (${order.returnlist.length})',
                                style: GoogleFonts.fredoka(),
                              ),
                            ),
                          ],
                        ),
                      ))),
                ],
              ),

              const SizedBox(height: 12),

              // Display selected product list
              Obx(() {
                switch (selectedProductType.value) {
                  case 'Stock Products':
                    return Column(
                      children: order.stockProductData
                          .map((product) => _buildProductCard(product, 'stock'))
                          .toList(),
                    );
                  case 'Refill Products':
                    return Column(
                      children: order.refilledProductData
                          .map(
                              (product) => _buildProductCard(product, 'refill'))
                          .toList(),
                    );
                  case 'Return Products':
                    return Column(
                      children: order.returnlist
                          .map((product) => _buildReturnProductCard(product))
                          .toList(),
                    );
                  default:
                    return Container();
                }
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.pink[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: GoogleFonts.fredoka(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(dynamic product, String type) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    final quantityController = _controller.quantityControllers.putIfAbsent(
      product.id.toString(),
          () => TextEditingController(text: product.acceptedQuantity.toString()),
    );

    Color borderColor = Colors.pink[300]!;
    String productTypeLabel = '';

    if (type == 'refill') {
      borderColor = Colors.blue[300]!;
      productTypeLabel = 'Refill';
    } else if (type == 'return') {
      borderColor = Colors.orange[300]!;
      productTypeLabel = 'Return';
    }

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: borderColor,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.productName,
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  if (productTypeLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: borderColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        productTypeLabel,
                        style: GoogleFonts.fredoka(
                          fontSize: 12,
                          color: borderColor,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.pink[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ID: ${product.id}',
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        color: Colors.pink[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildProductDetailRow(
                  Icons.barcode_reader, 'SKU Code', product.skuCode),
              _buildProductDetailRow(
                  Icons.inventory_2, 'Quantity', product.quantity.toString()),
              _buildProductDetailRow(
                Icons.currency_rupee_outlined,
                'Unit Price',
                currencyFormat.format(product.unitPrice),
              ),
              _buildProductDetailRow(
                Icons.calculate,
                'Total',
                currencyFormat.format(product.totalAmount),
              ),

              // Quantity input for stock and refill products
              if (type != 'return') ...[
                const SizedBox(height: 16),
                Text(
                  'Enter Accepted Quantity',
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  enabled: product.acceptedQuantity == 0,
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    labelStyle: GoogleFonts.fredoka(
                      color: Colors.grey[600],
                    ),
                    hintText: 'Max ${product.quantity}',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    suffixText: '/${product.quantity}',
                    errorText: _controller.quantityErrors['${product.id}'],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.pink[400]!,
                        width: 1.5,
                      ),
                    ),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    final enteredQty = int.tryParse(value) ?? 0;
                    if (enteredQty == 0) {
                      return 'Quantity cannot be 0';
                    }
                    if (enteredQty > product.quantity) {
                      return 'Cannot exceed ${product.quantity}';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _controller.quantityErrors.remove('${product.id}');
                    final enteredQty = int.tryParse(value) ?? 0;
                    if (enteredQty == 0) {
                      _controller.quantityErrors['${product.id}'] = 'Quantity cannot be 0';
                    } else if (enteredQty > product.quantity) {
                      _controller.quantityErrors['${product.id}'] = 'Cannot exceed ${product.quantity}';
                    } else {
                      _controller.quantityErrors.remove('${product.id}');
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReturnProductCard(ReturnItem product) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    final returnQuantityController = _controller.returnQuantityControllers.putIfAbsent(
      product.id.toString(),
          () => TextEditingController(text: product.returnedQty.toString()),
    );

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Colors.orange[300]!,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.productName,
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Return',
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.pink[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ID: ${product.id}',
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        color: Colors.pink[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildProductDetailRow(
                  Icons.barcode_reader, 'SKU Code', product.skuCode),
              _buildProductDetailRow(
                  Icons.inventory_2, 'Quantity', product.quantity.toString()),
              _buildProductDetailRow(Icons.inventory_2, 'Accepted Qty',
                  product.acceptedQuantity.toString()),
              _buildProductDetailRow(
                Icons.currency_rupee_outlined,
                'Unit Price',
                currencyFormat.format(product.unitPrice),
              ),
              _buildProductDetailRow(
                Icons.calculate,
                'Total',
                currencyFormat.format(product.totalAmount),
              ),

              // Return quantity input for return products
              const SizedBox(height: 16),
              Text(
                'Enter Return Quantity',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: returnQuantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Return Quantity',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  labelStyle: GoogleFonts.fredoka(
                    color: Colors.grey[600],
                  ),
                  hintText: 'Max ${product.acceptedQuantity}',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  suffixText: '/${product.acceptedQuantity}',
                  errorText: _controller.returnQuantityErrors['${product.id}'],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.orange[400]!,
                      width: 1.5,
                    ),
                  ),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter return quantity';
                  }
                  final enteredQty = int.tryParse(value) ?? 0;
                  if (enteredQty > product.acceptedQuantity) {
                    return 'Cannot exceed ${product.acceptedQuantity}';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Clear any existing error
                  _controller.returnQuantityErrors.remove('${product.id}');

                  // Perform validation
                  if (value.isNotEmpty) {
                    final enteredQty = int.tryParse(value) ?? 0;
                    if (enteredQty > product.acceptedQuantity) {
                      _controller.returnQuantityErrors['${product.id}'] =
                      'Cannot exceed ${product.acceptedQuantity}';
                    }
                  }

                  // Trigger UI update if using reactive controller
                  _controller.update(); // Add this if your controller extends GetxController
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: GoogleFonts.fredoka(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

/*  Widget _buildBatchRow(ProductData product, Batch batch) {
    final controller = _controller.quantityControllers['${product.id}_${batch.batchNumber}'];

    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.pink[200],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batch.batchNumber,
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Quantity: ${batch.batchQuantity} units',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Sold Qty',
                labelStyle: GoogleFonts.fredoka(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.pink[400]!,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }*/
  void _showZeroQuantityPopup() {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Validation Error',
          style: GoogleFonts.fredoka(
            color: Colors.red[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Quantity cannot be 0. Please enter a valid quantity for all products.',
          style: GoogleFonts.fredoka(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'OK',
              style: GoogleFonts.fredoka(
                color: Colors.pink[400],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasZeroQuantities() {
    final order = _controller.orderDetail.value!;

    switch (selectedProductType.value) {
      case 'Stock Products':
        return order.stockProductData.any((product) {
          final controller = _controller.quantityControllers['${product.id}'];
          final enteredQty = controller != null ? int.tryParse(controller.text) ?? 0 : 0;
          return enteredQty == 0;
        });
      case 'Refill Products':
        return order.refilledProductData.any((product) {
          final controller = _controller.quantityControllers['${product.id}'];
          final enteredQty = controller != null ? int.tryParse(controller.text) ?? 0 : 0;
          return enteredQty == 0;
        });
      case 'Return Products':
        return order.returnlist.any((product) {
          final controller = _controller.returnQuantityControllers['${product.id}'];
          final enteredQty = controller != null ? int.tryParse(controller.text) ?? 0 : 0;
          return enteredQty == 0;
        });
      default:
        return false;
    }
  }
  Widget _buildRejectionDialog(
    BuildContext context,
    int productId,
    TextEditingController reasonController,
  ) {
    final formKey = GlobalKey<FormState>();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Reject Product?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please provide a reason for rejecting this product',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Form(
              key: formKey,
              child: TextFormField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason*',
                  hintText: 'Enter rejection reason...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.pink[400]!,
                      width: 1.5,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter rejection reason';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        _controller.rejectProduct(
                          productId: productId,
                          reason: reasonController.text,
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Confirm Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
