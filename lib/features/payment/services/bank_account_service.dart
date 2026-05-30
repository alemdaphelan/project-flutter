import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_flutter/shared/models/bank_account.dart';

class BankAccountService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection path: users/{userId}/bankAccounts  (subcollection)
  CollectionReference _col(String userId) =>
      _db.collection('users').doc(userId).collection('bankAccounts');

  /// Lấy tất cả tài khoản của user (realtime stream)
  Stream<List<BankAccount>> watchAccounts(String userId) {
    return _col(userId).snapshots().map((snap) => snap.docs
        .map((d) => BankAccount.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  /// Lấy tài khoản mặc định (isPrimary = true)
  Future<BankAccount?> getPrimaryAccount(String userId) async {
    final snap = await _col(userId)
        .where('isPrimary', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return BankAccount.fromMap(
        snap.docs.first.data() as Map<String, dynamic>, snap.docs.first.id);
  }

  /// Thêm tài khoản mới
  Future<void> addAccount(BankAccount account) async {
    // Nếu đây là tài khoản đầu tiên → tự động set isPrimary
    final existing = await _col(account.userId).limit(1).get();
    final shouldBePrimary = existing.docs.isEmpty || account.isPrimary;

    // Nếu set primary → bỏ primary của tài khoản cũ
    if (shouldBePrimary) {
      await _clearPrimary(account.userId);
    }

    await _col(account.userId)
        .add(account.copyWith(isPrimary: shouldBePrimary).toMap());
  }

  /// Đặt làm tài khoản mặc định
  Future<void> setPrimary(String userId, String accountId) async {
    await _clearPrimary(userId);
    await _col(userId).doc(accountId).update({'isPrimary': true});
  }

  /// Xóa tài khoản
  Future<void> deleteAccount(String userId, String accountId) async {
    await _col(userId).doc(accountId).delete();
  }

  // --- Private ---
  Future<void> _clearPrimary(String userId) async {
    final snap =
        await _col(userId).where('isPrimary', isEqualTo: true).get();
    for (final doc in snap.docs) {
      await doc.reference.update({'isPrimary': false});
    }
  }
}