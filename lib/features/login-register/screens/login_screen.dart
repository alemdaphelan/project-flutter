import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'otp_screen.dart';
import 'profile_setup_screen.dart';
import 'email_verification_screen.dart';
import 'package:project_flutter/features/HomePage/screens/MainScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isEmailMode = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ====================== VALIDATE ======================

  String? _validateEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Vui lòng nhập email';

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Email không đúng định dạng (ví dụ: abc@gmail.com)';
    }

    if (trimmed.contains('..') || trimmed.startsWith('.') || trimmed.endsWith('.')) {
      return 'Email không hợp lệ';
    }

    final parts = trimmed.split('@');
    if (parts.length != 2) return 'Email không hợp lệ';
    final domain = parts[1];
    if (!domain.contains('.')) return 'Domain email không hợp lệ';

    return null;
  }

  /// Validate số điện thoại — bắt buộc đúng 10 số, chỉ chữ số
  String? _validatePhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Vui lòng nhập số điện thoại';

    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'Số điện thoại chỉ được chứa chữ số (0-9)';
    }

    if (trimmed.length != 10) {
      return 'Số điện thoại phải có đúng 10 số (bạn nhập ${trimmed.length} số)';
    }

    final phoneRegex = RegExp(r'^(0[3-9][0-9]{8})$');
    if (!phoneRegex.hasMatch(trimmed)) {
      return 'Số điện thoại không hợp lệ.\nPhải bắt đầu bằng 03x, 05x, 07x, 08x hoặc 09x';
    }

    return null;
  }

  String? _validateIdentifier(String value) {
    return _isEmailMode ? _validateEmail(value) : _validatePhone(value);
  }

  // ====================== ĐIỀU HƯỚNG SAU LOGIN ======================

  Future<void> _navigateAfterLogin(User user) async {
    final hasProfile = await _authService.hasCompletedProfile(user.uid);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            hasProfile ? MainScreen(user: user) : const ProfileSetupScreen(),
      ),
      (route) => false,
    );
  }

  // ====================== ĐĂNG NHẬP EMAIL ======================

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    final identifierError = _validateIdentifier(identifier);
    if (identifierError != null) {
      _showSnackBar(identifierError);
      return;
    }
    if (password.isEmpty) {
      _showSnackBar('Vui lòng nhập mật khẩu');
      return;
    }
    if (password.length < 6) {
      _showSnackBar('Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithEmail(identifier, password);
      if (user != null && mounted) {
        await _navigateAfterLogin(user);
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');

      // Nếu lỗi là chưa xác minh email → đưa về màn xác minh
      if (msg.contains('chưa được xác minh') || msg.contains('xác minh')) {
        if (mounted) {
          _showSnackBar(msg);
          // Sau 1 giây đẩy sang màn chờ verify
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    EmailVerificationScreen(email: identifier),
              ),
            );
          }
        }
      } else {
        _showSnackBar(msg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ====================== ĐĂNG NHẬP BẰNG SĐT ======================

  Future<void> _handlePhoneLogin() async {
    final phone = _identifierController.text.trim();
    final phoneError = _validatePhone(phone);
    if (phoneError != null) {
      _showSnackBar(phoneError);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OTPScreen(
          identifier: phone,
          isPhone: true,
          isPasswordReset: false,
        ),
      ),
    );
  }

  // ====================== QUÊN MẬT KHẨU ======================

  Future<void> _handleForgotPassword() async {
    final identifier = _identifierController.text.trim();

    if (identifier.isEmpty) {
      _showSnackBar(
        _isEmailMode
            ? 'Vui lòng nhập email trước khi yêu cầu đặt lại mật khẩu'
            : 'Vui lòng nhập số điện thoại trước khi yêu cầu OTP',
      );
      return;
    }

    final identifierError = _validateIdentifier(identifier);
    if (identifierError != null) {
      _showSnackBar(identifierError);
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text(
          !_isEmailMode
              ? 'Gửi mã OTP đến số điện thoại:\n$identifier'
              : 'Gửi link đặt lại mật khẩu đến email:\n$identifier',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OTPScreen(
                    identifier: identifier,
                    isPhone: !_isEmailMode,
                    isPasswordReset: true,
                  ),
                ),
              );
            },
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
  }

  // ====================== ĐĂNG NHẬP SOCIAL ======================

  Future<void> _socialLogin(String provider) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Tiếp tục với $provider'),
        content: Text('Bạn có muốn đăng nhập bằng $provider không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (!mounted) return;
              setState(() => _isLoading = true);

              try {
                User? user;
                if (provider == 'Google') {
                  user = await _authService.signInWithGoogle();
                } else if (provider == 'Facebook') {
                  user = await _authService.signInWithFacebook();
                }

                if (user != null && mounted) {
                  await _navigateAfterLogin(user);
                }
              } catch (e) {
                final msg = e.toString().replaceAll('Exception: ', '');
                if (mounted) _showSnackBar(msg);
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
  }

  // ====================== HELPERS ======================

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
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tab Đăng nhập / Đăng ký
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Đăng nhập'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text('Đăng ký'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Toggle Email / Số điện thoại
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEmailMode = true;
                        _identifierController.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _isEmailMode ? Colors.blue : Colors.grey,
                            width: _isEmailMode ? 2 : 1,
                          ),
                        ),
                      ),
                      child: Text(
                        'Email',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isEmailMode ? Colors.blue : Colors.grey,
                          fontWeight: _isEmailMode
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEmailMode = false;
                        _identifierController.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: !_isEmailMode ? Colors.blue : Colors.grey,
                            width: !_isEmailMode ? 2 : 1,
                          ),
                        ),
                      ),
                      child: Text(
                        'Số điện thoại',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !_isEmailMode ? Colors.blue : Colors.grey,
                          fontWeight: !_isEmailMode
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Input Email hoặc SĐT
            if (_isEmailMode)
              TextField(
                controller: _identifierController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                  hintText: 'example@gmail.com',
                ),
              )
            else
              TextField(
                controller: _identifierController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                // Chặn hoàn toàn ký tự không phải số
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại (10 số)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  counterText: '',
                  hintText: '0912345678',
                  helperText: 'Đúng 10 chữ số, bắt đầu bằng 0',
                ),
              ),

            const SizedBox(height: 16),

            // Chỉ hiện password khi đăng nhập bằng email
            if (_isEmailMode) ...[
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  child: const Text('Quên mật khẩu?'),
                ),
              ),
            ],

            // Thông tin khi đăng nhập bằng SĐT
            if (!_isEmailMode) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nhập số điện thoại, chúng tôi sẽ gửi mã OTP để xác minh.',
                        style: TextStyle(color: Colors.blue, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 8),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _isEmailMode ? _handleLogin : _handlePhoneLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _isEmailMode ? 'ĐĂNG NHẬP' : 'GỬI MÃ OTP',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),

            const SizedBox(height: 24),

            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Hoặc đăng nhập với'),
                ),
                Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 16),

            _buildSocialButton(
              'Google',
              Colors.red,
              Icons.g_mobiledata,
              () => _socialLogin('Google'),
            ),
            const SizedBox(height: 10),
            _buildSocialButton(
              'Facebook',
              const Color(0xFF1877F2),
              Icons.facebook,
              () => _socialLogin('Facebook'),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Chưa có tài khoản?'),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text('Đăng ký ngay'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    String text,
    Color color,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        'Tiếp tục với $text',
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
      ),
    );
  }
}