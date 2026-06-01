import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_flutter/shared/models/user_profile.dart';

class ReviewModel {
  final String reviewId;
  final String reviewerId;
  final String sellerId;
  final String productId;
  final double rating;
  final String comment;
  final String time;

  UserProfile? reviewer;

  ReviewModel({
    required this.reviewId,
    required this.reviewerId,
    required this.sellerId,
    required this.productId,
    required this.rating,
    required this.comment,
    required this.time,
  });

  factory ReviewModel.fromFirestore(Map<String, dynamic> data, String id) {
    String parsedTime = '';
    var rawTime = data['time'];

    if (rawTime is Timestamp) {
      parsedTime = rawTime.toDate().toString(); // Chuẩn Firebase
    } else if (rawTime != null) {
      parsedTime = rawTime.toString(); // Đề phòng data rác lưu nhầm kiểu String
    } else {
      parsedTime = DateTime.now().toString(); // Phòng hờ null
    }

    return ReviewModel(
      reviewId: id,
      reviewerId: data['reviewerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      productId: data['productId'] ?? '',
      rating: (data['rating'] ?? 0)
          .toDouble(), // Xử lý int hay double đều nuốt được
      comment: data['comment'] ?? '',
      time: parsedTime, // Nhét cái time đã qua xử lý an toàn vào đây
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewerId': reviewerId,
      'sellerId': sellerId,
      'productId': productId,
      'rating': rating,
      'comment': comment,
      'time': FieldValue.serverTimestamp(),
    };
  }
}
