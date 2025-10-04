// models/wheel_cart_order.dart
class WheelCartOrder {
  final int id;
  final String cartSeries;
  final int cartId;
  final String cartNumber;
  final String cartPersonName;
  final String address;
  final bool cartStatus;
  final String cartDate;
  final String warehouseName;
  final double totalAmount;
  final DateTime createdAt;
  final String createdName;
  final String encryptedSeriesId;
  final String orderStatus; // New field
  final bool wheelCartIn; // New field

  WheelCartOrder({
    required this.id,
    required this.cartSeries,
    required this.cartId,
    required this.cartNumber,
    required this.cartPersonName,
    required this.address,
    required this.cartStatus,
    required this.cartDate,
    required this.warehouseName,
    required this.totalAmount,
    required this.createdAt,
    required this.createdName,
    required this.encryptedSeriesId,
    required this.orderStatus, // New field
    required this.wheelCartIn, // New field
  });

  factory WheelCartOrder.fromJson(Map<String, dynamic> json) {
    return WheelCartOrder(
      id: json['id'] ?? 0,
      cartSeries: json['cart_series'] ?? '',
      cartId: json['cart_id'] ?? 0,
      cartNumber: json['cart_number'] ?? '',
      cartPersonName: json['cart_person_name'] ?? '',
      address: json['address'] ?? '',
      cartStatus: json['cart_status'] ?? false,
      cartDate: json['cart_date'] ?? '',
      warehouseName: json['warehouse_name'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      createdName: json['created_name'] ?? '',
      encryptedSeriesId: json['encrypted_series_id'] ?? '',
      orderStatus: json['order_status'] ?? 'Pending', // New field
      wheelCartIn: json['wheel_cart_in'] ?? false, // New field
    );
  }
}