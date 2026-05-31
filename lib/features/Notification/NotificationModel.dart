import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId; // Người NHẬN thông báo
  final String title; // Tiêu đề: "Đơn hàng thành công!"
  final String body; // Nội dung chi tiết
  final String
  type; // Loại thông báo (order, review, system...) để biết đường chuyển trang
  final String
  relatedId; // ID của Đơn hàng hoặc ID của Review để click vào là nhảy đúng chỗ
  final bool isRead; // Trạng thái đã đọc hay chưa (để tắt cái chấm đỏ)
  final String createdAt; // Thời gian

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return NotificationModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'system',
      relatedId: data['relatedId'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] != null
          ? data['createdAt'].toDate().toString()
          : '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
