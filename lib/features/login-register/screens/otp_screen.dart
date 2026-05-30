import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'change_password_screen.dart';
import 'profile_setup_screen.dart';
import 'main_screen.dart';

class OTPScreen extends StatefulWidget {
  final String identifier; // Số điện thoại hoặc email
  final bool isPhone; // true = số điện thoại, false = email
  final bool isPasswordReset; // true = quên mật khẩu, false = đăng nhập/ký
  final String?
  passwordForPhoneRegister; // Mật khẩu khi đăng ký bằng SĐT (không dùng với Firebase Phone Auth)

  const OTPScreen({
    super.key,
    required this.identifier,
    required this.isPhone,
    required this.isPasswordReset,
    this.passwordForPhoneRegister,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otpController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isSending = true; // Đang gửi OTP lần đầu
  bool _canResend = false; // Có thể gửi lại không
  int _resendCountdown = 60; // Đếm ngược gửi lại

  // Dùng cho email reset — không cần nhập OTP
  bool _isEmailReset = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendOTP());
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  // ====================== GỬI OTP ======================

  Future<void> _sendOTP() async {
    if (!mounted) return;
    setState(() {
      _isSending = true;
      _canResend = false;
    });

    if (widget.isPhone) {
      // SĐT: gửi SMS OTP thật qua Firebase
      String formattedPhone = widget.identifier.trim();
      // Chuyển 0912345678 → +84912345678
      if (formattedPhone.startsWith('0') && formattedPhone.length == 10) {
        formattedPhone = '+84${formattedPhone.substring(1)}';
      }

      await _authService.sendPhoneOTP(
        phoneNumber: formattedPhone,
        onCodeSent: (verificationId) {
          if (mounted) {
            setState(() => _isSending = false);
            _showSnackBar('Đã gửi mã OTP đến ${widget.identifier}');
            _startResendCountdown();
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isSending = false);
            _showSnackBar(error);
          }
        },
      );
    } else {
      // Email: gửi link reset qua Firebase (không phải OTP 6 số)
      await _authService.sendPasswordResetOTP(
        identifier: widget.identifier,
        isPhone: false,
        onCodeSent: (result) {
          if (mounted && result == 'EMAIL_RESET_SENT') {
            setState(() {
              _isSending = false;
              _isEmailReset = true;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isSending = false);
            _showSnackBar(error);
          }
        },
      );
    }
  }

  void _startResendCountdown() {
    _resendCountdown = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) _canResend = true;
      });
      return _resendCountdown > 0 && mounted;
    });
  }

  // ====================== XÁC MINH OTP ======================

  Future<void> _verifyOTP() async {
    final code = _otpController.text.trim();

    if (code.length != 6) {
      _showSnackBar('Vui lòng nhập đủ 6 số OTP');
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = await _authService.verifyPhoneOTP(code);

      if (user == null) {
        _showSnackBar('Xác minh OTP thất bại. Vui lòng thử lại.');
        return;
      }

      if (!mounted) return;

      if (widget.isPasswordReset) {
        // Quên mật khẩu → vào màn đổi mật khẩu
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
        );
      } else {
        // Đăng nhập / đăng ký → kiểm tra profile
        final hasProfile = await _authService.hasCompletedProfile(user.uid);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                hasProfile ? MainScreen_Auth() : const ProfileSetupScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ====================== BUILD ======================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isPasswordReset ? 'Đặt lại mật khẩu' : 'Xác minh OTP',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isSending
            ? _buildSendingState()
            : _isEmailReset
            ? _buildEmailResetState()
            : _buildOTPInputState(),
      ),
    );
  }

  /// Đang gửi OTP
  Widget _buildSendingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Đang gửi mã OTP...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  /// Email reset — không cần nhập OTP, chỉ thông báo
  Widget _buildEmailResetState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Icon(
          Icons.mark_email_read_outlined,
          size: 80,
          color: Colors.blue,
        ),
        const SizedBox(height: 24),
        const Text(
          'Đã gửi email đặt lại mật khẩu!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Chúng tôi đã gửi link đặt lại mật khẩu đến:\n${widget.identifier}',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Vui lòng kiểm tra hộp thư (kể cả thư mục Spam) và nhấp vào link trong email để đặt lại mật khẩu.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        OutlinedButton.icon(
          onPressed: _sendOTP,
          icon: const Icon(Icons.refresh),
          label: const Text('Gửi lại email'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Quay lại đăng nhập'),
        ),
      ],
    );
  }

  /// Nhập OTP (cho số điện thoại)
  Widget _buildOTPInputState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.sms_outlined, size: 60, color: Colors.blue),
        const SizedBox(height: 20),
        Text(
          'Nhập mã OTP đã gửi đến\n${widget.identifier}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 32),

        // Input OTP
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            letterSpacing: 12,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            labelText: 'Mã OTP 6 số',
            border: OutlineInputBorder(),
            counterText: '',
            hintText: '------',
          ),
          onChanged: (value) {
            // Tự động xác minh khi nhập đủ 6 số
            if (value.length == 6 && !_isLoading) {
              _verifyOTP();
            }
          },
        ),

        const SizedBox(height: 32),

        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: _verifyOTP,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  'XÁC NHẬN',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),

        const SizedBox(height: 20),

        // Gửi lại OTP
        Center(
          child: _canResend
              ? TextButton.icon(
                  onPressed: () {
                    _otpController.clear();
                    _sendOTP();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Gửi lại mã OTP'),
                )
              : Text(
                  'Gửi lại sau $_resendCountdown giây',
                  style: const TextStyle(color: Colors.grey),
                ),
        ),
      ],
    );
  }
}
