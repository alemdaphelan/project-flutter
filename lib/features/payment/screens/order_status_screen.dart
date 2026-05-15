import 'package:flutter/material.dart';

class OrderStatusScreen extends StatefulWidget {
  final bool isBuyer;
  const OrderStatusScreen({super.key, this.isBuyer = true});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  // Màu chủ đạo Oldie
  final Color primaryTeal = const Color(0xFF1B6B60);
  final Color lightTeal = const Color(0xFFE8F1F0);

  int _currentStep = 0;
  final TextEditingController _trackingController = TextEditingController();
  String _trackingNumber = "Chưa có mã";
  String? _errorText;

  final List<String> _statusTitles = [
    "Đang xử lý",
    "Đã bàn giao cho ĐVVC",
    "Hoàn thành đơn hàng",
  ];

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, 
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Oldie',
              style: TextStyle(
                color: primaryTeal,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Thông tin vận đơn (Style Card Oldie)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: lightTeal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: primaryTeal),
                const SizedBox(width: 12),
                const Text(
                  "Mã vận đơn: ",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  _trackingNumber,
                  style: TextStyle(
                    color: primaryTeal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 2. Thanh tiến trình (Cập nhật màu Stepper)
          Expanded(
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(colorScheme: ColorScheme.light(primary: primaryTeal)),
              child: Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                controlsBuilder: (context, details) => const SizedBox.shrink(),
                steps: [
                  _buildStep(0, "Người bán đang chuẩn bị hàng"),
                  _buildStep(1, "Hàng đã được gửi cho đơn vị vận chuyển"),
                  _buildStep(2, "Giao dịch thành công"),
                ],
              ),
            ),
          ),

          // 3. Khối hành động (Style Button/Input đồng bộ)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRoleActions(),
                const SizedBox(height: 16),

                // NÚT VỀ TRANG CHỦ (Style Secondary)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryTeal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        Navigator.popUntil(context, (route) => route.isFirst),
                    icon: Icon(Icons.home_outlined, color: primaryTeal),
                    label: Text(
                      "VỀ TRANG CHỦ",
                      style: TextStyle(
                        color: primaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleActions() {
    if (!widget.isBuyer) {
      if (_currentStep == 0) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "CẬP NHẬT MÃ VẬN ĐƠN",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _trackingController,
              decoration: InputDecoration(
                hintText: "Ví dụ: GHTK_123456789",
                errorText: _errorText,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryTeal, width: 2),
                ),
                prefixIcon: Icon(
                  Icons.qr_code_scanner,
                  color: primaryTeal,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _actionButton("XÁC NHẬN GỬI HÀNG", primaryTeal, () {
              setState(() {
                if (_trackingController.text.trim().isEmpty) {
                  _errorText = "Bạn chưa nhập mã vận đơn!";
                } else {
                  _errorText = null;
                  _trackingNumber = _trackingController.text;
                  _currentStep = 1;
                }
              });
            }),
          ],
        );
      }
      if (_currentStep == 2) {
        return Column(
          children: [
            Icon(Icons.check_circle, color: primaryTeal, size: 40),
            const SizedBox(height: 8),
            Text(
              "✅ KHÁCH HÀNG ĐÃ XÁC NHẬN",
              style: TextStyle(
                color: primaryTeal,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Giao dịch hoàn tất",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        );
      }
      return Center(
        child: Text(
          "Chờ khách hàng xác nhận...",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: primaryTeal,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else {
      if (_currentStep == 1) {
        return _actionButton(
          "TÔI ĐÃ NHẬN ĐƯỢC HÀNG",
          const Color(0xFF2E7D32), 
          () => setState(() => _currentStep = 2),
        );
      }
      if (_currentStep == 2) {
        return Column(
          children: [
            Icon(Icons.check_circle, color: primaryTeal, size: 40),
            const SizedBox(height: 8),
            Text(
              "ĐƠN HÀNG HOÀN THÀNH",
              style: TextStyle(
                color: primaryTeal,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        );
      }
      return Center(
        child: Text(
          "Người bán đang chuẩn bị gói hàng...",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: primaryTeal,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
  }

  Step _buildStep(int index, String subtitle) {
    return Step(
      title: Text(
        _statusTitles[index],
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: _currentStep >= index ? primaryTeal : Colors.grey,
        ),
      ),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
      content: const SizedBox.shrink(),
      isActive: _currentStep >= index,
      state: _currentStep > index ? StepState.complete : StepState.indexed,
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
