import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  chat, // Có tin nhắn mới
  offer_received, // Có người mặc cả / trả giá
  offer_accepted, // Người bán đồng ý bán với giá mày trả
  review, // Có người đánh giá
  order_purchased, // Đơn hàng vừa được đặt
  order_delivered, // Đơn hàng đã giao thành công
  order_cancelled, // Đơn hàng bị hủy
  system, // Thông báo hệ thống (bảo trì, khuyến mãi...)
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;

  final NotificationType type;

  final String relatedId;
  final bool isRead;
  final String createdAt;

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
    String typeString = data['type'] ?? '';
    NotificationType parsedType = NotificationType.system;

    for (var t in NotificationType.values) {
      if (t.name == typeString) {
        parsedType = t;
        break;
      }
    }
    String formattedTime = '';
    var rawTimestamp = data['createdAt'];
    if (rawTimestamp != null && rawTimestamp is Timestamp) {
      formattedTime = rawTimestamp.toDate().toString();
    } else {
      formattedTime = DateTime.now().toString();
    }

    return NotificationModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: parsedType,
      relatedId: data['relatedId'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: formattedTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,

      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
