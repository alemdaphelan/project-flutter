import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/payment_item_tile.dart';
import 'payment_method_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.isBuyer});

  final bool isBuyer;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color primaryTeal = const Color(0xFF1B6B60);

  List<dynamic> _allProvinces = [];
  List<dynamic> _allWards = [];
  List<dynamic> _displayWards = [];

  // 2 mã để quản lý
  String? selectedProvinceCode;
  String? selectedWardCode;

  String selectedMethod = "COD";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddressData();
  }

  // --- Hàm đọc json chỉ lấy tỉnh với phường ---
  Future<void> _loadAddressData() async {
    try {
      final String response = await rootBundle.loadString('assets/data/provinces.json');
      final List<dynamic> data = json.decode(response);

      setState(() {
        // Lấy bảng provinces và wards
        _allProvinces = data.firstWhere((e) => e['name'] == 'provinces')['data'];
        _allWards = data.firstWhere((e) => e['name'] == 'wards')['data'];
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi cấu trúc JSON: $e");
      setState(() => _isLoading = false);
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập số điện thoại';
    final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9}$');
    if (!phoneRegex.hasMatch(value)) return 'SĐT không hợp lệ';
    return null;
  }

  InputDecoration _inputStyle(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: primaryTeal, size: 20) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryTeal, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Oldie', style: TextStyle(color: primaryTeal, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PaymentItemTile(name: "Sản phẩm Demo", price: 250000),
                  const SizedBox(height: 24),
                  const Text("Thông tin giao hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  TextFormField(
                    decoration: _inputStyle("Họ và tên người nhận", icon: Icons.person_outline),
                    validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập họ tên' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    keyboardType: TextInputType.phone,
                    decoration: _inputStyle("Số điện thoại", icon: Icons.phone_android_outlined),
                    validator: _validatePhone,
                  ),
                  const SizedBox(height: 24),

                  const Text("Địa chỉ chi tiết (2 cấp)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 12),

                  // 1. Dropdown Tỉnh / Thành phố
                  DropdownButtonFormField<String>(
                    decoration: _inputStyle("Tỉnh / Thành phố"),
                    value: selectedProvinceCode,
                    items: _allProvinces.map((p) => DropdownMenuItem(
                      value: p['province_code'].toString(), 
                      child: Text(p['name'])
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedProvinceCode = val;
                        // lọc phường theo tỉnh đã chọn
                        _displayWards = _allWards.where((w) => w['province_code'].toString() == val).toList();
                        selectedWardCode = null; // Reset phường khi đổi tỉnh
                      });
                    },
                    validator: (val) => val == null ? 'Chọn Tỉnh/Thành' : null,
                  ),
                  const SizedBox(height: 12),

                  // 2. Dropdown Phường / Xã (Hiện ngay sau Tỉnh)
                  DropdownButtonFormField<String>(
                    decoration: _inputStyle("Phường / Xã / Thị trấn"),
                    value: selectedWardCode,
                    items: _displayWards.map((w) => DropdownMenuItem(
                      value: w['ward_code'].toString(), 
                      child: Text(w['name'])
                    )).toList(),
                    onChanged: (val) => setState(() => selectedWardCode = val),
                    validator: (val) => val == null ? 'Chọn Phường/Xã' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    maxLines: 2,
                    decoration: _inputStyle("Số nhà, tên đường, tổ/ấp..."),
                    validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập địa chỉ cụ thể' : null,
                  ),

                  const SizedBox(height: 32),
                  const Text("Phương thức thanh toán", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  _buildPaymentOption("COD", "Thanh toán khi nhận hàng (COD)"),
                  _buildPaymentOption("Bank", "Chuyển khoản ngân hàng (VietQR)"),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentMethodScreen(method: selectedMethod, isBuyer: widget.isBuyer),
                            ),
                          );
                        }
                      },
                      child: const Text("TIẾP TỤC", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildPaymentOption(String value, String title) {
    return RadioListTile(
      activeColor: primaryTeal,
      title: Text(title, style: const TextStyle(fontSize: 15)),
      value: value,
      groupValue: selectedMethod,
      onChanged: (val) => setState(() => selectedMethod = val!),
    );
  }
}