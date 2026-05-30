import 'package:flutter/material.dart';
import 'package:project_flutter/shared/models/bank_account.dart';

class BankAccountCard extends StatelessWidget {
  final BankAccount account;
  final VoidCallback? onSetPrimary;
  final VoidCallback? onDelete;

  const BankAccountCard({
    super.key,
    required this.account,
    this.onSetPrimary,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryTeal = const Color(0xFF1B6B60);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: account.isPrimary
            ? const Color(0xFFE8F1F0)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: account.isPrimary ? primaryTeal : Colors.grey.shade200,
          width: account.isPrimary ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icon ngân hàng
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.account_balance, color: primaryTeal, size: 22),
          ),
          const SizedBox(width: 12),

          // Thông tin tài khoản
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      account.bankName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (account.isPrimary) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryTeal,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Mặc định',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  account.accountNo,
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      letterSpacing: 1),
                ),
                Text(
                  account.accountName,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Action menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
            onSelected: (val) {
              if (val == 'primary') onSetPrimary?.call();
              if (val == 'delete') onDelete?.call();
            },
            itemBuilder: (_) => [
              if (!account.isPrimary)
                const PopupMenuItem(
                  value: 'primary',
                  child: Row(
                    children: [
                      Icon(Icons.star_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Đặt làm mặc định'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}