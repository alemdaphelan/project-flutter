import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_flutter/features/HomePage/Models/Product.dart';
import 'package:project_flutter/features/payment/services/listing_service.dart';

/// Màn hình người bán quản lý trạng thái các listing của mình
/// Vào từ: UserProfile hoặc menu trong ProductCard khi isOwner
class ManageListingScreen extends StatelessWidget {
  const ManageListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryTeal = const Color(0xFF1B6B60);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Tin đăng của tôi',
            style: TextStyle(
                color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: ListingService().watchSellerListings(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Lỗi: ${snap.error}'));
          }
          final listings = snap.data ?? [];
          if (listings.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Bạn chưa đăng bán sản phẩm nào',
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          // Sắp xếp: available → reserved → sold
          final sorted = [...listings]..sort((a, b) =>
              a.status.index.compareTo(b.status.index));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            itemBuilder: (_, i) => _ListingManageCard(product: sorted[i]),
          );
        },
      ),
    );
  }
}

class _ListingManageCard extends StatelessWidget {
  final ProductModel product;
  const _ListingManageCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final Color primaryTeal = const Color(0xFF1B6B60);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Info row ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.productImageUrl,
                    width: 64, height: 64, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64, height: 64,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.productName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(
                        '${product.price.toStringAsFixed(0)} VNĐ',
                        style: TextStyle(
                            color: primaryTeal,
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: product.status),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Action buttons ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: _buildActions(context, primaryTeal),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, Color primaryTeal) {
    final service = ListingService();

    switch (product.status) {
      case ListingStatus.available:
        // Chỉ có thể đánh dấu đã bán
        return Row(
          children: [
            const Spacer(),
            _actionBtn(
              label: 'Đánh dấu đã bán',
              icon: Icons.sell_outlined,
              color: Colors.red.shade400,
              onTap: () => _confirm(
                context,
                title: 'Đánh dấu đã bán?',
                content:
                    'Sản phẩm sẽ bị ẩn khỏi danh sách tìm kiếm.',
                onConfirm: () =>
                    service.updateStatus(product.id, ListingStatus.sold),
              ),
            ),
          ],
        );

      case ListingStatus.reserved:
        // Đang có đơn chờ — người bán chọn: vẫn còn hàng hay đã bán
        return Row(
          children: [
            Expanded(
              child: _actionBtn(
                label: 'Vẫn còn hàng',
                icon: Icons.refresh,
                color: primaryTeal,
                outlined: true,
                onTap: () => _confirm(
                  context,
                  title: 'Đặt lại thành "Còn hàng"?',
                  content:
                      'Sản phẩm sẽ hiện lại cho người mua khác tìm kiếm.',
                  onConfirm: () => service.updateStatus(
                      product.id, ListingStatus.available),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                label: 'Xác nhận đã bán',
                icon: Icons.check_circle_outline,
                color: Colors.red.shade400,
                onTap: () => _confirm(
                  context,
                  title: 'Xác nhận đã bán?',
                  content: 'Sản phẩm sẽ bị ẩn khỏi danh sách.',
                  onConfirm: () =>
                      service.updateStatus(product.id, ListingStatus.sold),
                ),
              ),
            ),
          ],
        );

      case ListingStatus.sold:
        // Đã bán — có thể đăng lại nếu còn hàng
        return Row(
          children: [
            const Spacer(),
            _actionBtn(
              label: 'Đăng lại',
              icon: Icons.replay,
              color: Colors.orange.shade700,
              outlined: true,
              onTap: () => _confirm(
                context,
                title: 'Đăng lại sản phẩm?',
                content:
                    'Sản phẩm sẽ hiện lại cho người mua tìm kiếm.',
                onConfirm: () => service.updateStatus(
                    product.id, ListingStatus.available),
              ),
            ),
          ],
        );
    }
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    final style = outlined
        ? OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          );

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );

    return outlined
        ? OutlinedButton(onPressed: onTap, style: style, child: child)
        : ElevatedButton(onPressed: onTap, style: style, child: child);
  }

  void _confirm(
    BuildContext context, {
    required String title,
    required String content,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ListingStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      ListingStatus.available => ('Còn hàng', Colors.green.shade50,  Colors.green.shade700),
      ListingStatus.reserved  => ('Đang đặt', Colors.orange.shade50, Colors.orange.shade700),
      ListingStatus.sold      => ('Đã bán',   Colors.red.shade50,    Colors.red.shade700),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}