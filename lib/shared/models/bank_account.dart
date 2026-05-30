import 'package:cloud_firestore/cloud_firestore.dart';

class BankAccount {
  final String id;           // doc ID trên Firestore
  final String userId;       // FK → UserProfile.uid  (quan hệ nhiều-một)
  final String bankId;       // Mã ngân hàng VietQR, vd: "970422" (MB)
  final String bankName;     // Tên hiển thị, vd: "MB Bank"
  final String accountNo;    // Số tài khoản
  final String accountName;  // Tên chủ tài khoản (in hoa)
  final bool isPrimary;      // Tài khoản mặc định khi nhận thanh toán
  final DateTime? createdAt;

  BankAccount({
    required this.id,
    required this.userId,
    required this.bankId,
    required this.bankName,
    required this.accountNo,
    required this.accountName,
    this.isPrimary = false,
    this.createdAt,
  });

  // Firestore path: users/{userId}/bankAccounts/{id}
  factory BankAccount.fromMap(Map<String, dynamic> map, String id) {
    return BankAccount(
      id: id,
      userId: map['userId'] as String,
      bankId: map['bankId'] as String,
      bankName: map['bankName'] as String,
      accountNo: map['accountNo'] as String,
      accountName: map['accountName'] as String,
      isPrimary: map['isPrimary'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bankId': bankId,
      'bankName': bankName,
      'accountNo': accountNo,
      'accountName': accountName,
      'isPrimary': isPrimary,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Tạo URL VietQR động từ thông tin tài khoản
  String vietQrUrl({required int amount, String? description}) {
    final desc = Uri.encodeComponent(description ?? 'Thanh toan Oldie');
    return 'https://img.vietqr.io/image/$bankId-$accountNo-compact.png'
        '?amount=$amount'
        '&addInfo=$desc'
        '&accountName=${Uri.encodeComponent(accountName)}';
  }

  BankAccount copyWith({
    String? bankId,
    String? bankName,
    String? accountNo,
    String? accountName,
    bool? isPrimary,
  }) {
    return BankAccount(
      id: id,
      userId: userId,
      bankId: bankId ?? this.bankId,
      bankName: bankName ?? this.bankName,
      accountNo: accountNo ?? this.accountNo,
      accountName: accountName ?? this.accountName,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt,
    );
  }
}

/// Danh sách ngân hàng phổ biến tại VN để hiện dropdown
class VietnamBank {
  final String id;
  final String name;
  const VietnamBank({required this.id, required this.name});

  static const List<VietnamBank> popular = [
    VietnamBank(id: '970422', name: 'MB Bank'),
    VietnamBank(id: '970436', name: 'Vietcombank'),
    VietnamBank(id: '970415', name: 'Vietinbank'),
    VietnamBank(id: '970418', name: 'BIDV'),
    VietnamBank(id: '970407', name: 'Techcombank'),
    VietnamBank(id: '970432', name: 'VPBank'),
    VietnamBank(id: '970423', name: 'TPBank'),
    VietnamBank(id: '970406', name: 'Sacombank'),
    VietnamBank(id: '970426', name: 'MSB'),
    VietnamBank(id: '970443', name: 'SHB'),
  ];
}