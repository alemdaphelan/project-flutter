import 'package:project_flutter/shared/models/user_profile.dart';
class ProductModel {
  final String sellerId;
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
    required this.time,
    required this.productImageUrl,
    required this.productName,
    required this.price,
    required this.specifications,
    required this.description,
    required this.location,
    required this.category,
  });

  factory ProductModel.FromFirestore(Map<String, dynamic> data, String id) {
    return ProductModel(
      sellerId: data['sellerId'] ?? '',
      time: data['time'].toDate().toString(),
      productImageUrl: data['image'] ?? '',
      productName: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      specifications: data['fields'] ?? {},
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      category: data['category'] ?? '',
    );
  }
}
