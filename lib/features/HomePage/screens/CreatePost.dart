import 'package:flutter/material.dart';

class CreatePostScreen extends StatelessWidget {
  final Color primaryTeal = const Color(0xFF1B6B60);
  final Color bgColor = const Color(0xFFF2F8F7);

  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Oldie',
              style: TextStyle(
                color: primaryTeal,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Text(
          'Tạo bài viết mới',
          style: TextStyle(fontSize: 24, color: primaryTeal),
        ),
      ),
    );
  }
}
