import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class MainScreen_Auth extends StatefulWidget {
  const MainScreen_Auth({super.key});

  @override
  State<MainScreen_Auth> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen_Auth> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _logout() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signOut();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đăng xuất thất bại: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _isLoading ? null : _logout,
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Chào mừng bạn đến với MainScreen!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Bạn đã đăng nhập thành công',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
