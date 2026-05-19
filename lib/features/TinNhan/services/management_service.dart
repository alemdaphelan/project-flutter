import 'package:flutter/material.dart';
// Import file chứa các màn hình quản lý (anh sẽ tạo ở Bước 2)
import '../screens/management_screens.dart';

class ManagementService {
  void manageCategories(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
    );
  }

  void setupAutoReply(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AutoReplySettingsScreen()),
    );
  }

  void manageQuickMessages(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuickMessageManagementScreen()),
    );
  }

  void showHiddenChats(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HiddenChatsScreen()),
    );
  }
}