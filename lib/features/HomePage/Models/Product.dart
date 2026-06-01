import 'package:project_flutter/shared/models/user_profile.dart';

enum ProductStatus { available, reserved, sold }

class ProductModel {
  final String id;           // Firestore doc ID — cần để update status
  final String sellerId;
  final String sellerName;
  final String time;
  final String productImageUrl;
  final String productName;
  final double price;
  final Map<String, dynamic> specifications;
  final String description;
  final String location;
  final String category;
  final ProductStatus status; // ← MỚI

  UserProfile? seller;

  ProductModel({
    required this.id,
    required this.sellerId,
    this.sellerName = '',
    required this.time,
    required this.productImageUrl,
    required this.productName,
    required this.price,
    required this.specifications,
    required this.description,
    required this.location,
    required this.category,
    this.status = ProductStatus.available,
  });

  bool get isAvailable => status == ProductStatus.available;
  bool get isReserved  => status == ProductStatus.reserved;
  bool get isSold      => status == ProductStatus.sold;

  Map<String, dynamic> toMap() {
    return {
      'sellerId':    sellerId,
      'sellerName':  sellerName,
      'image':       productImageUrl,
      'name':        productName,
      'price':       price,
      'fields':      specifications,
      'description': description,
      'location':    location,
      'category':    category,
      'time':        DateTime.now(),
      'status':      status.name, // ← lưu khi tạo mới
    };
  }

  factory ProductModel.fromFirestore(Map<String, dynamic> data, String id) {
    final statusStr = data['status'] as String? ?? 'available';
    final status = ProductStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => ProductStatus.available, // doc cũ chưa có field → available
    );

    return ProductModel(
      id:             id,
      sellerId:       data['sellerId'] ?? '',
      sellerName:     data['sellerName'] ?? '',
      time:           data['time'] != null
                        ? data['time'].toDate().toString()
                        : DateTime.now().toString(),
      productImageUrl: data['image'] ?? '',
      productName:    data['name'] ?? '',
      price:          (data['price'] ?? 0).toDouble(),
      specifications: Map<String, dynamic>.from(data['fields'] ?? {}),
      description:    data['description'] ?? '',
      location:       data['location'] ?? '',
      category:       data['category'] ?? '',
      status:         status,
    );
  }

  // Giữ factory cũ (F hoa) để không breaking các chỗ khác chưa đổi
  factory ProductModel.FromFirestore(Map<String, dynamic> data, String id) =>
      ProductModel.fromFirestore(data, id);
}