import 'package:project_flutter/shared/models/user_profile.dart';

class ProductModel {
  final String sellerId;
  final String sellerName; // thêm field này
  final String time;
  final String productImageUrl;
  final String productName;
  final double price;
  final Map<String, dynamic> specifications;
  final String description;
  final String location;
  final String category;

  UserProfile? seller;

  ProductModel({
    required this.sellerId,
    this.sellerName = '',   // optional, default rỗng
    required this.time,
    required this.productImageUrl,
    required this.productName,
    required this.price,
    required this.specifications,
    required this.description,
    required this.location,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'image': productImageUrl,
      'name': productName,
      'price': price,
      'fields': specifications,
      'description': description,
      'location': location,
      'category': category,
      'time': DateTime.now(),
    };
  }

  // Đổi F hoa → f thường để đúng convention Dart
  factory ProductModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ProductModel(
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      time: data['time'] != null
          ? data['time'].toDate().toString()
          : DateTime.now().toString(),
      productImageUrl: data['image'] ?? '',
      productName: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      specifications: Map<String, dynamic>.from(data['fields'] ?? {}),
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      category: data['category'] ?? '',
    );
  }
}