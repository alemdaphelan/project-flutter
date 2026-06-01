import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_flutter/features/login-register/screens/login_screen.dart';
import 'package:project_flutter/features/HomePage/screens/edit_profile_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final String userName = user?.displayName ?? 'Người Dùng Mới';
    final String userEmail = user?.email ?? 'Chưa có email';
    final String? userAvatar = user?.photoURL;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B6B60), Color(0xFF2E9B8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Điều hướng đến UserProfile screen ở đây
                      // Navigator.push(context, MaterialPageRoute(
                      //   builder: (_) => UserProfileScreen(userId: user?.uid ?? ''),
                      // ));
                    },
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      backgroundImage:
                          (userAvatar != null && userAvatar.isNotEmpty)
                          ? NetworkImage(userAvatar)
                          : null,
                      child: (userAvatar == null || userAvatar.isEmpty)
                          ? Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Tên + email
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Điều hướng đến UserProfile screen
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Nút xem trang cá nhân
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            child: const Text(
                              'Xem trang cá nhân →',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Nút đóng
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Menu chính ──
            _buildSectionLabel('Tài khoản'),

            _buildDrawerItem(
              icon: Icons.manage_accounts_outlined,
              title: 'Chỉnh sửa thông tin cá nhân',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.account_balance_outlined,
              title: 'Tài khoản ngân hàng',
              subtitle: 'Dùng để nhận thanh toán VietQR',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditProfileScreen(
                      initialTab: EditProfileTab.bankAccount,
                    ),
                  ),
                );
              },
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildSectionLabel('Khám phá'),

            _buildDrawerItem(
              icon: Icons.bookmark_border,
              title: 'Bài viết đã lưu',
              onTap: () {
                Navigator.pop(context);
                // TODO: điều hướng đến SavedPosts
              },
            ),

            _buildDrawerItem(
              icon: Icons.history,
              title: 'Lịch sử mua hàng',
              onTap: () {
                Navigator.pop(context);
                // TODO: điều hướng đến OrdersHub
              },
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildSectionLabel('Hỗ trợ'),

            _buildDrawerItem(
              icon: Icons.help_outline,
              title: 'Trợ giúp và hỗ trợ',
              onTap: () => Navigator.pop(context),
            ),

            _buildDrawerItem(
              icon: Icons.lock_outline,
              title: 'Quyền riêng tư',
              onTap: () => Navigator.pop(context),
            ),

            _buildDrawerItem(
              icon: Icons.settings_outlined,
              title: 'Cài đặt chung',
              onTap: () => Navigator.pop(context),
            ),

            const Spacer(),
            const Divider(height: 1),

            // ── Đăng xuất ──
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1B6B60), size: 22),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            )
          : null,
      onTap: onTap,
      dense: subtitle == null,
      horizontalTitleGap: 8,
    );
  }
}
