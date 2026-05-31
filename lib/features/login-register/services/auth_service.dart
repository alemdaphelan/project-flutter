import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_flutter/shared/models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ====================== EMAIL/PASSWORD ======================

  /// Đăng nhập bằng email + password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('Không tìm thấy tài khoản với email này.');
        case 'wrong-password':
        case 'invalid-credential':
          throw Exception('Mật khẩu không đúng. Vui lòng kiểm tra lại.');
        case 'invalid-email':
          throw Exception('Email không hợp lệ.');
        case 'user-disabled':
          throw Exception('Tài khoản này đã bị vô hiệu hóa.');
        default:
          throw Exception(e.message ?? 'Đăng nhập thất bại.');
      }
    }
  }

  /// Đăng ký bằng email + password
  /// Không cần sync Firestore ở đây — ProfileSetupScreen sẽ tạo document
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception(
              'Email này đã được sử dụng. Vui lòng đăng nhập hoặc dùng email khác.');
        case 'invalid-email':
          throw Exception('Email không hợp lệ.');
        case 'weak-password':
          throw Exception('Mật khẩu quá yếu. Cần ít nhất 6 ký tự.');
        case 'operation-not-allowed':
          throw Exception(
              'Chức năng đăng ký bằng Email chưa được bật trong Firebase Console.');
        default:
          throw Exception(e.message ?? 'Đăng ký thất bại.');
      }
    }
  }

  // ====================== SOCIAL LOGIN ======================

  /// Đăng nhập bằng Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User tự hủy

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      // Sync thông tin từ Google vào Firestore
      if (user != null) {
        await syncUserToFirestore(user);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Đăng nhập Google thất bại.');
    } catch (e) {
      throw Exception('Đăng nhập Google thất bại: $e');
    }
  }

  /// Đăng nhập bằng Facebook
  Future<User?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.cancelled) {
        return null; // User tự hủy — không throw exception
      }

      if (result.status != LoginStatus.success) {
        throw Exception('Đăng nhập Facebook thất bại: ${result.message}');
      }

      final token = result.accessToken;
      if (token == null) {
        throw Exception('Không lấy được Access Token từ Facebook.');
      }

      final OAuthCredential credential = FacebookAuthProvider.credential(
        token.tokenString,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      // Sync thông tin từ Facebook vào Firestore
      if (user != null) {
        await syncUserToFirestore(user);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception(
              'Email này đã được đăng ký bằng phương thức khác (Google hoặc Email/Password).');
        default:
          throw Exception('Lỗi Firebase: ${e.message}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Đồng bộ thông tin từ Firebase Auth (Google/Facebook) vào Firestore.
  /// - Lần đầu login: tạo document mới với đầy đủ thông tin từ provider
  /// - Đã có document: chỉ fill những field đang rỗng, KHÔNG ghi đè
  ///   dữ liệu user đã tự chỉnh sửa trong ProfileSetupScreen
  Future<void> syncUserToFirestore(User user) async {
    try {
      final ref = _firestore.collection('users').doc(user.uid);
      final doc = await ref.get();

      if (!doc.exists) {
        // Lần đầu đăng nhập Social → tạo document mới
        // hasCompletedProfile = false → app sẽ đẩy vào ProfileSetupScreen
        // để user bổ sung thêm thông tin (địa chỉ, bio, sở thích...)
        await ref.set({
          'displayName': user.displayName ?? '',
          'email': user.email ?? '',
          'avatarUrl': user.photoURL ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'hasCompletedProfile': false,
          'averageRating': 0.0,
          'totalReviews': 0,
          'interests': [],
          'bio': '',
          'location': '',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Đã có document → chỉ cập nhật field đang rỗng/null
        final data = doc.data()!;
        final updates = <String, dynamic>{};

        if ((data['displayName'] ?? '').toString().isEmpty &&
            (user.displayName ?? '').isNotEmpty) {
          updates['displayName'] = user.displayName;
        }
        if ((data['email'] ?? '').toString().isEmpty &&
            (user.email ?? '').isNotEmpty) {
          updates['email'] = user.email;
        }
        if ((data['avatarUrl'] ?? '').toString().isEmpty &&
            (user.photoURL ?? '').isNotEmpty) {
          updates['avatarUrl'] = user.photoURL;
        }

        if (updates.isNotEmpty) {
          updates['updatedAt'] = FieldValue.serverTimestamp();
          await ref.update(updates);
        }
      }
    } catch (e) {
      // Không throw — lỗi sync không được chặn luồng đăng nhập
      print('[syncUserToFirestore] Lỗi: $e');
    }
  }

  // ====================== PHONE AUTH (OTP THẬT) ======================

  String? _verificationId;
  int? _resendToken;

  /// Gửi OTP thật đến số điện thoại (Firebase Phone Auth)
  /// [phoneNumber] phải có định dạng quốc tế, ví dụ: +84912345678
  Future<void> sendPhoneOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Android tự động xác minh SMS (không cần nhập OTP thủ công)
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        String msg;
        switch (e.code) {
          case 'invalid-phone-number':
            msg = 'Số điện thoại không hợp lệ. Vui lòng nhập đúng định dạng.';
            break;
          case 'too-many-requests':
            msg = 'Quá nhiều yêu cầu OTP. Vui lòng thử lại sau ít phút.';
            break;
          case 'quota-exceeded':
            msg = 'Hết hạn mức gửi SMS hôm nay. Vui lòng thử lại ngày mai.';
            break;
          default:
            msg = e.message ?? 'Gửi OTP thất bại.';
        }
        onError(msg);
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  /// Xác minh OTP và đăng nhập/liên kết tài khoản
  Future<User?> verifyPhoneOTP(String smsCode) async {
    if (_verificationId == null) {
      throw Exception('Chưa gửi OTP. Vui lòng yêu cầu gửi lại.');
    }
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode.trim(),
      );
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-verification-code':
          throw Exception('Mã OTP không đúng. Vui lòng kiểm tra lại.');
        case 'session-expired':
          throw Exception('Mã OTP đã hết hạn. Vui lòng yêu cầu gửi lại.');
        default:
          throw Exception(e.message ?? 'Xác minh OTP thất bại.');
      }
    }
  }

  // ====================== QUÊN MẬT KHẨU ======================

  /// Gửi OTP để reset mật khẩu
  /// - Nếu là số điện thoại: gửi SMS OTP thật qua Firebase
  /// - Nếu là email: gửi link đặt lại mật khẩu thật qua Firebase
  Future<void> sendPasswordResetOTP({
    required String identifier,
    required bool isPhone,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    if (isPhone) {
      final formattedPhone = _formatVietnamPhone(identifier);
      await sendPhoneOTP(
        phoneNumber: formattedPhone,
        onCodeSent: onCodeSent,
        onError: onError,
      );
    } else {
      try {
        await _auth.sendPasswordResetEmail(email: identifier.trim());
        onCodeSent('EMAIL_RESET_SENT');
      } on FirebaseAuthException catch (e) {
        switch (e.code) {
          case 'user-not-found':
            onError('Không tìm thấy tài khoản với email này.');
            break;
          case 'invalid-email':
            onError('Email không hợp lệ.');
            break;
          default:
            onError(e.message ?? 'Gửi email thất bại.');
        }
      }
    }
  }

  /// Xác minh OTP reset mật khẩu (chỉ dùng cho phone)
  Future<User?> verifyResetOTP(String smsCode) async {
    return await verifyPhoneOTP(smsCode);
  }

  /// Format số điện thoại Việt Nam sang +84...
  String _formatVietnamPhone(String phone) {
    phone = phone.trim().replaceAll(' ', '').replaceAll('-', '');
    if (phone.startsWith('0') && phone.length == 10) {
      return '+84${phone.substring(1)}';
    }
    if (phone.startsWith('+84')) {
      return phone;
    }
    if (phone.startsWith('84') && phone.length == 11) {
      return '+$phone';
    }
    return phone;
  }

  // ====================== ĐỔI MẬT KHẨU ======================

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập.');
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'requires-recent-login':
          throw Exception(
              'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại để đổi mật khẩu.');
        case 'weak-password':
          throw Exception('Mật khẩu quá yếu. Cần ít nhất 6 ký tự.');
        default:
          throw Exception(e.message ?? 'Đổi mật khẩu thất bại.');
      }
    }
  }

  // ====================== ĐĂNG XUẤT ======================

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        FacebookAuth.instance.logOut(),
      ]);
    } catch (e) {
      // Bỏ qua lỗi khi đăng xuất
    }
  }

  // ====================== USER PROFILE ======================

  /// Kiểm tra user đã hoàn thành profile chưa
  Future<bool> hasCompletedProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists && (doc.data()?['hasCompletedProfile'] == true);
    } catch (e) {
      return false;
    }
  }

  /// Lưu profile người dùng lên Firestore
  Future<void> saveUserProfile(String uid, UserProfile profile) async {
    await _firestore.collection('users').doc(uid).set(
      profile.toMap(),
      SetOptions(merge: true),
    );
  }

  /// Lấy profile người dùng từ Firestore
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ====================== HELPERS ======================

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}