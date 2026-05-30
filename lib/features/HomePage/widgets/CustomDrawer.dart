import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_flutter/features/login-register/screens/login_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy user đang đăng nhập hiện tại
    final user = FirebaseAuth.instance.currentUser;
    
    final String userName = user?.displayName ?? "Người Dùng Mới"; 
    final String userEmail = user?.email ?? "Chưa có email";
    final String userAvatar = user?.photoURL ?? "https://via.placeholder.com/150";

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Đã xóa const và truyền userAvatar động vào
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(userAvatar),
                  ),
                  const SizedBox(width: 12),
                  // Đã xóa const và truyền userName, userEmail vào
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildDrawerItem(Icons.settings_outlined, 'Cài đặt chung'),
            const Divider(height: 1),
            _buildDrawerItem(Icons.bookmark_border, 'Bài viết đã lưu'),
            const Divider(height: 1),
            _buildDrawerItem(Icons.help_outline, 'Trợ giúp và hỗ trợ'),
            const Divider(height: 1),
            _buildDrawerItem(Icons.lock_outline, 'Quyền riêng tư'),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context); // Đóng Drawer lại trước
                
                // Gọi lệnh Đăng xuất của Firebase
                await FirebaseAuth.instance.signOut(); 
                
                // Đẩy văng người dùng về lại trang Login
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false, 
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      onTap: () {},
    );
  }
}