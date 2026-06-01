import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_flutter/features/HomePage/Models/Product.dart';

class ListingService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('listings');

  /// Người bán tự cập nhật trạng thái listing
  Future<void> updateStatus(String productId, ListingStatus status) {
    return _col.doc(productId).update({'status': status.name});
  }

  /// Lấy stream các listing của 1 seller để quản lý
  Stream<List<ProductModel>> watchSellerListings(String sellerId) {
    return _col
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ProductModel.fromFirestore(
                d.data() as Map<String, dynamic>, d.id))
            .toList());
  }
}