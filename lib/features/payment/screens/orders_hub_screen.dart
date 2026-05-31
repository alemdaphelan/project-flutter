import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_flutter/features/payment/models/OrderModel.dart';
import 'package:project_flutter/features/payment/services/OrderService.dart';
import 'order_status_screen.dart';

/// Màn hình "Đơn hàng" ở bottom nav
/// Tab 0: Đơn mua  (user là buyer)
/// Tab 1: Đơn bán  (user là seller)
class OrdersHubScreen extends StatefulWidget {
  const OrdersHubScreen({super.key});

  @override
  State<OrdersHubScreen> createState() => _OrdersHubScreenState();
}

class _OrdersHubScreenState extends State<OrdersHubScreen>
    with SingleTickerProviderStateMixin {
  final Color primaryTeal = const Color(0xFF1B6B60);
  late final TabController _tabController;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Đơn hàng',
          style: TextStyle(
              color: primaryTeal,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryTeal,
          indicatorWeight: 2.5,
          labelColor: primaryTeal,
          unselectedLabelColor: Colors.grey,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: [
            // Tab đơn mua — hiện badge nếu có đơn đang shipping
            _BadgeTab(
              label: 'Đơn mua',
              stream: OrderService().watchBuyerOrders(uid),
              // Badge khi có đơn đang giao (cần người mua confirm)
              badgeFilter: (o) => o.status == OrderStatus.shipping,
            ),
            // Tab đơn bán — badge khi có đơn chờ gửi hàng
            _BadgeTab(
              label: 'Đơn bán',
              stream: OrderService().watchSellerOrders(uid),
              badgeFilter: (o) => o.status == OrderStatus.pending,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrderList(
            stream: OrderService().watchBuyerOrders(uid),
            emptyMessage: 'Bạn chưa có đơn mua nào',
            emptyIcon: Icons.shopping_bag_outlined,
            isBuyer: true,
          ),
          _OrderList(
            stream: OrderService().watchSellerOrders(uid),
            emptyMessage: 'Bạn chưa có đơn bán nào',
            emptyIcon: Icons.storefront_outlined,
            isBuyer: false,
          ),
        ],
      ),
    );
  }
}

// ── Tab với badge số đỏ ──────────────────────────────────────────
class _BadgeTab extends StatelessWidget {
  final String label;
  final Stream<List<OrderModel>> stream;
  final bool Function(OrderModel) badgeFilter;

  const _BadgeTab({
    required this.label,
    required this.stream,
    required this.badgeFilter,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: stream,
      builder: (context, snap) {
        final count =
            snap.data?.where(badgeFilter).length ?? 0;
        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Danh sách đơn hàng (dùng chung cho cả 2 tab) ─────────────────
class _OrderList extends StatelessWidget {
  final Stream<List<OrderModel>> stream;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool isBuyer;

  const _OrderList({
    required this.stream,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.isBuyer,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Hiện lỗi thật để debug — thường là Firestore index hoặc rules
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Lỗi tải đơn hàng:\n\${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final orders = snap.data ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(emptyIcon, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(emptyMessage,
                    style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          itemCount: orders.length,
          itemBuilder: (_, i) => _OrderCard(order: orders[i], isBuyer: isBuyer),
        );
      },
    );
  }
}

// ── Card 1 đơn hàng ──────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool isBuyer;
  const _OrderCard({required this.order, required this.isBuyer});

  @override
  Widget build(BuildContext context) {
    final Color primaryTeal = const Color(0xFF1B6B60);
    final status = order.status;
    final needsAction = status == OrderStatus.pending ||
        status == OrderStatus.shipping;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderStatusScreen(orderId: order.id, isBuyer: isBuyer),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: needsAction
                ? primaryTeal.withOpacity(0.3)
                : Colors.transparent,
          ),
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
            // Header: status + thời gian
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusBadge(status: status),
                  Text(
                    _formatDate(order.createdAt),
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
            ),

            // Body: ảnh + thông tin
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Ảnh sản phẩm
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      order.productImageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
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
                        Text(
                          order.productName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.price.toStringAsFixed(0)} VNĐ',
                          style: TextStyle(
                              color: primaryTeal,
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.paymentMethod == 'COD'
                              ? 'Thanh toán khi nhận hàng'
                              : 'Chuyển khoản ngân hàng',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: Colors.grey, size: 20),
                ],
              ),
            ),

            // Footer: địa chỉ giao + tracking nếu có
            if (order.trackingNumber.isNotEmpty ||
                order.deliveryAddress.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    if (order.trackingNumber.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.local_shipping_outlined,
                              size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            '${order.carrierName}  ${order.trackingNumber}',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.deliveryAddress,
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Badge trạng thái ─────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, icon, bg, fg) = switch (status) {
      OrderStatus.pending => (
          'Chờ gửi hàng',
          Icons.hourglass_top_rounded,
          Colors.orange.shade50,
          Colors.orange.shade700
        ),
      OrderStatus.shipping => (
          'Đang giao',
          Icons.local_shipping_outlined,
          const Color(0xFFE8F1F0),
          const Color(0xFF1B6B60)
        ),
      OrderStatus.completed => (
          'Hoàn thành',
          Icons.check_circle_outline,
          Colors.green.shade50,
          Colors.green.shade700
        ),
      OrderStatus.cancelled => (
          'Đã hủy',
          Icons.cancel_outlined,
          Colors.red.shade50,
          Colors.red.shade700
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: fg),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
              color: fg, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}