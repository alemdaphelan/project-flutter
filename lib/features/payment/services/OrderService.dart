import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_flutter/features/payment/models/OrderModel.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('orders');

  /// Tạo đơn hàng mới, trả về orderId
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

  /// Người bán cập nhật đơn vị vận chuyển + mã vận đơn → chuyển sang shipping
  Future<void> confirmShipping(String orderId, {
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

  /// Người mua xác nhận đã nhận hàng → hoàn thành
  Future<void> confirmReceived(String orderId) {
    return _col.doc(orderId).update({
      'status': OrderStatus.completed.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Danh sách đơn của buyer — sort ở client, không cần Composite Index
  Stream<List<OrderModel>> watchBuyerOrders(String buyerId) {
    return _col
        .where('buyerId', isEqualTo: buyerId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => OrderModel.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Danh sách đơn của seller — sort ở client, không cần Composite Index
  Stream<List<OrderModel>> watchSellerOrders(String sellerId) {
    return _col
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => OrderModel.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }
}