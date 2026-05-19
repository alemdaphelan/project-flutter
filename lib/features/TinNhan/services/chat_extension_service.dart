import 'package:flutter/material.dart';
import 'firebase_chat_service.dart';

// Dịch vụ quản lý các tính năng mở rộng (Phân loại, Tự động trả lời, Menu tùy chọn)
class ChatExtensionService {
  // 1. TỰ ĐỘNG TRẢ LỜI
  static bool isAutoReplyEnabled = false;
  static String autoReplyText = "Chào bạn, hiện shop đang bận. Shop sẽ phản hồi bạn trong thời gian sớm nhất nhé!";

  // 2. QUẢN LÝ PHÂN LOẠI & TRẠNG THÁI CHAT (Bộ nhớ cục bộ)
  static List<Map<String, dynamic>> categories = [
    {"name": "Khách VIP", "color": Colors.blue},
    {"name": "Khách sỉ", "color": Colors.orange},
    {"name": "Khách boom hàng", "color": Colors.red},
  ];
  
  // Lưu danh sách ID các phòng chat đang bị ẩn
  static Set<String> hiddenChatIds = {};
  
  // Lưu map: ID phòng chat -> Tên phân loại (VD: "room1" -> "Khách VIP")
  static Map<String, String> chatCategoryMap = {};

  // Hiển thị menu tùy chọn (BottomSheet) khi nhấn giữ
  static void showChatOptions(BuildContext context, String chatRoomId, String userName, VoidCallback onUpdate) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(margin: const EdgeInsets.symmetric(vertical: 10), height: 5, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const Padding(padding: EdgeInsets.all(8.0), child: Text("Tùy chọn hội thoại", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            
            // NÚT: THÊM VÀO PHÂN LOẠI
            ListTile(
              leading: const Icon(Icons.folder_special, color: Colors.blue),
              title: const Text("Thêm vào phân loại"),
              onTap: () {
                Navigator.pop(c); 
                _showCategorySelection(context, chatRoomId, onUpdate); 
              },
            ),
            
            // NÚT: ẨN ĐOẠN CHAT
            ListTile(
              leading: const Icon(Icons.visibility_off, color: Colors.grey),
              title: const Text("Ẩn đoạn chat"),
              onTap: () {
                hiddenChatIds.add(chatRoomId); // Đưa ID vào danh sách ẩn
                onUpdate(); // Gọi lệnh vẽ lại màn hình chính (biến mất lập tức)
                Navigator.pop(c);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã ẩn đoạn chat!")));
              },
            ),
            
            // NÚT: XÓA ĐOẠN CHAT
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text("Xóa đoạn chat", style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(c);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang xóa dữ liệu...")));
                
                await FirebaseChatService().deleteChat(chatRoomId); // Xóa thật trên Firebase
                onUpdate(); // Vẽ lại màn hình
                
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa vĩnh viễn đoạn chat!")));
              },
            ),
          ],
        ),
      ),
    );
  }

  // Bảng chọn phân loại
  static void _showCategorySelection(BuildContext context, String chatRoomId, VoidCallback onUpdate) {
    showModalBottomSheet(
      context: context,
      builder: (c) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(padding: EdgeInsets.all(16.0), child: Text("Chọn phân loại", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return ListTile(
                  leading: Icon(Icons.folder, color: cat["color"]),
                  title: Text(cat["name"]),
                  onTap: () {
                    chatCategoryMap[chatRoomId] = cat["name"]; // Lưu ID chat vào đúng cái thư mục này
                    onUpdate();
                    Navigator.pop(c);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã gắn thẻ: ${cat["name"]}")));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}