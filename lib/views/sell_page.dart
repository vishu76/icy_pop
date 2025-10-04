import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sell_controller.dart';
import '../controllers/ice_cream_sale_controller.dart';

class SellPage extends StatelessWidget {
  final SellController _sellController = Get.put(SellController());

  final List<String> iceCreamNames = [
    'Choco Bliss',
    'Vanilla Dream',
    'Strawberry Swirl',
    'Minty Magic',
    'Caramel Crunch',
    'Cookies & Cream Delight',
    'Blueberry Burst',
    'Mango Tango',
    'Rocky Road Adventure',
    'Pistachio Paradise',
    'Red Velvet Scoop',
    'Honey Almond Drizzle',
  ];

  final List<IceCreamSaleController> iceCreamControllers = List.generate(
      12,
      (index) => Get.put(IceCreamSaleController(availableStock: 50),
          tag: "iceCream_$index"));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        title: Text(
          'Sell Ice Cream',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.pink[300],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: iceCreamNames.length,
          itemBuilder: (context, index) {
            final iceController = iceCreamControllers[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      iceCreamNames[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink[300],
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextField(
                            enabled: false,
                            controller: TextEditingController(
                              text: iceController.availableStock.toString(),
                            ),
                            decoration: InputDecoration(
                              labelText: 'Available',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.inventory,
                                  color: Colors.pink[300]),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Sold',
                              labelStyle: TextStyle(color: Colors.pink[300]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.point_of_sale,
                                  color: Colors.pink[300]),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              iceController.updateSale(value);
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Obx(() {
                      final sold = iceController.sold.value;
                      final balance = iceController.availableStock - sold;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Sold: $sold",
                            style: TextStyle(color: Colors.pink[400]),
                          ),
                          Text(
                            "Balance: $balance",
                            style: TextStyle(color: Colors.pink[400]),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final List<int> sales = iceCreamControllers
              .map((controller) => controller.sold.value)
              .toList();
          _sellController.submitSales(sales);
        },
        label: Text(
          'Submit Sales',
          style: TextStyle(color: Colors.white),
        ),
        icon: Icon(
          Icons.check,
          color: Colors.white,
        ),
        backgroundColor: Colors.pink[400],
      ),
    );
  }
}
