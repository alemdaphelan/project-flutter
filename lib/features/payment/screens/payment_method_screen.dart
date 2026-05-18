import 'package:flutter/material.dart';
import 'order_status_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String method; 
  final bool isBuyer; // 1. Thêm biến nhận trạng thái

  // 2. Bắt buộc truyền vào Constructor
  const PaymentMethodScreen({super.key, required this.method, required this.isBuyer});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final Color primaryTeal = const Color(0xFF1B6B60);

  final String myBankId = "970422"; 
  final String myAccountNo = "0944649536";
  final String myAccountName = "HO NGOC PHUONG NHU";
  final int amount = 250000;

  @override
  Widget build(BuildContext context) {
    bool isQR = widget.method == "Bank";

    String qrUrl =
        "https://img.vietqr.io/image/$myBankId-$myAccountNo-compact.png"
        "?amount=$amount"
        "&addInfo=Thanh toan don hang Oldie";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isQR) ...[
              Text(
                "QUÉT MÃ ĐỂ THANH TOÁN",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTeal, letterSpacing: 1.1),
              ),
              const SizedBox(height: 8),
              Text(
                "Chủ tài khoản: $myAccountName",
                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: primaryTeal.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    qrUrl,
                    width: 240,
                    height: 240,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return SizedBox(width: 240, height: 240, child: Center(child: CircularProgressIndicator(color: primaryTeal)));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Vui lòng nhấn xác nhận sau khi bạn đã chuyển khoản thành công",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 40),
              _buildConfirmButton(context, "XÁC NHẬN ĐÃ THANH TOÁN"),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(30),
                decoration: const BoxDecoration(color: Color(0xFFE8F1F0), shape: BoxShape.circle),
                child: Icon(Icons.delivery_dining_outlined, size: 80, color: primaryTeal),
              ),
              const SizedBox(height: 30),
              Text("THANH TOÁN KHI NHẬN HÀNG", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTeal)),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Đơn hàng sẽ được gửi đến địa chỉ của bạn. Vui lòng chuẩn bị tiền mặt khi nhận hàng.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                ),
              ),
              const SizedBox(height: 50),
              _buildConfirmButton(context, "XÁC NHẬN ĐẶT HÀNG"),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context, String label) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              // 3. ĐẨY TRẠNG THÁI TIẾP SANG TRANG ORDER STATUS
              builder: (context) => OrderStatusScreen(isBuyer: widget.isBuyer), 
            ),
          );
        },
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
        ),
      ),
    );
  }
}