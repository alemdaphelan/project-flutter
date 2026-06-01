import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'profile_setup_screen.dart';
import 'login_screen.dart';

/// Màn hình chờ xác minh email.
/// Hiển thị sau khi đăng ký thành công — user cần nhấp link trong email.
/// Tự động kiểm tra mỗi 3 giây và chuyển vào app khi email đã được xác minh.
class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();

  Timer? _checkTimer;
  bool _isResending = false;
  bool _isChecking = false;
  int _resendCountdown = 0; // 0 = có thể gửi lại
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Tự động kiểm tra mỗi 3 giây
    _startAutoCheck();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Tự động poll Firebase mỗi 3 giây để kiểm tra email đã verify chưa
  void _startAutoCheck() {
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      final verified = await _authService.checkEmailVerified();
      if (verified && mounted) {
        _checkTimer?.cancel();
        _onEmailVerified();
      }
    });
  }

  /// Khi email đã được xác minh → vào ProfileSetup
  void _onEmailVerified() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email đã được xác minh! Chào mừng bạn.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      (route) => false,
    );
  }

  /// Kiểm tra thủ công khi user nhấn nút
  Future<void> _checkManually() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    try {
      final verified = await _authService.checkEmailVerified();
      if (!mounted) return;
      if (verified) {
        _checkTimer?.cancel();
        _onEmailVerified();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email chưa được xác minh. Vui lòng kiểm tra hộp thư.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  /// Gửi lại email xác minh
  Future<void> _resendEmail() async {
    if (_isResending || _resendCountdown > 0) return;
    setState(() => _isResending = true);
    try {
      await _authService.resendVerificationEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gửi lại email xác minh đến ${widget.email}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Đếm ngược 60 giây trước khi cho gửi lại
      _startResendCountdown();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _startResendCountdown() {
    setState(() => _resendCountdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          _resendCountdown = 0;
          timer.cancel();
        }
      });
    });
  }

  /// Huỷ đăng ký và quay về màn hình đăng nhập
  Future<void> _cancelAndGoBack() async {
    _checkTimer?.cancel();
    // Xoá tài khoản chưa verify để tránh tài khoản rác
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.delete();
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _cancelAndGoBack();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Xác minh Email'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _cancelAndGoBack,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // Icon email
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 72,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Xác minh Email của bạn',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Email được gửi đến
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.email_outlined,
                        color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Chúng tôi đã gửi email xác minh đến địa chỉ trên.\n'
                'Vui lòng mở email và nhấp vào link xác minh để kích hoạt tài khoản.',
                style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              const Text(
                'Nếu không thấy email, hãy kiểm tra thư mục Spam hoặc Junk.',
                style: TextStyle(fontSize: 13, color: Colors.orange),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Đang tự động kiểm tra
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Đang chờ xác minh...',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Nút kiểm tra thủ công
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : _checkManually,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isChecking ? 'Đang kiểm tra...' : 'Tôi đã xác minh rồi',
                    style: const TextStyle(fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Nút gửi lại email
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed:
                      (_isResending || _resendCountdown > 0) ? null : _resendEmail,
                  icon: _isResending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _isResending
                        ? 'Đang gửi...'
                        : _resendCountdown > 0
                            ? 'Gửi lại sau $_resendCountdown giây'
                            : 'Gửi lại email xác minh',
                    style: const TextStyle(fontSize: 15),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Huỷ và quay lại
              TextButton(
                onPressed: _cancelAndGoBack,
                child: const Text(
                  'Huỷ và quay lại đăng nhập',
                  style: TextStyle(color: Colors.grey),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}