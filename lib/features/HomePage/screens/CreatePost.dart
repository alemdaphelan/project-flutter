import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_flutter/firestore_service.dart';
import 'package:project_flutter/features/HomePage/Models/Product.dart';
import 'package:project_flutter/cloudinary_service.dart';

class CreatePostScreen extends StatefulWidget {
  final String userId;
  final String userName;
  const CreatePostScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  // Controller cố định
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  // Quản lý trạng thái nạp dữ liệu từ Firebase
  List<Map<String, dynamic>> _firebaseCategories = [];
  String? _selectedCategory;
  bool _isLoading =
      true; // Ban đầu bật loading để đợi nạp categories từ Firebase

  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  // Nơi quản lý đống Controller động
  final Map<String, TextEditingController> _dynamicControllers = {};

  @override
  void initState() {
    super.initState();
    // VỪA MỞ MÀN HÌNH: Đi bốc danh mục từ Firebase về liền
    _loadCategoriesFromFirebase();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _disposeDynamicFields();
    super.dispose();
  }

  // Hàm nạp danh mục từ Firestore Service của mày
  void _loadCategoriesFromFirebase() async {
    try {
      // Gọi lại cái hàm getCategories() có sẵn trong file firestore_service.dart của mày
      List<Map<String, dynamic>> cats = await _firestoreService.getCategories();

      setState(() {
        _firebaseCategories = cats;
        if (_firebaseCategories.isNotEmpty) {
          // Chọn mặc định là cái danh mục đầu tiên bốc được trên Firebase về
          _selectedCategory = _firebaseCategories.first['name'];
          // Đẻ ô nhập liệu cho danh mục đó
          _initDynamicFields();
        }
        _isLoading = false; // Tải xong rồi thì tắt màn hình chờ
      });
    } catch (e) {
      print("Lỗi nạp danh mục từ Firebase: $e");
      setState(() => _isLoading = false);
    }
  }

  // Hàm lấy ra danh sách fields (Array) từ cái danh mục đang được chọn
  List<String> _getCurrentFields() {
    if (_selectedCategory == null) return [];
    // Tìm trong đống data Firebase xem thằng nào có name trùng với thằng đang chọn
    final currentCat = _firebaseCategories.firstWhere(
      (cat) => cat['name'] == _selectedCategory,
      orElse: () => {},
    );
    // Ép kiểu dữ liệu Array từ Firebase (List<dynamic>) về thành List<String> của Dart
    if (currentCat.containsKey('fields') && currentCat['fields'] != null) {
      return List<String>.from(currentCat['fields']);
    }
    return [];
  }

  // Tự động sinh controller dựa trên mảng bốc từ Firebase về
  void _initDynamicFields() {
    _disposeDynamicFields();
    final fields = _getCurrentFields();
    for (var fieldName in fields) {
      _dynamicControllers[fieldName] = TextEditingController();
    }
  }

  void _disposeDynamicFields() {
    _dynamicControllers.forEach((key, controller) {
      controller.dispose();
    });
    _dynamicControllers.clear();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _pickedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không mở được album: $e')));
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn hình ảnh sản phẩm!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ========================================================
      // 1. KỸ SƯ BẮN ẢNH LÊN CLOUDINARY TRƯỚC
      // ========================================================
      String? cloudinaryUrl = await CloudinaryService().uploadImage(
        _pickedImage!,
        type: ImageUploadType.product, // Khai báo rõ đây là ảnh sản phẩm
      );

      // Nếu rớt mạng hoặc lỗi API -> Chặn luôn không cho đăng bài
      if (cloudinaryUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Lỗi tải ảnh lên mạng. Vui lòng thử lại!'),
            ),
          );
          setState(() => _isLoading = false);
        }
        return;
      }
      // ========================================================

      // 2. Gom toàn bộ data thông số động
      Map<String, dynamic> specificationsMap = {};
      _dynamicControllers.forEach((fieldName, controller) {
        specificationsMap[fieldName] = controller.text.trim();
      });

      // 3. Khởi tạo cục Data
      ProductModel newProduct = ProductModel(
        id: '',
        sellerId: widget.userId,
        sellerName: widget.userName, // Sửa lại chỗ này luôn, nãy mày để rỗng ''
        time: '',
        productImageUrl: cloudinaryUrl, // 🔴 CẮM ĐƯỜNG LINK HTTPS XỊN VÀO ĐÂY
        productName: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        specifications: specificationsMap,
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        category: _selectedCategory ?? 'Other',
      );

      // 4. Bắn vào Database
      await _firestoreService.addProduct(newProduct.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Đăng bán sản phẩm thành công!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF1B6B60);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F7),
      appBar: AppBar(
        title: const Text(
          'Đăng bán món đồ cũ',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Nếu đang đợi Firebase trả data về thì hiện vòng xoay, có data rồi mới vẽ giao diện
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECTION HÌNH ẢNH ---
                    const Text(
                      'Hình ảnh sản phẩm',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _pickedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _pickedImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    color: Colors.grey.shade400,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Bấm vào đây để chọn ảnh',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- SECTION THÔNG TIN CƠ BẢN ---
                    _buildTextField(
                      controller: _nameController,
                      label: 'Tên sản phẩm',
                      hint: 'Ví dụ: iPhone 13 Pro Max 128GB',
                      validator: (v) =>
                          v!.isEmpty ? 'Vui lòng nhập tên sản phẩm' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _priceController,
                      label: 'Giá bán (VNĐ)',
                      hint: 'Ví dụ: 12500000',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v!.isEmpty) return 'Vui lòng nhập giá bán';
                        if (double.tryParse(v) == null)
                          return 'Giá bán phải là một con số';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- DROPDOWN DANH MỤC LẤY ĐỘNG TỪ FIREBASE ---
                    const Text(
                      'Danh mục sản phẩm',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          // MAP DANH SÁCH DROPDOWN TỪ FIREBASE ĐỔ VỀ
                          items: _firebaseCategories.map((cat) {
                            String name = cat['name'] ?? 'Unknown';
                            return DropdownMenuItem<String>(
                              value: name,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCategory = newValue;
                                // Đổi danh mục -> Tính toán lại và sinh bộ controller mới từ mảng Firebase
                                _initDynamicFields();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- SECTION THUỘC TÍNH ĐỘNG ---
                    _buildDynamicFieldsSection(),

                    // --- SECTION THÔNG TIN KHÁC ---
                    _buildTextField(
                      controller: _locationController,
                      label: 'Địa chỉ nơi bán',
                      hint: 'Ví dụ: Quận 1, TP. Hồ Chí Minh',
                      validator: (v) =>
                          v!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Mô tả chi tiết tình trạng đồ',
                      hint: 'Máy xài mượt, còn hộp, trầy xước nhẹ ở góc...',
                      maxLines: 4,
                      validator: (v) =>
                          v!.isEmpty ? 'Vui lòng viết vài dòng mô tả' : null,
                    ),
                    const SizedBox(height: 32),

                    // --- NÚT ĐĂNG ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Đăng bán ngay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDynamicFieldsSection() {
    // Gọi hàm bốc mảng String từ data Firebase của category hiện tại
    final fields = _getCurrentFields();
    if (fields.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB9DDD6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: Color(0xFF1B6B60), size: 18),
              const SizedBox(width: 8),
              Text(
                'Thông số chi tiết của $_selectedCategory',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1B6B60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: fields.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              String fieldName = fields[index];
              return _buildTextField(
                // Bốc đúng controller động tương ứng với tên trường từ Firebase
                controller: _dynamicControllers[fieldName]!,
                label: fieldName,
                hint: 'Nhập $fieldName...',
                validator: (v) =>
                    v!.isEmpty ? 'Không được bỏ trống trường này' : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF1B6B60),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
