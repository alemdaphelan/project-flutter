import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_flutter/shared/models/bank_account.dart';
import 'package:project_flutter/features/payment/services/bank_account_service.dart';
import 'package:project_flutter/features/payment/widgets/bank_account_card.dart';

class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({super.key});

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  final Color primaryTeal = const Color(0xFF1B6B60);
  final _service = BankAccountService();
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _accountNoCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  VietnamBank? _selectedBank;
  bool _isSaving = false;

  @override
  void dispose() {
    _accountNoCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          'Tài khoản ngân hàng',
          style: TextStyle(
              color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // ── Danh sách tài khoản hiện có ──
          Expanded(
            child: StreamBuilder<List<BankAccount>>(
              stream: _service.watchAccounts(userId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final accounts = snap.data ?? [];
                if (accounts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance_outlined,
                            size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Chưa có tài khoản ngân hàng',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: accounts.length,
                  itemBuilder: (_, i) => BankAccountCard(
                    account: accounts[i],
                    onSetPrimary: () =>
                        _service.setPrimary(userId, accounts[i].id),
                    onDelete: () => _confirmDelete(accounts[i]),
                  ),
                );
              },
            ),
          ),

          // ── Form thêm tài khoản mới ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Thêm tài khoản mới',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryTeal)),
                  const SizedBox(height: 16),

                  // Dropdown chọn ngân hàng
                  DropdownButtonFormField<VietnamBank>(
                    decoration: _inputStyle('Chọn ngân hàng',
                        icon: Icons.account_balance_outlined),
                    value: _selectedBank,
                    items: VietnamBank.popular
                        .map((b) => DropdownMenuItem(
                              value: b,
                              child: Text(b.name),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedBank = val),
                    validator: (val) =>
                        val == null ? 'Vui lòng chọn ngân hàng' : null,
                  ),
                  const SizedBox(height: 12),

                  // Số tài khoản
                  TextFormField(
                    controller: _accountNoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputStyle('Số tài khoản',
                        icon: Icons.credit_card_outlined),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Vui lòng nhập số tài khoản'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Tên chủ tài khoản
                  TextFormField(
                    controller: _accountNameCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _inputStyle('Tên chủ tài khoản (IN HOA)',
                        icon: Icons.person_outline),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Vui lòng nhập tên chủ tài khoản'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Nút lưu
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : _saveAccount,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('LƯU TÀI KHOẢN',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _service.addAccount(BankAccount(
        id: '',
        userId: userId,
        bankId: _selectedBank!.id,
        bankName: _selectedBank!.name,
        accountNo: _accountNoCtrl.text.trim(),
        accountName: _accountNameCtrl.text.trim().toUpperCase(),
      ));
      _formKey.currentState!.reset();
      _accountNoCtrl.clear();
      _accountNameCtrl.clear();
      setState(() => _selectedBank = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã thêm tài khoản'),
            backgroundColor: primaryTeal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: $e'), backgroundColor: Colors.red.shade400),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmDelete(BankAccount account) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa tài khoản?'),
        content: Text(
            'Bạn có chắc muốn xóa tài khoản ${account.bankName} - ${account.accountNo}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _service.deleteAccount(userId, account.id);
            },
            child:
                const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputStyle(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon:
          icon != null ? Icon(icon, color: primaryTeal, size: 20) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}