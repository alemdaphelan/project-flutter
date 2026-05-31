import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_flutter/shared/models/bank_account.dart';
import 'package:project_flutter/features/payment/services/bank_account_service.dart';
import 'package:project_flutter/features/payment/widgets/bank_account_card.dart';

enum EditProfileTab { basicInfo, bankAccount }

class EditProfileScreen extends StatefulWidget {
  final EditProfileTab initialTab;

  const EditProfileScreen({
    super.key,
    this.initialTab = EditProfileTab.basicInfo,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == EditProfileTab.bankAccount ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF1B6B60);

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
        title: const Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(
            color: primaryTeal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryTeal,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryTeal,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(
              icon: Icon(Icons.person_outline, size: 20),
              text: 'Thông tin cá nhân',
            ),
            Tab(
              icon: Icon(Icons.account_balance_outlined, size: 20),
              text: 'Tài khoản ngân hàng',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _BasicInfoTab(),
          _BankAccountTab(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 1: Thông tin cơ bản
// ══════════════════════════════════════════════════════════════
class _BasicInfoTab extends StatefulWidget {
  const _BasicInfoTab();

  @override
  State<_BasicInfoTab> createState() => _BasicInfoTabState();
}

class _BasicInfoTabState extends State<_BasicInfoTab> {
  final Color primaryTeal = const Color(0xFF1B6B60);
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameCtrl.text = data['displayName'] ?? '';
        _phoneCtrl.text = data['phoneNumber'] ?? '';
        _locationCtrl.text = data['location'] ?? '';
        _bioCtrl.text = data['bio'] ?? '';
      } else {
        // Nếu chưa có doc → prefill từ FirebaseAuth
        final user = FirebaseAuth.instance.currentUser;
        _nameCtrl.text = user?.displayName ?? '';
      }
    } catch (e) {
      debugPrint('Lỗi load profile: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);
    try {
      final data = {
        'displayName': _nameCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'hasCompletedProfile': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));

      // Cập nhật displayName trên FirebaseAuth để hiện đúng tên khắp nơi
      await FirebaseAuth.instance.currentUser
          ?.updateDisplayName(_nameCtrl.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã lưu thông tin!'),
            backgroundColor: primaryTeal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar placeholder
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: const Color(0xFFE8F1F0),
                    backgroundImage: FirebaseAuth
                                .instance.currentUser?.photoURL !=
                            null
                        ? NetworkImage(
                            FirebaseAuth.instance.currentUser!.photoURL!)
                        : null,
                    child:
                        FirebaseAuth.instance.currentUser?.photoURL == null
                            ? Icon(Icons.person,
                                size: 44, color: primaryTeal)
                            : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryTeal,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                FirebaseAuth.instance.currentUser?.email ?? '',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
            const SizedBox(height: 28),

            _sectionTitle('Thông tin cơ bản'),
            const SizedBox(height: 14),

            TextFormField(
              controller: _nameCtrl,
              decoration: _inputStyle('Họ và tên', Icons.person_outline),
              validator: (val) => val == null || val.isEmpty
                  ? 'Vui lòng nhập họ tên'
                  : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration:
                  _inputStyle('Số điện thoại', Icons.phone_android_outlined),
              validator: (val) {
                if (val == null || val.isEmpty) return null; // optional
                if (!RegExp(r'^(0|\+84)[0-9]{9}$').hasMatch(val)) {
                  return 'SĐT không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _locationCtrl,
              decoration: _inputStyle(
                  'Khu vực (VD: Quận 1, TP.HCM)', Icons.location_on_outlined),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _bioCtrl,
              maxLines: 3,
              maxLength: 200,
              decoration: _inputStyle('Giới thiệu bản thân', Icons.info_outline)
                  .copyWith(counterText: ''),
            ),
            const SizedBox(height: 28),

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
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'LƯU THAY ĐỔI',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
        letterSpacing: 0.8,
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryTeal, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

// ══════════════════════════════════════════════════════════════
// TAB 2: Tài khoản ngân hàng (tái sử dụng BankAccountScreen logic)
// ══════════════════════════════════════════════════════════════
class _BankAccountTab extends StatefulWidget {
  const _BankAccountTab();

  @override
  State<_BankAccountTab> createState() => _BankAccountTabState();
}

class _BankAccountTabState extends State<_BankAccountTab> {
  final Color primaryTeal = const Color(0xFF1B6B60);
  final _service = BankAccountService();
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  final _formKey = GlobalKey<FormState>();
  final _accountNoCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  VietnamBank? _selectedBank;
  bool _isSaving = false;
  bool _showForm = false; // ẩn/hiện form thêm mới

  @override
  void dispose() {
    _accountNoCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Banner giải thích ──
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: primaryTeal, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tài khoản mặc định sẽ được dùng để tạo mã QR cho người mua chuyển khoản.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),

        // ── Danh sách tài khoản ──
        Expanded(
          child: StreamBuilder<List<BankAccount>>(
            stream: _service.watchAccounts(userId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final accounts = snap.data ?? [];
              if (accounts.isEmpty && !_showForm) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance_outlined,
                        size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('Chưa có tài khoản ngân hàng',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Thêm tài khoản để nhận thanh toán qua VietQR',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 12)),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _showForm = true),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm tài khoản'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryTeal,
                        side: BorderSide(color: primaryTeal),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...accounts.map((acc) => BankAccountCard(
                        account: acc,
                        onSetPrimary: () =>
                            _service.setPrimary(userId, acc.id),
                        onDelete: () => _confirmDelete(acc),
                      )),
                  const SizedBox(height: 8),
                  // Nút thêm tài khoản mới
                  if (!_showForm)
                    OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _showForm = true),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm tài khoản mới'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryTeal,
                        side: BorderSide(color: primaryTeal),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                ],
              );
            },
          ),
        ),

        // ── Form thêm mới (hiện khi _showForm = true) ──
        if (_showForm)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
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
                  Row(
                    children: [
                      Text(
                        'Thêm tài khoản mới',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: primaryTeal),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          setState(() {
                            _showForm = false;
                            _formKey.currentState?.reset();
                            _accountNoCtrl.clear();
                            _accountNameCtrl.clear();
                            _selectedBank = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Chọn ngân hàng
                  DropdownButtonFormField<VietnamBank>(
                    decoration: _inputStyle(
                        'Chọn ngân hàng', Icons.account_balance_outlined),
                    value: _selectedBank,
                    items: VietnamBank.popular
                        .map((b) => DropdownMenuItem(
                              value: b,
                              child: Text(b.name),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedBank = val),
                    validator: (val) =>
                        val == null ? 'Vui lòng chọn ngân hàng' : null,
                  ),
                  const SizedBox(height: 10),

                  // Số tài khoản
                  TextFormField(
                    controller: _accountNoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputStyle(
                        'Số tài khoản', Icons.credit_card_outlined),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Vui lòng nhập số tài khoản'
                        : null,
                  ),
                  const SizedBox(height: 10),

                  // Tên chủ tài khoản
                  TextFormField(
                    controller: _accountNameCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _inputStyle(
                        'Tên chủ tài khoản (IN HOA)',
                        Icons.person_outline),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Vui lòng nhập tên chủ tài khoản'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
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
                          : const Text(
                              'LƯU TÀI KHOẢN',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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

      setState(() {
        _showForm = false;
        _selectedBank = null;
        _accountNoCtrl.clear();
        _accountNameCtrl.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Đã thêm tài khoản ngân hàng!'),
              backgroundColor: primaryTeal),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red.shade400),
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
            'Xóa ${account.bankName} - ${account.accountNo}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _service.deleteAccount(userId, account.id);
            },
            child: const Text('Xóa',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryTeal, size: 20),
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