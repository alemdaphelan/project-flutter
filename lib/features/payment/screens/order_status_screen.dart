import 'package:flutter/material.dart';
import 'package:project_flutter/features/payment/models/OrderModel.dart';
import 'package:project_flutter/features/payment/services/OrderService.dart';

/// Màn hình theo dõi đơn hàng — realtime từ Firestore
/// Cả buyer và seller cùng nhìn vào 1 orderId → trạng thái đồng bộ
class OrderStatusScreen extends StatefulWidget {
  final String orderId;
  final bool isBuyer;

  const OrderStatusScreen({
    super.key,
    required this.orderId,
    required this.isBuyer,
  });

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  final Color primaryTeal = const Color(0xFF1B6B60);
  final Color lightTeal = const Color(0xFFE8F1F0);
  final _orderService = OrderService();
  final _trackingCtrl = TextEditingController();
  final _carrierCtrl = TextEditingController();
  String? _trackingError;
  String? _carrierError;
  bool _isActing = false;
  bool _expandBuyerInfo = false;  // ← NEW: Collapse/expand buyer info

  @override
  void dispose() {
    _trackingCtrl.dispose();
    _carrierCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OrderModel?>(
      stream: _orderService.watchOrder(widget.orderId),
      builder: (context, snap) {
        // Loading
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Lỗi hoặc không tìm thấy đơn
        if (!snap.hasData || snap.data == null) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: const Center(child: Text('Không tìm thấy đơn hàng')),
          );
        }

        final order = snap.data!;
        final step = order.status.stepIndex;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              // ── Thông tin sản phẩm ──
              _buildOrderSummary(order),

              // ── Mã vận đơn (chỉ hiện khi đã có) ──
              if (order.trackingNumber.isNotEmpty)
                _buildTrackingCard(order),

              // ── Stepper trạng thái ──
              Expanded(child: _buildStepper(step)),

              // ── Hành động theo role + trạng thái ──
              _buildActionPanel(order),
            ],
          ),
        );
      },
    );
  }

  // ── Tóm tắt đơn hàng (sản phẩm + thông tin buyer) ──
  Widget _buildOrderSummary(OrderModel order) {
    return Column(
      children: [
        // ── Card sản phẩm ──
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: lightTeal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Ảnh sản phẩm
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  order.productImageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.shade200,
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
                    Text(order.productName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${order.price.toStringAsFixed(0)} VNĐ  •  ${order.paymentMethod}',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '📦 ${order.deliveryAddress}',
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Card thông tin người mua (collapsible) ──
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: BoxDecoration(
            color: lightTeal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // ── Header (expandable) ──
              GestureDetector(
                onTap: () => setState(() => _expandBuyerInfo = !_expandBuyerInfo),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: primaryTeal,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'THÔNG TIN GIAO HÀNG',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryTeal,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.receiverName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _expandBuyerInfo
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: primaryTeal,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content (expanded) ──
              if (_expandBuyerInfo)
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Divider
                      Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                        height: 16,
                      ),

                      // Tên người nhận
                      _buildBuyerInfoRow(
                        icon: '👤',
                        label: 'Người nhận',
                        value: order.receiverName,
                      ),
                      const SizedBox(height: 12),

                      // SĐT
                      _buildBuyerInfoRow(
                        icon: '📱',
                        label: 'Số điện thoại',
                        value: order.receiverPhone,
                      ),
                      const SizedBox(height: 12),

                      // Địa chỉ đầy đủ
                      _buildBuyerInfoRow(
                        icon: '📍',
                        label: 'Địa chỉ giao hàng',
                        value: order.deliveryAddress,
                        multiline: true,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Helper: Dòng thông tin người mua
  Widget _buildBuyerInfoRow({
    required String icon,
    required String label,
    required String value,
    bool multiline = false,
  }) {
    return Row(
      crossAxisAlignment:
          multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
                maxLines: multiline ? null : 1,
                overflow: multiline ? TextOverflow.clip : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Card mã vận đơn ──
  Widget _buildTrackingCard(OrderModel order) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: primaryTeal.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping_outlined, color: primaryTeal, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên đơn vị vận chuyển
                if (order.carrierName.isNotEmpty)
                  Text(
                    order.carrierName,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: primaryTeal,
                        fontSize: 13),
                  ),
                // Mã vận đơn
                Row(
                  children: [
                    Text('Mã vận đơn: ',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                    Text(
                      order.trackingNumber,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stepper ──
  Widget _buildStepper(int currentStep) {
    final steps = [
      _StepData('Đang xử lý', 'Người bán đang chuẩn bị hàng'),
      _StepData('Đang giao hàng', 'Hàng đã được giao cho đơn vị vận chuyển'),
      _StepData('Hoàn thành', 'Giao dịch thành công'),
    ];

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.light(primary: primaryTeal),
      ),
      child: Stepper(
        type: StepperType.vertical,
        currentStep: currentStep,
        controlsBuilder: (_, __) => const SizedBox.shrink(),
        steps: steps.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          return Step(
            title: Text(
              s.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: currentStep >= i ? primaryTeal : Colors.grey,
              ),
            ),
            subtitle: Text(s.subtitle,
                style: TextStyle(color: Colors.grey.shade600)),
            content: const SizedBox.shrink(),
            isActive: currentStep >= i,
            state: currentStep > i
                ? StepState.complete
                : StepState.indexed,
          );
        }).toList(),
      ),
    );
  }

  // ── Panel hành động ──
  Widget _buildActionPanel(OrderModel order) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRoleAction(order),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryTeal),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () =>
                  Navigator.popUntil(context, (r) => r.isFirst),
              icon: Icon(Icons.home_outlined, color: primaryTeal),
              label: Text('VỀ TRANG CHỦ',
                  style: TextStyle(
                      color: primaryTeal, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleAction(OrderModel order) {
    // ── NGƯỜI BÁN ──
    if (!widget.isBuyer) {
      switch (order.status) {
        case OrderStatus.pending:
          // Người bán nhập tên ĐVVC + mã vận đơn để chuyển trạng thái
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('THÔNG TIN VẬN CHUYỂN',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.1)),
              const SizedBox(height: 10),

              // Dropdown gợi ý ĐVVC phổ biến
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Đơn vị vận chuyển',
                  errorText: _carrierError,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: Icon(Icons.local_shipping_outlined,
                      color: primaryTeal, size: 20),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryTeal, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                value: _carrierCtrl.text.isEmpty ? null : _carrierCtrl.text,
                items: const [
                  DropdownMenuItem(value: 'GHTK', child: Text('Giao Hàng Tiết Kiệm (GHTK)')),
                  DropdownMenuItem(value: 'GHN', child: Text('Giao Hàng Nhanh (GHN)')),
                  DropdownMenuItem(value: 'ViettelPost', child: Text('Viettel Post')),
                  DropdownMenuItem(value: 'VNPost', child: Text('Vietnam Post (VNPost)')),
                  DropdownMenuItem(value: 'J&T Express', child: Text('J&T Express')),
                  DropdownMenuItem(value: 'Ninja Van', child: Text('Ninja Van')),
                  DropdownMenuItem(value: 'Khác', child: Text('Khác...')),
                ],
                onChanged: (val) {
                  setState(() {
                    _carrierCtrl.text = val ?? '';
                    _carrierError = null;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Nếu chọn "Khác" → cho nhập tay
              if (_carrierCtrl.text == 'Khác')
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    onChanged: (val) => setState(() => _carrierCtrl.text = val),
                    decoration: InputDecoration(
                      hintText: 'Nhập tên đơn vị vận chuyển',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryTeal, width: 2),
                      ),
                    ),
                  ),
                ),

              // Mã vận đơn
              TextField(
                controller: _trackingCtrl,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Mã vận đơn',
                  hintText: 'Ví dụ: GHTK_123456789',
                  errorText: _trackingError,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: Icon(Icons.qr_code_scanner,
                      color: primaryTeal, size: 20),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryTeal, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _actionButton('XÁC NHẬN ĐÃ GỬI HÀNG', primaryTeal, () async {
                final carrier = _carrierCtrl.text.trim();
                final code = _trackingCtrl.text.trim();
                // Validate cả 2 field
                setState(() {
                  _carrierError = carrier.isEmpty ? 'Chọn đơn vị vận chuyển' : null;
                  _trackingError = code.isEmpty ? 'Nhập mã vận đơn' : null;
                });
                if (carrier.isEmpty || code.isEmpty) return;
                setState(() => _isActing = true);
                await _orderService.confirmShipping(
                  widget.orderId,
                  carrierName: carrier,
                  trackingNumber: code,
                );
                if (mounted) setState(() => _isActing = false);
              }),
            ],
          );

        case OrderStatus.shipping:
          return Center(
            child: Text('Chờ khách hàng xác nhận đã nhận hàng...',
                style: TextStyle(
                    fontStyle: FontStyle.italic, color: primaryTeal)),
          );

        case OrderStatus.completed:
          return _successBadge('✅ KHÁCH HÀNG ĐÃ XÁC NHẬN',
              'Giao dịch hoàn tất');

        case OrderStatus.cancelled:
          return _successBadge('❌ ĐƠN HÀNG ĐÃ HỦY', '', isError: true);
      }
    }

    // ── NGƯỜI MUA ──
    switch (order.status) {
      case OrderStatus.pending:
        return Center(
          child: Text('Người bán đang chuẩn bị gói hàng...',
              style: TextStyle(
                  fontStyle: FontStyle.italic, color: primaryTeal)),
        );

      case OrderStatus.shipping:
        // Người mua thấy mã vận đơn và có thể xác nhận nhận hàng
        return _actionButton(
          'TÔI ĐÃ NHẬN ĐƯỢC HÀNG',
          const Color(0xFF2E7D32),
          () async {
            setState(() => _isActing = true);
            await _orderService.confirmReceived(widget.orderId);
            if (mounted) setState(() => _isActing = false);
          },
        );

      case OrderStatus.completed:
        return _successBadge('ĐƠN HÀNG HOÀN THÀNH', '');

      case OrderStatus.cancelled:
        return _successBadge('❌ ĐƠN HÀNG ĐÃ HỦY', '', isError: true);
    }
  }

  // ── Helpers UI ──
  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isActing ? null : onTap,
        child: _isActing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.5)),
      ),
    );
  }

  Widget _successBadge(String title, String subtitle,
      {bool isError = false}) {
    final color = isError ? Colors.red : primaryTeal;
    return Column(
      children: [
        Icon(
          isError ? Icons.cancel : Icons.check_circle,
          color: color,
          size: 40,
        ),
        const SizedBox(height: 6),
        Text(title,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        if (subtitle.isNotEmpty)
          Text(subtitle,
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ],
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Oldie',
              style: TextStyle(
                  color: primaryTeal,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          Text(
            widget.isBuyer ? 'Theo dõi đơn hàng' : 'Quản lý đơn hàng',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _StepData {
  final String title;
  final String subtitle;
  const _StepData(this.title, this.subtitle);
}