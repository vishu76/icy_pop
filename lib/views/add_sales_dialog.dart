// widgets/add_sales_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sales_controller.dart';
import '../models/out_order.dart';

class AddSalesDialog extends StatefulWidget {
  final String cartSeries;
  final String cartId;
  final String warehouseId;
  final List<ProductData> products;

  const AddSalesDialog({
    super.key,
    required this.cartSeries,
    required this.cartId,
    required this.warehouseId,
    required this.products,
  });

  @override
  State<AddSalesDialog> createState() => _AddSalesDialogState();
}

class _AddSalesDialogState extends State<AddSalesDialog> {
  final SalesController _controller = Get.put(SalesController());
  final List<Map<String, dynamic>> _productList = [];
  final Map<String, TextEditingController> _quantityControllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each batch
   /* for (var product in widget.products) {
      for (var batch in product.batchList) {
        _quantityControllers['${product.productId}_${batch.batchNumber}'] =
            TextEditingController(text: '0');
      }
    }*/
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Sales'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...widget.products.expand((product) => [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  product.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            /*  ...product.batchList.map((batch) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Batch: ${batch.batchNumber}'),
                    ),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _quantityControllers['${product.productId}_${batch.batchNumber}'],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Qty',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              )),*/
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        Obx(() => ElevatedButton(
          onPressed: _controller.isLoading.value ? null : _submitSales,
          child: _controller.isLoading.value
              ? CircularProgressIndicator(color: Colors.pink[300])
              : const Text('Submit'),
        )),
      ],
    );
  }

  void _submitSales() {
    _productList.clear();

    // Group batches by product
    final productMap = <int, List<Map<String, dynamic>>>{};

 /*   for (var product in widget.products) {
      for (var batch in product.batchList) {
        final controller = _quantityControllers['${product.productId}_${batch.batchNumber}'];
        final quantity = int.tryParse(controller?.text ?? '0') ?? 0;

        if (quantity > 0) {
          productMap.putIfAbsent(product.productId, () => []);
          productMap[product.productId]!.add({
            'batch_number': batch.batchNumber,
            'sold_quantity': quantity.toString(),
          });
        }
      }
    }*/

    // Convert to required format
    productMap.forEach((productId, batches) {
      _productList.add({
        'product_id': productId.toString(),
        'batch_list': batches,
      });
    });

    if (_productList.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter quantities for at least one batch',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _controller.addSales(
      cartSeries: widget.cartSeries,
      cartId: widget.cartId,
      warehouseId: widget.warehouseId,
      productList: _productList,
    );
  }
}