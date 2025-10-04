class CartDataModel {
  final String status;
  final String msg;
  final CartData data;

  CartDataModel({
    required this.status,
    required this.msg,
    required this.data,
  });

  factory CartDataModel.fromJson(Map<String, dynamic> json) {
    return CartDataModel(
      status: json['status'] ?? '',
      msg: json['msg'] ?? '',
      data: CartData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'msg': msg,
      'data': data.toJson(),
    };
  }
}

class CartData {
  final int id;
  final String createdAt;
  final String? updatedAt;
  final String createdBy;
  final String? updatedBy;
  final bool isActive;
  final String cartSeries;
  final String? cartId;
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
  final String orderproductstatus;
  final List<StockProduct> stockProductData;
  final List<RefillProduct> refilledProductData; // Changed from List<dynamic>
  final double stockamt;
  final double refillamt;
  final List<ReturnProduct> returnlist;

  CartData({
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
    required this.orderproductstatus,
    required this.totalAmount,
    this.verified,
    required this.isReturned,
    required this.adminReturned,
    required this.orderStatus,
    required this.encryptedSeriesId,
    required this.convertedDate,
    required this.stockProductData,
    required this.refilledProductData, // Updated type
    required this.stockamt,
    required this.refillamt,
    required this.returnlist,
  });

  factory CartData.fromJson(Map<String, dynamic> json) {
    return CartData(
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
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      verified: json['verified'],
      isReturned: json['is_returned'] ?? false,
      adminReturned: json['admin_returned'] ?? false,
      orderStatus: json['order_status'] ?? '',
      encryptedSeriesId: json['encrypted_series_id'] ?? '',
      convertedDate: json['converted_date'] ?? '',
      orderproductstatus: json['order_product_status'] ?? '',
      stockProductData: (json['stock_product_data'] as List? ?? [])
          .map((item) => StockProduct.fromJson(item))
          .toList(),
      refilledProductData: (json['refilled_product_data'] as List? ?? [])
          .map((item) => RefillProduct.fromJson(item)) // Use RefillProduct parser
          .toList(),
      stockamt: (json['stockamt'] ?? 0.0).toDouble(),
      refillamt: (json['refillamt'] ?? 0.0).toDouble(),
      returnlist: (json['returnlist'] as List? ?? [])
          .map((item) => ReturnProduct.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isActive': isActive,
      'cart_series': cartSeries,
      'cart_id': cartId,
      'cart_user_id': cartUserId,
      'cart_number': cartNumber,
      'cart_person_name': cartPersonName,
      'address': address,
      'cart_status': cartStatus,
      'cart_date': cartDate,
      'cart_out_time': cartOutTime,
      'cart_in_time': cartInTime,
      'warehouse_id': warehouseId,
      'warehouse_name': warehouseName,
      'total_amount': totalAmount,
      'verified': verified,
      'is_returned': isReturned,
      'admin_returned': adminReturned,
      'order_status': orderStatus,
      'order_product_status': orderproductstatus,
      'encrypted_series_id': encryptedSeriesId,
      'converted_date': convertedDate,
      'stock_product_data': stockProductData.map((item) => item.toJson()).toList(),
      'refilled_product_data': refilledProductData.map((item) => item.toJson()).toList(),
      'stockamt': stockamt,
      'refillamt': refillamt,
      'returnlist': returnlist.map((item) => item.toJson()).toList(),
    };
  }
}

class StockProduct {
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

  StockProduct({
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

  factory StockProduct.fromJson(Map<String, dynamic> json) {
    return StockProduct(
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
      unitPrice: (json['unit_price'] ?? 0.0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      requestType: json['request_type'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isActive': isActive,
      'wheel_cart_id': wheelCartId,
      'product_id': productId,
      'product_name': productName,
      'sku_code': skuCode,
      'quantity': quantity,
      'accepted_quantity': acceptedQuantity,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'request_type': requestType,
    };
  }
}

// NEW: RefillProduct model for refilled_product_data
class RefillProduct {
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

  RefillProduct({
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

  factory RefillProduct.fromJson(Map<String, dynamic> json) {
    return RefillProduct(
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
      unitPrice: (json['unit_price'] ?? 0.0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      requestType: json['request_type'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isActive': isActive,
      'wheel_cart_id': wheelCartId,
      'product_id': productId,
      'product_name': productName,
      'sku_code': skuCode,
      'quantity': quantity,
      'accepted_quantity': acceptedQuantity,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'request_type': requestType,
    };
  }
}

class ReturnProduct {
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

  ReturnProduct({
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

  factory ReturnProduct.fromJson(Map<String, dynamic> json) {
    return ReturnProduct(
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
      unitPrice: (json['unit_price'] ?? 0.0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      requestType: json['request_type'] ?? 0,
      returnedQty: json['returned_qty'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isActive': isActive,
      'wheel_cart_id': wheelCartId,
      'product_id': productId,
      'product_name': productName,
      'sku_code': skuCode,
      'quantity': quantity,
      'accepted_quantity': acceptedQuantity,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'request_type': requestType,
      'returned_qty': returnedQty,
    };
  }
}