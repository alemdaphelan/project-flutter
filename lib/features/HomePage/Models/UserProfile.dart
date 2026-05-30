import 'package:project_flutter/features/HomePage/Models/Product.dart';

class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String location;
  final int totalReviews;
  final double averageRating;
  final String avatarUrl;
  final List<ProductModel> userPosts;
  UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.location,
    required this.totalReviews,
    required this.averageRating,
    required this.avatarUrl,
    this.userPosts = const [],
  });

  factory UserProfileModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserProfileModel(
      id: id,
      name: data['display_name'] ?? 'Unknown',
      email: data['email'] ?? 'Unknown',
      location: data['location'] ?? 'Unknown',
      totalReviews: data['totalReviews'] ?? 0,
      averageRating: (data['averageRating'] != null)
          ? (data['averageRating'] as num).toDouble()
          : 0.0,
      avatarUrl: data['avatarUrl'] ?? '',
    );
  }
}
