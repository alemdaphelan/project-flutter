import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import 'main_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  List<String> _selectedInterests = [];
  bool _isLoading = false;
  File? _avatarFile; // File ảnh đã chọn từ máy
  String? _avatarLocalPath; // Đường dẫn tạm (nếu không upload Storage)

  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _interestOptions = [
    {'label': 'Thời trang', 'icon': Icons.checkroom},
    {'label': 'Điện thoại', 'icon': Icons.smartphone},
    {'label': 'Laptop', 'icon': Icons.laptop},
    {'label': 'Phụ kiện', 'icon': Icons.watch},
    {'label': 'Mỹ phẩm', 'icon': Icons.face_retouching_natural},
    {'label': 'Giày dép', 'icon': Icons.directions_walk},
    {'label': 'Đồ gia dụng', 'icon': Icons.home},
    {'label': 'Thể thao', 'icon': Icons.sports_basketball},
    {'label': 'Sách', 'icon': Icons.menu_book},
    {'label': 'Đồ ăn', 'icon': Icons.restaurant},
    {'label': 'Du lịch', 'icon': Icons.flight},
    {'label': 'Công nghệ', 'icon': Icons.computer},
  ];

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ====================== CHỌN ẢNH ======================

  Future<void> _pickAvatar() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chọn ảnh đại diện',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Chụp ảnh'),
              onTap: () async {
                Navigator.pop(context);
                await _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Chọn từ thư viện'),
              onTap: () async {
                Navigator.pop(context);
                await _getImage(ImageSource.gallery);
              },
            ),
            if (_avatarFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Xóa ảnh',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _avatarFile = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() {
          _avatarFile = File(picked.path);
          _avatarLocalPath = picked.path;
        });
      }
    } catch (e) {
      _showSnackBar('Không thể chọn ảnh: $e');
    }
  }

  // ====================== LƯU PROFILE ======================

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_displayNameController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập họ và tên');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
        return;
      }

      // Lưu ảnh local path (nếu muốn upload Firebase Storage thật
      // thì cần thêm firebase_storage và implement upload ở đây)
      String? avatarUrl = _avatarLocalPath;

      final profile = UserProfile(
        uid: user.uid,
        displayName: _displayNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        interests: _selectedInterests,
        avatarUrl: avatarUrl,
        hasCompletedProfile: true,
      );

      await _authService.saveUserProfile(user.uid, profile);

      if (mounted) {
        _showSnackBar('Hoàn thành! Chào mừng bạn đến với ứng dụng.');
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => MainScreen_Auth()),
          (route) => false,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Lỗi lưu thông tin: ${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ====================== BUILD ======================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoàn thiện hồ sơ'),
        automaticallyImplyLeading: false, // Không cho quay lại
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Vui lòng hoàn thiện hồ sơ để chúng tôi phục vụ bạn tốt hơn. Thao tác này chỉ cần làm một lần.',
                        style: TextStyle(color: Colors.blue, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Avatar
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _avatarFile != null
                            ? FileImage(_avatarFile!)
                            : null,
                        child: _avatarFile == null
                            ? const Icon(
                                Icons.person,
                                size: 55,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Nhấn để chọn ảnh đại diện',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),

              const SizedBox(height: 28),

              // Họ và tên (bắt buộc)
              TextFormField(
                controller: _displayNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                  hintText: 'Nguyễn Văn A',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  if (value.trim().length < 2) {
                    return 'Họ tên phải có ít nhất 2 ký tự';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Số điện thoại (không bắt buộc)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  counterText: '',
                  hintText: '0912345678 (không bắt buộc)',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return null; // Không bắt buộc
                  final phoneRegex = RegExp(r'^(0[3-9][0-9]{8})$');
                  if (!phoneRegex.hasMatch(value.trim())) {
                    return 'Số điện thoại phải có đúng 10 số';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Giới thiệu bản thân
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Giới thiệu bản thân',
                  prefixIcon: Icon(Icons.edit_note),
                  border: OutlineInputBorder(),
                  hintText: 'Một vài điều về bạn... (không bắt buộc)',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 20),

              // Sở thích mua sắm
              const Text(
                'Sở thích mua sắm',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Chọn các danh mục bạn quan tâm',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _interestOptions.map((item) {
                  final label = item['label'] as String;
                  final icon = item['icon'] as IconData;
                  final isSelected = _selectedInterests.contains(label);

                  return FilterChip(
                    avatar: Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: Colors.blue,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedInterests.add(label);
                        } else {
                          _selectedInterests.remove(label);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 36),

              // Nút hoàn thành
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'HOÀN THÀNH',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Có thể bỏ qua? KHÔNG — giải thích rõ
              const Center(
                child: Text(
                  'Bạn cần hoàn thiện hồ sơ trước khi sử dụng ứng dụng',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
