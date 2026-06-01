import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:project_flutter/features/payment/models/OrderModel.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('orders');
  CollectionReference get _listings => _db.collection('listings');

  /// Tạo đơn hàng mới → đánh dấu listing là "reserved"
  Future<String> createOrder(OrderModel order) async {
    final ref = await _col.add(order.toMap());

    // Bọc riêng — lỗi update status không nên block việc tạo đơn
    if (order.productId.isNotEmpty) {
      try {
        await _listings.doc(order.productId).update({'status': 'reserved'});
      } catch (e) {
        debugPrint('Cảnh báo: không update được status listing - $e');
        // Không rethrow — đơn hàng vẫn được tạo thành công
      }
    }

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

  /// Người mua xác nhận đã nhận hàng → completed + listing "sold"
  Future<void> confirmReceived(String orderId) async {
    final snap = await _col.doc(orderId).get();
    final data = snap.data() as Map<String, dynamic>?;
    final productId = data?['productId'] as String? ?? '';

    await _col.doc(orderId).update({
      'status': OrderStatus.completed.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (productId.isNotEmpty) {
      await _listings.doc(productId).update({'status': 'sold'});
    }
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
