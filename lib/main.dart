import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // IMPORT FCM
import 'package:project_flutter/firebase_options.dart';
import 'package:project_flutter/features/login-register/screens/login_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("🔔 Nhận được thông báo ngầm: ${message.notification?.title}");
}

void main() async {
  // Chốt chặn 1: Đảm bảo Flutter Binding đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Chốt chặn 2: Khởi tạo lõi Firebase (dùng cấu hình của mày)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Chốt chặn 3: Đăng ký dịch vụ lắng nghe thông báo khi tắt app
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Chốt chặn 4: Xin quyền hệ điều hành (Bắt buộc cho iOS và Android 13+)
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Người dùng đã cấp quyền Push Notification');

      // Lấy Token: Mày mở Debug Console lên, copy cái chuỗi token này lại lát test nhé
      String? token = await messaging.getToken();
      debugPrint('📱 FCM Token của máy này: $token');
    } else {
      debugPrint('❌ Người dùng TỪ CHỐI cấp quyền');
    }

    // Mọi hệ thống nền đã sẵn sàng, bắt đầu vẽ UI
    runApp(const MyApp());
  } catch (e) {
    debugPrint('❌ Lỗi khởi tạo hệ thống: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oldie App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
