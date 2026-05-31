import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_flutter/firestore_service.dart';
import 'package:project_flutter/features/Notification/NotificationModel.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;

  const NotificationScreen({super.key, required this.userId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF1B6B60);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F7),
      appBar: AppBar(
        title: const Text(
          'Thông báo của tôi',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Mở đường ống hút data real-time từ Firebase
        stream: _firestoreService.getNotificationsStream(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryTeal),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('❌ Lỗi tải thông báo: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Dịch data từ Firebase thành List Object Model
          List<NotificationModel> notifications = snapshot.data!.docs.map((
            doc,
          ) {
            return NotificationModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final noti = notifications[index];
              return _buildNotificationItem(noti, primaryTeal);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel noti, Color themeColor) {
    return InkWell(
      onTap: () async {
        // TƯ DUY KỸ SƯ: Bấm vào là cập nhật trạng thái "Đã đọc" ngay lập tức trên Database
        if (!noti.isRead) {
          await _firestoreService.markNotificationAsRead(noti.id);
        }

        // Logic điều hướng (Tạm thời in ra console, sau này mày gắn Navigator.push vào đây)
        if (context.mounted) {
          if (noti.type == 'review') {
            debugPrint("👉 Nhảy sang trang review với ID: ${noti.relatedId}");
          } else if (noti.type == 'order') {
            debugPrint("👉 Nhảy sang trang đơn hàng với ID: ${noti.relatedId}");
          }
        }
      },
      child: Container(
        // Đổi màu nền để phân biệt Đọc (trắng) và Chưa đọc (xanh nhạt)
        color: noti.isRead ? Colors.white : const Color(0xFFEAF4F2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationIcon(noti.type, themeColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    noti.title,
                    style: TextStyle(
                      fontWeight: noti.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    noti.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: noti.isRead
                          ? Colors.grey.shade600
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    noti.createdAt.isNotEmpty
                        ? noti.createdAt.split('.')[0]
                        : '',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            // Vẽ cái chấm đỏ huyền thoại
            if (!noti.isRead)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type, Color themeColor) {
    IconData iconData;
    Color bagColor;

    switch (type) {
      case 'order':
        iconData = Icons.local_shipping_outlined;
        bagColor = Colors.orange.shade100;
        break;
      case 'review':
        iconData = Icons.star_outline;
        bagColor = Colors.amber.shade100;
        break;
      default:
        iconData = Icons.campaign_outlined;
        bagColor = themeColor.withOpacity(0.1);
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: bagColor,
      child: Icon(iconData, color: themeColor, size: 20),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Hộp thư trống trơn',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
