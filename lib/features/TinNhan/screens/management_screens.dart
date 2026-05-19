import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_extension_service.dart';
import '../services/firebase_chat_service.dart';
import '../models/chat_room.dart';
import 'chat_screen.dart';

// ==========================================
// 1. MÀN HÌNH QUẢN LÝ PHÂN LOẠI
// ==========================================
class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);
  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  void _addNewCategory() {
    TextEditingController catController = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Thêm phân loại mới"),
        content: TextField(controller: catController, decoration: const InputDecoration(hintText: "Tên phân loại (vd: Khách VIP)")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              if (catController.text.isNotEmpty) {
                setState(() {
                  ChatExtensionService.categories.add({"name": catController.text.trim(), "color": Colors.green});
                });
                Navigator.pop(c);
              }
            },
            child: const Text("Lưu"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý phân loại")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ChatExtensionService.categories.length,
        itemBuilder: (context, index) {
          final cat = ChatExtensionService.categories[index];
          return Card(
            child: ListTile(
              leading: Icon(Icons.folder, color: cat["color"]),
              title: Text(cat["name"]),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CategorizedChatsScreen(categoryName: cat["name"])));
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(backgroundColor: const Color(0xFFFFCE00), onPressed: _addNewCategory, child: const Icon(Icons.add, color: Colors.black)),
    );
  }
}

// MÀN HÌNH XEM DANH SÁCH CHAT TRONG 1 PHÂN LOẠI
class CategorizedChatsScreen extends StatelessWidget {
  final String categoryName;
  const CategorizedChatsScreen({Key? key, required this.categoryName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Phân loại: $categoryName")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseChatService().getChatRoomsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var rooms = snapshot.data!.docs.map((d) => ChatRoom.fromFirestore(d)).toList();
          rooms = rooms.where((r) => ChatExtensionService.chatCategoryMap[r.id] == categoryName).toList();

          if (rooms.isEmpty) return const Center(child: Text("Chưa có hội thoại nào trong thư mục này"));

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (c, i) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(rooms[i].otherUserName),
              subtitle: Text(rooms[i].lastMessage, maxLines: 1),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChatScreen(chatRoomId: rooms[i].id))),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 2. MÀN HÌNH CÀI ĐẶT TRẢ LỜI TỰ ĐỘNG
// ==========================================
class AutoReplySettingsScreen extends StatefulWidget {
  const AutoReplySettingsScreen({Key? key}) : super(key: key);
  @override
  State<AutoReplySettingsScreen> createState() => _AutoReplySettingsScreenState();
}

class _AutoReplySettingsScreenState extends State<AutoReplySettingsScreen> {
  late bool _isAutoReplyEnabled;
  late TextEditingController _replyController;

  @override
  void initState() {
    super.initState();
    _isAutoReplyEnabled = ChatExtensionService.isAutoReplyEnabled;
    _replyController = TextEditingController(text: ChatExtensionService.autoReplyText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trả lời tự động")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text("Bật trả lời tự động"),
              value: _isAutoReplyEnabled,
              onChanged: (val) => setState(() => _isAutoReplyEnabled = val),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _replyController, maxLines: 4, enabled: _isAutoReplyEnabled,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Nhập nội dung..."),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFFFFCE00)),
              onPressed: () {
                ChatExtensionService.isAutoReplyEnabled = _isAutoReplyEnabled;
                ChatExtensionService.autoReplyText = _replyController.text;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu cài đặt!")));
                Navigator.pop(context);
              },
              child: const Text("Lưu thay đổi", style: TextStyle(color: Colors.black)),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. MÀN HÌNH QUẢN LÝ TIN NHẮN NHANH
// ==========================================
class QuickMessageManagementScreen extends StatelessWidget {
  const QuickMessageManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tin nhắn nhanh")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: ListTile(title: const Text("/diachi"), subtitle: const Text("Địa chỉ shop ở 140 Lê Trọng Tấn..."), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: (){}))),
          Card(child: ListTile(title: const Text("/stk"), subtitle: const Text("Vietcombank: 123456789 - Nguyễn Văn A"), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: (){}))),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: const Color(0xFFFFCE00), icon: const Icon(Icons.add, color: Colors.black), label: const Text("Thêm mẫu", style: TextStyle(color: Colors.black)), onPressed: () {}),
    );
  }
}

// ==========================================
// 4. MÀN HÌNH HỘI THOẠI ĐÃ ẨN
// ==========================================
class HiddenChatsScreen extends StatefulWidget {
  const HiddenChatsScreen({Key? key}) : super(key: key);
  @override
  State<HiddenChatsScreen> createState() => _HiddenChatsScreenState();
}

class _HiddenChatsScreenState extends State<HiddenChatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hội thoại đã ẩn")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseChatService().getChatRoomsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var rooms = snapshot.data!.docs.map((d) => ChatRoom.fromFirestore(d)).toList();
          rooms = rooms.where((r) => ChatExtensionService.hiddenChatIds.contains(r.id)).toList();

          if (rooms.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.visibility_off, size: 80, color: Colors.grey[300]), const SizedBox(height: 16), const Text("Không có hội thoại nào bị ẩn", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold))]));
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (c, i) => ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
              title: Text(rooms[i].otherUserName),
              subtitle: Text(rooms[i].lastMessage, maxLines: 1),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCE00)),
                onPressed: () {
                  setState(() {
                    ChatExtensionService.hiddenChatIds.remove(rooms[i].id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã khôi phục hội thoại ra màn hình chính!")));
                },
                child: const Text("Bỏ ẩn", style: TextStyle(color: Colors.black)),
              ),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChatScreen(chatRoomId: rooms[i].id))),
            ),
          );
        },
      ),
    );
  }
}