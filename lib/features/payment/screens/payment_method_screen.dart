import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_flutter/shared/models/bank_account.dart';
import 'package:project_flutter/features/payment/services/bank_account_service.dart';
import 'order_status_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String method;
  final bool isBuyer;
  final int amount; // Nhận giá từ màn hình trước thay vì hardcode
  final String orderId; // Có thể dùng để tracking đơn hàng thực tế
  final String sellerId; // Truyền sellerId để lấy đúng QR của người bán

  const PaymentMethodScreen({
    super.key,
    required this.method,
    required this.isBuyer,
    this.amount = 250000, // giữ default để không breaking change
    required this.orderId,
    required this.sellerId,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final Color primaryTeal = const Color(0xFF1B6B60);
  final _service = BankAccountService();

  // Lấy uid của NGƯỜI BÁN — thực tế nên truyền sellerId từ ProductModel
  // Tạm thời dùng current user để demo flow người bán xem QR của mình
  final String sellerId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final bool isQR = widget.method == "Bank";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Oldie',
                style: TextStyle(
                    color: primaryTeal,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: isQR ? _buildQRSection() : _buildCODSection(),
      ),
    );
  }

  // ── QR: đọc tài khoản primary của người bán từ Firestore ──
  Widget _buildQRSection() {
    return FutureBuilder<BankAccount?>(
      future: _service.getPrimaryAccount(sellerId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Người bán chưa cài tài khoản ngân hàng
        if (!snap.hasData || snap.data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'Người bán chưa thiết lập\ntài khoản ngân hàng',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vui lòng liên hệ người bán\nhoặc chọn thanh toán COD',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                _buildConfirmButton(context, "VỀ TRANG TRƯỚC",
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
          );
        }

        final account = snap.data!;
        final qrUrl = account.vietQrUrl(
          amount: widget.amount,
          description: 'Thanh toan don hang Oldie',
        );

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "QUÉT MÃ ĐỂ THANH TOÁN",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTeal,
                  letterSpacing: 1.1),
            ),
            const SizedBox(height: 4),
            Text(
              "${account.bankName}  •  ${account.accountNo}",
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            Text(
              account.accountName,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // QR động
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border.all(color: primaryTeal.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  qrUrl,
                  width: 240,
                  height: 240,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return SizedBox(
                      width: 240,
                      height: 240,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: primaryTeal)),
                    );
                  },
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 240,
                    height: 240,
                    child: Center(
                        child: Text('Không tải được QR',
                            style: TextStyle(color: Colors.grey))),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Vui lòng nhấn xác nhận sau khi đã chuyển khoản",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 32),
            _buildConfirmButton(context, "XÁC NHẬN ĐÃ THANH TOÁN"),
          ],
        );
      },
    );
  }

  Widget _buildCODSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(30),
          decoration: const BoxDecoration(
              color: Color(0xFFE8F1F0), shape: BoxShape.circle),
          child: Icon(Icons.delivery_dining_outlined,
              size: 80, color: primaryTeal),
        ),
        const SizedBox(height: 30),
        Text("THANH TOÁN KHI NHẬN HÀNG",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryTeal)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Đơn hàng sẽ được gửi đến địa chỉ của bạn. "
            "Vui lòng chuẩn bị tiền mặt khi nhận hàng.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.5),
          ),
        ),
        const SizedBox(height: 50),
        _buildConfirmButton(context, "XÁC NHẬN ĐẶT HÀNG"),
      ],
    );
  }

  Widget _buildConfirmButton(BuildContext context, String label,
      {VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed ??
            () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      OrderStatusScreen(isBuyer: widget.isBuyer),
                ),
              );
            },
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.1)),
      ),
    );
  }
}