import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ========================================================
// KỸ SƯ TẠO ENUM ĐỂ PHÂN BIỆT MỤC ĐÍCH UPLOAD
// ========================================================
enum ImageUploadType {
  product,
  avatar,
  chat, // Tao tặng thêm cái này để dùng cho màn hình Chat lúc nãy
}

class CloudinaryService {
  // 🔴 THAY BẰNG CLOUD NAME CỦA MÀY
  final String cloudName = "db9hzryrx";

  // 🔴 ĐIỀN CHÍNH XÁC TÊN 2 CÁI PRESET MÀY VỪA TẠO TRÊN WEB VÀO ĐÂY
  final String productPreset = "selling_app_products";
  final String avatarPreset = "selling_app_avatar";
  // (Nếu chat mày muốn lưu chung thư mục với product thì lấy chung preset)
  final String chatPreset = "selling_app_products";

  /// Hàm đẩy ảnh lên Cloudinary. Bắt buộc phải truyền [type] để chọn đúng đường ray.
  Future<String?> uploadImage(
    File imageFile, {
    required ImageUploadType type,
  }) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    String selectedPreset;
    switch (type) {
      case ImageUploadType.avatar:
        selectedPreset = avatarPreset;
        break;
      case ImageUploadType.product:
        selectedPreset = productPreset;
        break;
      case ImageUploadType.chat:
        selectedPreset = chatPreset;
        break;
    }

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = selectedPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);

        return jsonMap['secure_url'] as String;
      } else {
        print('❌ Lỗi upload Cloudinary: Status Code ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Lỗi kết nối Cloudinary: $e');
      return null;
    }
  }
}
