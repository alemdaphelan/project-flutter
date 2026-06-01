/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:project_flutter/features/payment/models/OrderModel.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('orders');
  CollectionReference get _listings => _db.collection('listings');

  /// Tạo đơn hàng mới — KHÔNG tự động đổi status listing
  /// Người bán tự quyết qua ManageListingScreen
  Future<String> createOrder(OrderModel order) async {
    final ref = await _col.add(order.toMap());

    return ref.id;
  }

  /// Lắng nghe realtime 1 đơn hàng — cả buyer lẫn seller dùng chung
  Stream<OrderModel?> watchOrder(String orderId) {
    return _col.doc(orderId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return OrderModel.fromMap(snap.data() as Map<String, dynamic>, snap.id);
    });
  }

  /// Người bán xác nhận gửi hàng → shipping
  Future<void> confirmShipping(
    String orderId, {
    required String carrierName,
    required String trackingNumber,
  }) {
    return _col.doc(orderId).update({
      'carrierName': carrierName,
      'trackingNumber': trackingNumber,
      'status': OrderStatus.shipping.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Người mua xác nhận đã nhận hàng → completed
  /// KHÔNG tự động set listing "sold" — người bán tự quyết qua ManageListingScreen
  Future<void> confirmReceived(String orderId) async {
    await _col.doc(orderId).update({
      'status': OrderStatus.completed.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Hủy đơn → trả listing về "available"
  Future<void> cancelOrder(String orderId) async {
    final snap = await _col.doc(orderId).get();
    final data = snap.data() as Map<String, dynamic>?;
    final productId = data?['productId'] as String? ?? '';

    await _col.doc(orderId).update({
      'status': OrderStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (productId.isNotEmpty) {
      await _listings.doc(productId).update({'status': 'available'});
    }
  }

  /// Danh sách đơn của buyer
  Stream<List<OrderModel>> watchBuyerOrders(String buyerId) {
    return _col.where('buyerId', isEqualTo: buyerId).snapshots().map((s) {
      final list = s.docs
          .map(
            (d) => OrderModel.fromMap(d.data() as Map<String, dynamic>, d.id),
          )
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Danh sách đơn của seller
  Stream<List<OrderModel>> watchSellerOrders(String sellerId) {
    return _col.where('sellerId', isEqualTo: sellerId).snapshots().map((s) {
      final list = s.docs
          .map(
            (d) => OrderModel.fromMap(d.data() as Map<String, dynamic>, d.id),
          )
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}

*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_flutter/features/payment/models/OrderModel.dart';

import 'package:project_flutter/firestore_service.dart';
import 'package:project_flutter/features/Notification/NotificationModel.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('orders');
  CollectionReference get _listings => _db.collection('listings');

  final FirestoreService _notiService = FirestoreService();

  Future<String> createOrder(OrderModel order) async {
    final ref = await _col.add(order.toMap());

    await _notiService.triggerNotification(
      receiverId: order.sellerId,
      title: 'Đơn hàng mới! 💸',
      body: 'Khách vừa chốt đơn món "${order.productName}". Chuẩn bị hàng nhé!',
      type: NotificationType.order_purchased,
      relatedId: ref.id, // Bấm vào nhảy qua OrderStatusScreen của ID này
    );
    // ========================================================

    return ref.id;
  }

  Stream<OrderModel?> watchOrder(String orderId) {
    return _col.doc(orderId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return OrderModel.fromMap(snap.data() as Map<String, dynamic>, snap.id);
    });
  }

  Future<void> confirmShipping(
    String orderId, {
    required String carrierName,
    required String trackingNumber,
  }) async {
    await _col.doc(orderId).update({
      'carrierName': carrierName,
      'trackingNumber': trackingNumber,
      'status': OrderStatus.shipping.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final snap = await _col.doc(orderId).get();
    final data = snap.data() as Map<String, dynamic>?;
    if (data != null) {
      await _notiService.triggerNotification(
        receiverId: data['buyerId'], // Bắn cho thằng mua
        title: 'Đơn hàng đang giao 🚚',
        body: 'Món "${data['productName']}" đã được bàn giao cho $carrierName.',
        type: NotificationType.system, // Xài tạm type system cho báo đang giao
        relatedId: orderId,
      );
    }
  }

  Future<void> confirmReceived(String orderId) async {
    await _col.doc(orderId).update({
      'status': OrderStatus.completed.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final snap = await _col.doc(orderId).get();
    final data = snap.data() as Map<String, dynamic>?;

    if (data != null) {
      await _notiService.triggerNotification(
        receiverId: data['sellerId'],
        title: 'Giao dịch hoàn tất! 🎉',
        body: 'Khách hàng đã xác nhận nhận được món "${data['productName']}".',
        type: NotificationType.system,
        relatedId: orderId,
      );
      await _notiService.triggerNotification(
        receiverId: data['buyerId'],
        title: 'Giao hàng thành công! 📦',
        body:
            'Bạn đã nhận được "${data['productName']}". Bấm vào đây để đánh giá người bán ngay nhé!',
        type: NotificationType.order_delivered,
        relatedId: data['sellerId'],
      );
    }
  }

  Future<void> cancelOrder(String orderId) async {
    final snap = await _col.doc(orderId).get();
    final data = snap.data() as Map<String, dynamic>?;
    final productId = data?['productId'] as String? ?? '';

    await _col.doc(orderId).update({
      'status': OrderStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (productId.isNotEmpty) {
      await _listings.doc(productId).update({'status': 'available'});
    }
    if (data != null) {
      String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      String targetReceiverId = (currentUserId == data['buyerId'])
          ? data['sellerId']
          : data['buyerId'];

      await _notiService.triggerNotification(
        receiverId: targetReceiverId,
        title: 'Đơn hàng đã bị hủy ❌',
        body: 'Giao dịch cho món "${data['productName']}" đã bị hủy.',
        type: NotificationType.order_cancelled,
        relatedId: orderId,
      );
    }
    // ========================================================
  }

  /// Danh sách đơn của buyer
  Stream<List<OrderModel>> watchBuyerOrders(String buyerId) {
    return _col.where('buyerId', isEqualTo: buyerId).snapshots().map((s) {
      final list = s.docs
          .map(
            (d) => OrderModel.fromMap(d.data() as Map<String, dynamic>, d.id),
          )
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Danh sách đơn của seller
  Stream<List<OrderModel>> watchSellerOrders(String sellerId) {
    return _col.where('sellerId', isEqualTo: sellerId).snapshots().map((s) {
      final list = s.docs
          .map(
            (d) => OrderModel.fromMap(d.data() as Map<String, dynamic>, d.id),
          )
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
