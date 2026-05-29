import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'otp_screen.dart';
import 'main_screen.dart';
import 'profile_setup_screen.dart';

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
  bool _isEmailMode = true; // true = Email, false = Số điện thoại

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ====================== VALIDATE ======================

  String? _validateIdentifier(String value) {
    if (value.trim().isEmpty) {
      return _isEmailMode
          ? 'Vui lòng nhập email'
          : 'Vui lòng nhập số điện thoại';
    }
    if (_isEmailMode) {
      final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-z]{2,}$');
      if (!emailRegex.hasMatch(value.trim())) {
        return 'Email không đúng định dạng (ví dụ: abc@gmail.com)';
      }
    } else {
      final phoneRegex = RegExp(r'^(0[3-9][0-9]{8})$');
      if (!phoneRegex.hasMatch(value.trim())) {
        return 'Số điện thoại phải có đúng 10 số và bắt đầu bằng 0';
      }
    }
    return null;
  }

  // ====================== ĐIỀU HƯỚNG SAU LOGIN ======================

  /// Kiểm tra profile và điều hướng phù hợp
  Future<void> _navigateAfterLogin(User user) async {
    final hasProfile = await _authService.hasCompletedProfile(user.uid);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => hasProfile
            ? const MainScreen()
            : const ProfileSetupScreen(),
      ),
      (route) => false,
    );
  }

  // ====================== ĐĂNG NHẬP EMAIL/PHONE ======================

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    // Validate
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
      User? user;
      if (_isEmailMode) {
        user = await _authService.signInWithEmail(identifier, password);
      } else {
        // Đăng nhập bằng số điện thoại dùng Phone Auth
        // Chuyển sang màn hình OTP để xác minh
        _showSnackBar('Đăng nhập bằng số điện thoại yêu cầu xác minh OTP');
        setState(() => _isLoading = false);
        return;
      }

      if (user != null) {
        await _navigateAfterLogin(user);
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

    final bool isPhone = !_isEmailMode;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text(
          isPhone
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
                    isPhone: isPhone,
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

                // null = user tự hủy → không làm gì
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
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
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
            TextField(
              controller: _identifierController,
              keyboardType: _isEmailMode
                  ? TextInputType.emailAddress
                  : TextInputType.phone,
              maxLength: _isEmailMode ? null : 10,
              decoration: InputDecoration(
                labelText: _isEmailMode ? 'Email' : 'Số điện thoại (10 số)',
                prefixIcon: Icon(
                  _isEmailMode ? Icons.email_outlined : Icons.phone_outlined,
                ),
                border: const OutlineInputBorder(),
                counterText: _isEmailMode ? null : '',
                hintText: _isEmailMode ? 'example@gmail.com' : '0912345678',
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

            // Nếu đăng nhập bằng SĐT, giải thích flow
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

            // Nút đăng nhập
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

  /// Đăng nhập bằng số điện thoại — chuyển sang màn OTP
  Future<void> _handlePhoneLogin() async {
    final phone = _identifierController.text.trim();
    final phoneRegex = RegExp(r'^(0[3-9][0-9]{8})$');
    if (!phoneRegex.hasMatch(phone)) {
      _showSnackBar('Số điện thoại phải có đúng 10 số và bắt đầu bằng 0');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OTPScreen(
          identifier: phone,
          isPhone: true,
          isPasswordReset: false, // Đây là đăng nhập, không phải reset
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