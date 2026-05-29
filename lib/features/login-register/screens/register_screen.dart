import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';
import 'profile_setup_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();

  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isEmailMode = true; // true = đăng ký bằng email, false = số điện thoại

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ====================== VALIDATE ======================

  /// Validate email
  String? _validateEmail(String value) {
    if (value.trim().isEmpty) return 'Vui lòng nhập email';
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không đúng định dạng (ví dụ: abc@gmail.com)';
    }
    return null;
  }

  /// Validate số điện thoại Việt Nam (10 số, bắt đầu 03x, 05x, 07x, 08x, 09x)
  String? _validatePhone(String value) {
    if (value.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
    final phoneRegex = RegExp(r'^(0[3-9][0-9]{8})$');
    if (!phoneRegex.hasMatch(value.trim())) {
      if (value.trim().length != 10) {
        return 'Số điện thoại phải có đúng 10 số (bạn nhập ${value.trim().length} số)';
      }
      return 'Số điện thoại không hợp lệ. Phải bắt đầu bằng 03x, 05x, 07x, 08x hoặc 09x';
    }
    return null;
  }

  /// Validate mật khẩu
  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }

  // ====================== ĐĂNG KÝ ======================

  Future<void> _handleRegister() async {
    // Validate tất cả fields
    if (_isEmailMode) {
      final emailError = _validateEmail(_emailController.text);
      if (emailError != null) { _showSnackBar(emailError); return; }
    } else {
      final phoneError = _validatePhone(_phoneController.text);
      if (phoneError != null) { _showSnackBar(phoneError); return; }
    }

    final passwordError = _validatePassword(_passwordController.text);
    if (passwordError != null) { _showSnackBar(passwordError); return; }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEmailMode) {
        // Đăng ký bằng email → tạo tài khoản Firebase trực tiếp
        final user = await _authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (user != null && mounted) {
          // Đăng ký xong → vào ProfileSetup
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
            (route) => false,
          );
        }
      } else {
        // Đăng ký bằng số điện thoại → gửi OTP trước để xác minh
        // Sau khi xác minh OTP thành công sẽ tạo tài khoản tự động
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPScreen(
              identifier: _phoneController.text.trim(),
              isPhone: true,
              isPasswordReset: false,
              passwordForPhoneRegister: _passwordController.text,
            ),
          ),
        );
        setState(() => _isLoading = false);
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
      appBar: AppBar(title: const Text('Đăng ký tài khoản')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toggle Email / Số điện thoại
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isEmailMode = true),
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
                    onTap: () => setState(() => _isEmailMode = false),
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

            const SizedBox(height: 24),

            // Input tương ứng
            if (_isEmailMode)
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                  hintText: 'example@gmail.com',
                ),
              )
            else
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại (10 số)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  counterText: '',
                  hintText: '0912345678',
                  helperText: 'Nhập đúng 10 số, bắt đầu bằng 0',
                ),
              ),

            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: const OutlineInputBorder(),
                helperText: 'Ít nhất 6 ký tự',
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Xác nhận mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _isEmailMode ? 'ĐĂNG KÝ' : 'GỬI MÃ XÁC NHẬN',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Đã có tài khoản?'),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Đăng nhập ngay'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}