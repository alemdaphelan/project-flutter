import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_flutter/firestore_service.dart';
import 'package:project_flutter/features/Notification/NotificationModel.dart';
// KỸ SƯ IMPORT CÁC MÀN HÌNH ĐÍCH ĐỂ CHUYỂN HƯỚNG
import 'package:project_flutter/features/TinNhan/screens/chat_screen.dart';
import 'package:project_flutter/features/payment/screens/order_status_screen.dart';
import 'package:project_flutter/features/Review/ReviewScreen.dart';

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
        // 1. Cập nhật trạng thái "Đã đọc" tắt chấm đỏ
        if (!noti.isRead) {
          await _firestoreService.markNotificationAsRead(noti.id);
        }

        if (context.mounted) {
          switch (noti.type) {
            case NotificationType.chat:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatRoomId: noti.relatedId,
                    titleName: "Trò chuyện",
                  ),
                ),
              );
              break;
            case NotificationType.offer_received:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatRoomId: noti.relatedId,
                    titleName: "Thương lượng giá",
                  ),
                ),
              );
              break;
            case NotificationType.offer_accepted:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatRoomId: noti.relatedId,
                    titleName: "Chấp nhận thương lượng giá",
                  ),
                ),
              );
              break;
            case NotificationType.review:
              debugPrint(
                "Nhảy sang trang Review với sellerId: ${noti.relatedId}",
              );
              break;

            case NotificationType.order_purchased:
            case NotificationType.order_cancelled:
            case NotificationType.system:
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1B6B60)),
                ),
              );

              try {
                var orderSnap = await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(noti.relatedId)
                    .get();

                if (context.mounted) Navigator.pop(context);

                if (orderSnap.exists) {
                  bool iAmBuyer = orderSnap['buyerId'] == widget.userId;
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderStatusScreen(
                          orderId: noti.relatedId,
                          isBuyer: iAmBuyer,
                        ),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Rất tiếc, đơn hàng này không còn tồn tại!',
                        ),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) Navigator.pop(context);
              }
              break;
            case NotificationType.order_delivered:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SellerReviewsScreen(
                    sellerId: noti.relatedId,
                    currentUserId: widget.userId,
                  ),
                ),
              );
              break;
          }
        }
      },
      child: Container(
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

                  // ========================================================
                  // KỸ SƯ THÊM THẺ CHỨA NÚT ĐÁNH GIÁ KHI ĐƠN HÀNG ĐÃ GIAO
                  // ========================================================
                  if (noti.type == NotificationType.order_delivered)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.orange,
                            width: 1.2,
                          ),
                          minimumSize: const Size(135, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.orange.shade50,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SellerReviewsScreen(
                                sellerId: noti.relatedId,
                                currentUserId: widget.userId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.star_rounded,
                          color: Colors.orange,
                          size: 18,
                        ),
                        label: const Text(
                          'Đánh giá ngay',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // ========================================================
                ],
              ),
            ),
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

  Widget _buildNotificationIcon(NotificationType type, Color themeColor) {
    IconData iconData;
    Color bagColor;
    Color iconColor;

    switch (type) {
      case NotificationType.order_purchased:
        iconData = Icons.shopping_bag_outlined;
        bagColor = Colors.blue.shade100;
        iconColor = Colors.blue.shade700;
        break;
      case NotificationType.order_delivered:
        iconData = Icons.check_circle_outline;
        bagColor = Colors.green.shade100;
        iconColor = Colors.green.shade700;
        break;
      case NotificationType.order_cancelled:
        iconData = Icons.cancel_outlined;
        bagColor = Colors.red.shade100;
        iconColor = Colors.red.shade700;
        break;
      case NotificationType.offer_received:
      case NotificationType.offer_accepted:
        iconData = Icons.handshake_outlined;
        bagColor = Colors.orange.shade100;
        iconColor = Colors.orange.shade700;
        break;
      case NotificationType.review:
        iconData = Icons.star_outline;
        bagColor = Colors.amber.shade100;
        iconColor = Colors.amber.shade800;
        break;
      case NotificationType.chat:
        iconData = Icons.chat_bubble_outline;
        bagColor = Colors.purple.shade100;
        iconColor = Colors.purple.shade700;
        break;
      default:
        iconData = Icons.notifications_none;
        bagColor = Colors.grey.shade200;
        iconColor = Colors.grey.shade700;
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: bagColor,
      child: Icon(iconData, color: iconColor, size: 20),
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
