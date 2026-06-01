import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_flutter/features/HomePage/Models/Product.dart';
import 'package:project_flutter/features/payment/models/OrderModel.dart';
import 'package:project_flutter/features/payment/services/OrderService.dart';
import 'package:project_flutter/features/payment/widgets/payment_item_tile.dart';
import 'payment_method_screen.dart';
import 'package:project_flutter/features/payment/widgets/searchable_address_dropdown.dart';

class CheckoutScreen extends StatefulWidget {
  final ProductModel product;
  final double? dealPrice; // <- Bổ sung biến để nhận giá offer nếu có

  const CheckoutScreen({super.key, required this.product, this.dealPrice});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color primaryTeal = const Color(0xFF1B6B60);

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();

  List<dynamic> _allProvinces = [];
  List<dynamic> _allWards = [];
  List<dynamic> _displayWards = [];
  String? selectedProvinceCode;
  String? selectedProvinceName;
  String? selectedWardCode;
  String? selectedWardName;

  String selectedMethod = 'COD';
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _submitLock = false; 

  @override
  void initState() {
    super.initState();
    _loadAddressData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAddressData() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/provinces.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        _allProvinces =
            data.firstWhere((e) => e['name'] == 'provinces')['data'];
        _allWards = data.firstWhere((e) => e['name'] == 'wards')['data'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi load address: $e');
      setState(() => _isLoading = false);
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập số điện thoại';
    if (!RegExp(r'^(0|\+84)[0-9]{9}$').hasMatch(value)) return 'SĐT không hợp lệ';
    return null;
  }

  InputBorder _inputBorder({Color color = Colors.grey, double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
  }

  InputDecoration _inputStyle(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: primaryTeal, size: 20) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: _inputBorder(color: Colors.grey.shade300),
      focusedBorder: _inputBorder(color: primaryTeal, width: 2),
      errorBorder: _inputBorder(color: Colors.red),
      focusedErrorBorder: _inputBorder(color: Colors.red, width: 2),
    );
  }

  Future<void> _submit() async {
    if (_submitLock) return;
    _submitLock = true;

    if (!_formKey.currentState!.validate()) {
      _submitLock = false;
      return;
    }
    if (selectedProvinceCode == null) {
      _submitLock = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn Tỉnh/Thành phố')),
      );
      return;
    }
    if (selectedWardCode == null) {
      _submitLock = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn Phường/Xã')),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final fullAddress =
          '${_streetCtrl.text.trim()}, $selectedWardName, $selectedProvinceName';

      // Ưu tiên lấy giá deal nếu có, không có thì lấy giá gốc
      double finalPrice = widget.dealPrice ?? widget.product.price;

      final order = OrderModel(
        id: '',
        buyerId: uid,
        sellerId: widget.product.sellerId,
        productId: widget.product.id, 
        productName: widget.product.productName,
        productImageUrl: widget.product.productImageUrl,
        price: finalPrice, // Chốt giá cuối cùng
        receiverName: _nameCtrl.text.trim(),
        receiverPhone: _phoneCtrl.text.trim(),
        deliveryAddress: fullAddress,
        paymentMethod: selectedMethod,
        createdAt: DateTime.now(),
      );

      final orderId = await OrderService().createOrder(order);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentMethodScreen(
            method: selectedMethod,
            amount: finalPrice.toInt(), // Cập nhật số tiền qua cổng thanh toán
            orderId: orderId,
            sellerId: widget.product.sellerId,
            isBuyer: true,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đặt hàng: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      _submitLock = false;
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ưu tiên hiển thị giá deal
    double displayPrice = widget.dealPrice ?? widget.product.price;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PaymentItemTile(
                      name: widget.product.productName,
                      price: displayPrice, // Giá hiển thị trên banner sản phẩm
                      imageUrl: widget.product.productImageUrl,
                    ),
                    const SizedBox(height: 24),

                    const Text('Thông tin giao hàng',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _inputStyle('Họ và tên người nhận',
                          icon: Icons.person_outline),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Vui lòng nhập họ tên'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _inputStyle('Số điện thoại',
                          icon: Icons.phone_android_outlined),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 24),

                    Text('Địa chỉ giao hàng',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700)),
                    const SizedBox(height: 12),

                    SearchableAddressDropdown(
                      label: 'Tỉnh / Thành phố',
                      icon: Icons.location_city_outlined,
                      items: _allProvinces,
                      displayKey: 'name',
                      selectedValue: selectedProvinceName,
                      primaryTeal: primaryTeal,
                      onSelected: (item) {
                        setState(() {
                          selectedProvinceCode =
                              item['province_code'].toString();
                          selectedProvinceName = item['name'];
                          _displayWards = _allWards
                              .where((w) =>
                                  w['province_code'].toString() ==
                                  selectedProvinceCode)
                              .toList();
                          selectedWardCode = null;
                          selectedWardName = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    SearchableAddressDropdown(
                      label: 'Phường / Xã / Thị trấn',
                      icon: Icons.holiday_village_outlined,
                      items: _displayWards,
                      displayKey: 'name',
                      selectedValue: selectedWardName,
                      enabled: selectedProvinceCode != null,
                      hintText: selectedProvinceCode == null
                          ? 'Chọn tỉnh/thành trước'
                          : 'Chọn phường/xã',
                      primaryTeal: primaryTeal,
                      onSelected: (item) {
                        setState(() {
                          selectedWardCode = item['ward_code'].toString();
                          selectedWardName = item['name'];
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _streetCtrl,
                      maxLines: 2,
                      decoration:
                          _inputStyle('Số nhà, tên đường, tổ/ấp...'),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Vui lòng nhập địa chỉ cụ thể'
                          : null,
                    ),

                    const SizedBox(height: 32),
                    const Text('Phương thức thanh toán',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    _buildPaymentOption(
                        'COD', 'Thanh toán khi nhận hàng (COD)'),
                    _buildPaymentOption(
                        'Bank', 'Chuyển khoản ngân hàng (VietQR)'),

                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng thanh toán',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                          Text(
                            '${displayPrice.toStringAsFixed(0)} VNĐ', // Cập nhật tổng tiền hiển thị
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: primaryTeal,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('TIẾP TỤC',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
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