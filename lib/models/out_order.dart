// models/out_order_response.dart
import 'out_order.dart';

class OutOrderResponse {
  final String status;
  final String msg;
  final OutOrderData data;

  OutOrderResponse({
    required this.status,
    required this.msg,
    required this.data,
  });

  factory OutOrderResponse.fromJson(Map<String, dynamic> json) {
    return OutOrderResponse(
      status: json['status'] ?? '',
      msg: json['msg'] ?? '',
      data: OutOrderData.fromJson(json['data'] ?? {}),
    );
  }
}

class OutOrderData {
  final int id;
  final String createdAt;
  final String? updatedAt;
  final String createdBy;
  final String? updatedBy;
  final bool isActive;
  final String cartSeries;
  final int? cartId;
  final String cartUserId;
  final String cartNumber;
  final String cartPersonName;
  final String address;
  final bool cartStatus;
  final String cartDate;
  final String cartOutTime;
  final String cartInTime;
  final String warehouseId;
  final String warehouseName;
  final double totalAmount;
  final dynamic verified;
  final bool isReturned;
  final bool adminReturned;
  final String orderStatus;
  final String encryptedSeriesId;
  final String convertedDate;
  final List<ProductData> stockProductData;
  final List<RefilledProductData> refilledProductData;
  final double stockamt;
  final double refillamt;
  final List<ReturnItem> returnlist;

  OutOrderData({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    this.updatedBy,
    required this.isActive,
    required this.cartSeries,
    this.cartId,
    required this.cartUserId,
    required this.cartNumber,
    required this.cartPersonName,
    required this.address,
    required this.cartStatus,
    required this.cartDate,
    required this.cartOutTime,
    required this.cartInTime,
    required this.warehouseId,
    required this.warehouseName,
    required this.totalAmount,
    this.verified,
    required this.isReturned,
    required this.adminReturned,
    required this.orderStatus,
    required this.encryptedSeriesId,
    required this.convertedDate,
    required this.stockProductData,
    required this.refilledProductData,
    required this.stockamt,
    required this.refillamt,
    required this.returnlist,
  });

  factory OutOrderData.fromJson(Map<String, dynamic> json) {
    return OutOrderData(
      id: json['id'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'],
      createdBy: json['createdBy'] ?? '',
      updatedBy: json['updatedBy'],
      isActive: json['isActive'] ?? false,
      cartSeries: json['cart_series'] ?? '',
      cartId: json['cart_id'],
      cartUserId: json['cart_user_id'] ?? '',
      cartNumber: json['cart_number'] ?? '',
      cartPersonName: json['cart_person_name'] ?? '',
      address: json['address'] ?? '',
      cartStatus: json['cart_status'] ?? false,
      cartDate: json['cart_date'] ?? '',
      cartOutTime: json['cart_out_time'] ?? '',
      cartInTime: json['cart_in_time'] ?? '',
      warehouseId: json['warehouse_id'] ?? '',
      warehouseName: json['warehouse_name'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      verified: json['verified'],
      isReturned: json['is_returned'] ?? false,
      adminReturned: json['admin_returned'] ?? false,
      orderStatus: json['order_status'] ?? '',
      encryptedSeriesId: json['encrypted_series_id'] ?? '',
      convertedDate: json['converted_date'] ?? '',
      stockProductData: (json['stock_product_data'] as List?)
          ?.map((e) => ProductData.fromJson(e))
          .toList() ?? [],
      refilledProductData: (json['refilled_product_data'] as List?)
          ?.map((e) =>RefilledProductData.fromJson(e))
          .toList() ?? [],
      stockamt: (json['stockamt'] ?? 0).toDouble(),
      refillamt: (json['refillamt'] ?? 0).toDouble(),
      returnlist: (json['returnlist'] as List?)
          ?.map((e) => ReturnItem.fromJson(e))
          .toList() ?? [],
    );
  }
}

class ProductData {
  final int id;
  final String createdAt;
  final String? updatedAt;
  final String createdBy;
  final String? updatedBy;
  final bool isActive;
  final int wheelCartId;
  final int productId;
  final String productName;
  final String skuCode;
  final int quantity;
  final int acceptedQuantity;
  final double unitPrice;
  final double totalAmount;
  final int requestType;

  ProductData({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    this.updatedBy,
    required this.isActive,
    required this.wheelCartId,
    required this.productId,
    required this.productName,
    required this.skuCode,
    required this.quantity,
    required this.acceptedQuantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.requestType,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    return ProductData(
      id: json['id'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'],
      createdBy: json['createdBy'] ?? '',
      updatedBy: json['updatedBy'],
      isActive: json['isActive'] ?? false,
      wheelCartId: json['wheel_cart_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      skuCode: json['sku_code'] ?? '',
      quantity: json['quantity'] ?? 0,
      acceptedQuantity: json['accepted_quantity'] ?? 0,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      requestType: json['request_type'] ?? 0,
    );
  }
}


class RefilledProductData {
  final int id;
  final String createdAt;
  final String? updatedAt;
  final String createdBy;
  final String? updatedBy;
  final bool isActive;
  final int wheelCartId;
  final int productId;
  final String productName;
  final String skuCode;
  final int quantity;
  final int acceptedQuantity;
  final double unitPrice;
  final double totalAmount;
  final int requestType;

  RefilledProductData({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    this.updatedBy,
    required this.isActive,
    required this.wheelCartId,
    required this.productId,
    required this.productName,
    required this.skuCode,
    required this.quantity,
    required this.acceptedQuantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.requestType,
  });

  factory RefilledProductData.fromJson(Map<String, dynamic> json) {
    return RefilledProductData(
      id: json['id'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'],
      createdBy: json['createdBy'] ?? '',
      updatedBy: json['updatedBy'],
      isActive: json['isActive'] ?? false,
      wheelCartId: json['wheel_cart_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      skuCode: json['sku_code'] ?? '',
      quantity: json['quantity'] ?? 0,
      acceptedQuantity: json['accepted_quantity'] ?? 0,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      requestType: json['request_type'] ?? 0,
    );
  }
}

class ReturnItem {
  final int id;
  final String createdAt;
  final String? updatedAt;
  final String createdBy;
  final String? updatedBy;
  final bool isActive;
  final int wheelCartId;
  final int productId;
  final String productName;
  final String skuCode;
  final int quantity;
  final int acceptedQuantity;
  final double unitPrice;
  final double totalAmount;
  final int requestType;
  final int returnedQty;

  ReturnItem({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    this.updatedBy,
    required this.isActive,
    required this.wheelCartId,
    required this.productId,
    required this.productName,
    required this.skuCode,
    required this.quantity,
    required this.acceptedQuantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.requestType,
    required this.returnedQty,
  });

  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    return ReturnItem(
      id: json['id'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'],
      createdBy: json['createdBy'] ?? '',
      updatedBy: json['updatedBy'],
      isActive: json['isActive'] ?? false,
      wheelCartId: json['wheel_cart_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      skuCode: json['sku_code'] ?? '',
      quantity: json['quantity'] ?? 0,
      acceptedQuantity: json['accepted_quantity'] ?? 0,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      requestType: json['request_type'] ?? 0,
      returnedQty: json['returned_qty'] ?? 0,
    );
  }
}