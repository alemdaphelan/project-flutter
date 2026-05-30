import 'package:cloud_firestore/cloud_firestore.dart';

/// Các trạng thái đơn hàng theo nghiệp vụ thực tế
enum OrderStatus {
  pending,    // Đang xử lý  — người bán chưa làm gì
  shipping,   // Đang giao   — người bán đã nhập mã vận đơn
  completed,  // Hoàn thành  — người mua xác nhận đã nhận
  cancelled,  // Đã hủy
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:   return 'Đang xử lý';
      case OrderStatus.shipping:  return 'Đang giao hàng';
      case OrderStatus.completed: return 'Hoàn thành';
      case OrderStatus.cancelled: return 'Đã hủy';
    }
  }

  /// Map sang index của Stepper
  int get stepIndex {
    switch (this) {
      case OrderStatus.pending:   return 0;
      case OrderStatus.shipping:  return 1;
      case OrderStatus.completed: return 2;
      case OrderStatus.cancelled: return 0;
    }
  }

  static OrderStatus fromString(String s) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => OrderStatus.pending,
    );
  }
}

class OrderModel {
  final String id;            // Firestore doc ID
  final String buyerId;       // FK → UserProfile.uid
  final String sellerId;      // FK → UserProfile.uid
  final String productId;     // FK → ProductModel (để tra cứu sau)
  final String productName;
  final String productImageUrl;
  final double price;         // double thay vì String để tính toán được

  // Thông tin giao hàng
  final String receiverName;
  final String receiverPhone;
  final String deliveryAddress; // tỉnh + phường + số nhà đã ghép

  // Thanh toán
  final String paymentMethod;   // "COD" | "Bank"

  // Vận chuyển
  final String trackingNumber;  // mã vận đơn — rỗng khi chưa gửi

  // Trạng thái
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.price,
    required this.receiverName,
    required this.receiverPhone,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.trackingNumber = '',
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      receiverName: map['receiverName'] ?? '',
      receiverPhone: map['receiverPhone'] ?? '',
      deliveryAddress: map['deliveryAddress'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'COD',
      trackingNumber: map['trackingNumber'] ?? '',
      status: OrderStatusX.fromString(map['status'] ?? 'pending'),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'sellerId': sellerId,
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'price': price,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'trackingNumber': trackingNumber,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  OrderModel copyWith({
    String? trackingNumber,
    OrderStatus? status,
  }) {
    return OrderModel(
      id: id,
      buyerId: buyerId,
      sellerId: sellerId,
      productId: productId,
      productName: productName,
      productImageUrl: productImageUrl,
      price: price,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}