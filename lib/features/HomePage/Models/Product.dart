import 'package:project_flutter/features/HomePage/Models/UserProfile.dart';

class ProductModel {
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

  UserProfileModel? seller;

  ProductModel({
    required this.sellerId,
    required this.sellerName,
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
      sellerName: data['sellerName'] ?? 'Người bán',
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