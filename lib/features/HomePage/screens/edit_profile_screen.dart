import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project_flutter/shared/models/bank_account.dart';
import 'package:project_flutter/features/payment/services/bank_account_service.dart';
import 'package:project_flutter/features/payment/widgets/bank_account_card.dart';
import 'package:project_flutter/features/payment/widgets/searchable_address_dropdown.dart';
import 'package:flutter/services.dart';

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
      backgroundColor: const Color(0xFFF2F8F7),
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
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.person_outline, size: 20), text: 'Thông tin cá nhân'),
            Tab(icon: Icon(Icons.account_balance_outlined, size: 20), text: 'Tài khoản ngân hàng'),
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
// TAB 1: Thông tin cá nhân
// ══════════════════════════════════════════════════════════════
class _BasicInfoTab extends StatefulWidget {
  const _BasicInfoTab();

  @override
  State<_BasicInfoTab> createState() => _BasicInfoTabState();
}

class _BasicInfoTabState extends State<_BasicInfoTab> {
  static const Color primaryTeal = Color(0xFF1B6B60);

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController(); // Số nhà, tên đường
  final _bioCtrl = TextEditingController();

  // Dữ liệu địa chỉ
  List<dynamic> _allProvinces = [];
  List<dynamic> _allWards = [];
  List<dynamic> _displayWards = [];
  String? _selectedProvinceCode;
  String? _selectedProvinceName;
  String? _selectedWardCode;
  String? _selectedWardName;
  bool _isAddressLoading = true;

  // Sở thích — danh sách gợi ý phù hợp sàn C2C đồ cũ
  static const List<String> _interestOptions = [
    'Điện thoại', 'Laptop', 'Máy tính bảng', 'Màn hình',
    'Tai nghe', 'Loa', 'Máy ảnh', 'Đồng hồ',
    'Sách', 'Quần áo', 'Giày dép', 'Túi xách',
    'Đồ gia dụng', 'Đồ chơi', 'Xe đạp', 'Dụng cụ thể thao',
  ];
  final Set<String> _selectedInterests = {};

  // Avatar
  File? _pickedAvatar;
  String? _currentAvatarUrl;
  bool _isUploadingAvatar = false;

  // Dùng để match lại dropdown sau khi load JSON xong
  String? _savedProvinceName;
  String? _savedWardName;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadAddressData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // ── Load dữ liệu từ Firestore ──
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
        _bioCtrl.text = data['bio'] ?? '';
        _currentAvatarUrl = data['avatarUrl'] as String?;

        // Load sở thích
        final interests = data['interests'];
        if (interests is List) {
          _selectedInterests.addAll(interests.cast<String>());
        }

        // Parse location đã lưu dạng "số nhà, phường, tỉnh"
        // Lưu lại street để điền vào _streetCtrl sau khi address data load xong
        final savedLocation = data['location'] as String? ?? '';
        if (savedLocation.isNotEmpty) {
          final parts = savedLocation.split(', ');
          if (parts.length >= 1) _streetCtrl.text = parts[0];
          // province & ward sẽ được match sau khi _loadAddressData xong
          _savedProvinceName = parts.length >= 3 ? parts[2] : null;
          _savedWardName = parts.length >= 2 ? parts[1] : null;
        }
      } else {
        // Prefill từ Firebase Auth nếu chưa có document
        final user = FirebaseAuth.instance.currentUser;
        _nameCtrl.text = user?.displayName ?? '';
        _currentAvatarUrl = user?.photoURL;
      }
    } catch (e) {
      debugPrint('Lỗi load profile: $e');
    }
    setState(() => _isLoading = false);
  }

  // ── Load dữ liệu tỉnh/phường từ JSON ──
  Future<void> _loadAddressData() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/provinces.json');
      final List<dynamic> data = json.decode(response);
      final provinces =
          data.firstWhere((e) => e['name'] == 'provinces')['data'] as List;
      final wards =
          data.firstWhere((e) => e['name'] == 'wards')['data'] as List;

      setState(() {
        _allProvinces = provinces;
        _allWards = wards;
        _isAddressLoading = false;

        // Match lại dropdown nếu đã có dữ liệu lưu trước
        if (_savedProvinceName != null) {
          final matchProvince = _allProvinces.cast<Map>().firstWhere(
            (p) => p['name'] == _savedProvinceName,
            orElse: () => {},
          );
          if (matchProvince.isNotEmpty) {
            _selectedProvinceCode =
                matchProvince['province_code'].toString();
            _selectedProvinceName = matchProvince['name'];
            _displayWards = _allWards
                .where((w) =>
                    w['province_code'].toString() == _selectedProvinceCode)
                .toList();

            if (_savedWardName != null) {
              final matchWard = _displayWards.cast<Map>().firstWhere(
                (w) => w['name'] == _savedWardName,
                orElse: () => {},
              );
              if (matchWard.isNotEmpty) {
                _selectedWardCode = matchWard['ward_code'].toString();
                _selectedWardName = matchWard['name'];
              }
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Lỗi load address: $e');
      setState(() => _isAddressLoading = false);
    }
  }

  // ── Chọn ảnh từ thư viện ──
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      _pickedAvatar = File(picked.path);
    });
  }

  // ── Upload avatar lên Cloudinary ──
  Future<String?> _uploadAvatarToCloudinary(File file) async {
    const cloudName = 'db9hzryrx';
    const preset = 'selling_app_avatar';
    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = preset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final body = json.decode(await response.stream.bytesToString());
      return body['secure_url'] as String?;
    }
    return null;
  }

  // ── Lưu toàn bộ thông tin ──
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);
    try {
      String? avatarUrl = _currentAvatarUrl;

      // Upload ảnh mới nếu user đã chọn
      if (_pickedAvatar != null) {
        setState(() => _isUploadingAvatar = true);
        avatarUrl = await _uploadAvatarToCloudinary(_pickedAvatar!);
        setState(() => _isUploadingAvatar = false);
        if (avatarUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không upload được ảnh. Vui lòng thử lại.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isSaving = false);
          return;
        }
      }

      // Ghép địa chỉ đầy đủ
      final street = _streetCtrl.text.trim();
      final fullLocation = [
        if (street.isNotEmpty) street,
        if (_selectedWardName != null) _selectedWardName!,
        if (_selectedProvinceName != null) _selectedProvinceName!,
      ].join(', ');

      final data = {
        'displayName': _nameCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'location': fullLocation,
        'bio': _bioCtrl.text.trim(),
        'interests': _selectedInterests.toList(),
        'avatarUrl': avatarUrl ?? '',
        'hasCompletedProfile': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));

      // Đồng bộ lên FirebaseAuth
      final authUser = FirebaseAuth.instance.currentUser;
      await authUser?.updateDisplayName(_nameCtrl.text.trim());
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        await authUser?.updatePhotoURL(avatarUrl);
      }

      setState(() {
        _currentAvatarUrl = avatarUrl;
        _pickedAvatar = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu thông tin!'),
            backgroundColor: primaryTeal,
            duration: Duration(seconds: 2),
          ),
        );
        // Quay lại màn hình trước sau khi lưu thành công
        Navigator.pop(context);
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
      return const Center(
          child: CircularProgressIndicator(color: primaryTeal));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ──
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryTeal, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: const Color(0xFFE8F1F0),
                        backgroundImage: _pickedAvatar != null
                            ? FileImage(_pickedAvatar!) as ImageProvider
                            : (_currentAvatarUrl != null &&
                                    _currentAvatarUrl!.isNotEmpty)
                                ? NetworkImage(_currentAvatarUrl!)
                                : null,
                        child: (_pickedAvatar == null &&
                                (_currentAvatarUrl == null ||
                                    _currentAvatarUrl!.isEmpty))
                            ? const Icon(Icons.person,
                                size: 48, color: primaryTeal)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryTeal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: _isUploadingAvatar
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.camera_alt,
                                size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                FirebaseAuth.instance.currentUser?.email ?? '',
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
            if (_pickedAvatar != null) ...[
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Ảnh mới sẽ được lưu khi bạn nhấn "Lưu thay đổi"',
                  style: TextStyle(
                      color: primaryTeal,
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 28),

            // ── Thông tin cơ bản ──
            _sectionTitle('THÔNG TIN CƠ BẢN'),
            const SizedBox(height: 14),

            TextFormField(
              controller: _nameCtrl,
              decoration:
                  _inputStyle('Họ và tên hiển thị', Icons.person_outline),
              validator: (val) =>
                  val == null || val.trim().isEmpty
                      ? 'Vui lòng nhập họ tên'
                      : null,
            ),
            const SizedBox(height: 14),

            // Email chỉ đọc — không cho sửa
            InputDecorator(
              decoration: _inputStyle('Email', Icons.email_outlined).copyWith(
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              child: Text(
                FirebaseAuth.instance.currentUser?.email ?? '—',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 15),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Email không thể thay đổi',
                style:
                    TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _inputStyle(
                  'Số điện thoại', Icons.phone_android_outlined),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return null;
                if (!RegExp(r'^(0|\+84)[0-9]{9}$').hasMatch(val.trim())) {
                  return 'Số điện thoại không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── Địa chỉ: Tỉnh → Phường → Số nhà ──
            _sectionTitle('ĐỊA CHỈ'),
            const SizedBox(height: 14),

            _isAddressLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(color: primaryTeal),
                    ),
                  )
                : Column(
                    children: [
                      // Dropdown Tỉnh/Thành phố — có tìm kiếm
                      SearchableAddressDropdown(
                        label: 'Tỉnh / Thành phố',
                        icon: Icons.location_city_outlined,
                        items: _allProvinces,
                        displayKey: 'name',
                        selectedValue: _selectedProvinceName,
                        primaryTeal: primaryTeal,
                        onSelected: (item) {
                          setState(() {
                            _selectedProvinceCode =
                                item['province_code'].toString();
                            _selectedProvinceName = item['name'];
                            _displayWards = _allWards
                                .where((w) =>
                                    w['province_code'].toString() ==
                                    _selectedProvinceCode)
                                .toList();
                            _selectedWardCode = null;
                            _selectedWardName = null;
                          });
                        },
                      ),
                      const SizedBox(height: 14),

                      // Dropdown Phường/Xã — có tìm kiếm
                      SearchableAddressDropdown(
                        label: 'Phường / Xã / Thị trấn',
                        icon: Icons.holiday_village_outlined,
                        items: _displayWards,
                        displayKey: 'name',
                        selectedValue: _selectedWardName,
                        enabled: _selectedProvinceCode != null,
                        hintText: _selectedProvinceCode == null
                            ? 'Chọn tỉnh/thành trước'
                            : 'Chọn phường/xã',
                        primaryTeal: primaryTeal,
                        onSelected: (item) {
                          setState(() {
                            _selectedWardCode = item['ward_code'].toString();
                            _selectedWardName = item['name'];
                          });
                        },
                      ),
                      const SizedBox(height: 14),

                      // Số nhà, tên đường
                      TextFormField(
                        controller: _streetCtrl,
                        decoration: _inputStyle(
                            'Số nhà, tên đường, tổ/ấp...',
                            Icons.signpost_outlined),
                      ),
                    ],
                  ),
            const SizedBox(height: 28),

            TextFormField(
              controller: _bioCtrl,
              maxLines: 3,
              maxLength: 200,
              decoration: _inputStyle(
                      'Giới thiệu bản thân', Icons.info_outline)
                  .copyWith(
                counterText: '${_bioCtrl.text.length}/200',
                helperText: 'Mô tả ngắn về bạn — hiện trên trang cá nhân',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 28),

            // ── Sở thích / Danh mục quan tâm ──
            _sectionTitle('SỞ THÍCH & DANH MỤC QUAN TÂM'),
            const SizedBox(height: 6),
            Text(
              'Chọn những danh mục bạn hay mua/bán để nhận gợi ý phù hợp hơn',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _interestOptions.map((interest) {
                final selected = _selectedInterests.contains(interest);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedInterests.remove(interest);
                    } else {
                      _selectedInterests.add(interest);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? primaryTeal
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? primaryTeal
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      interest,
                      style: TextStyle(
                        fontSize: 13,
                        color: selected
                            ? Colors.white
                            : Colors.grey.shade700,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 36),

            // ── Nút lưu ──
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
                          fontSize: 15,
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
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
        letterSpacing: 1.0,
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
        borderSide: const BorderSide(color: primaryTeal, width: 2),
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
// TAB 2: Tài khoản ngân hàng
// ══════════════════════════════════════════════════════════════
class _BankAccountTab extends StatefulWidget {
  const _BankAccountTab();

  @override
  State<_BankAccountTab> createState() => _BankAccountTabState();
}

class _BankAccountTabState extends State<_BankAccountTab> {
  static const Color primaryTeal = Color(0xFF1B6B60);
  final _service = BankAccountService();
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  final _formKey = GlobalKey<FormState>();
  final _accountNoCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  VietnamBank? _selectedBank;
  bool _isSaving = false;
  bool _showForm = false;

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
              const Icon(Icons.info_outline, color: primaryTeal, size: 18),
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
                    Text(
                        'Thêm tài khoản để nhận thanh toán qua VietQR',
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
                        side: const BorderSide(color: primaryTeal),
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
                  if (!_showForm)
                    OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _showForm = true),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm tài khoản mới'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryTeal,
                        side: const BorderSide(color: primaryTeal),
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

        // ── Form thêm mới ──
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
                      const Text(
                        'Thêm tài khoản mới',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: primaryTeal),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => setState(() {
                          _showForm = false;
                          _formKey.currentState?.reset();
                          _accountNoCtrl.clear();
                          _accountNameCtrl.clear();
                          _selectedBank = null;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                  TextFormField(
                    controller: _accountNameCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _inputStyle(
                        'Tên chủ tài khoản (IN HOA)', Icons.person_outline),
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
          const SnackBar(
              content: Text('Đã thêm tài khoản ngân hàng!'),
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
        content: Text('Xóa ${account.bankName} - ${account.accountNo}?'),
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
        borderSide: const BorderSide(color: primaryTeal, width: 2),
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