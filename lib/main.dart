/*import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:project_flutter/firebase_options.dart';
import 'package:project_flutter/features/HomePage/screens/MainScreen.dart';
import 'package:project_flutter/features/login-register/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 4. Firebase đã ready, bây giờ mới được phép vẽ UI!
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Lỗi khởi tạo Firebase: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color oldieTeal = Color(0xFF1B6B60);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Selling App',
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
      home: const LoginScreen(), // Màn hình đầu tiên là Login
    );
  }
}
*/
import 'package:flutter/material.dart';
import 'package:project_flutter/features/HomePage/screens/MainScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:project_flutter/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 4. Firebase đã ready, bây giờ mới được phép vẽ UI!
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Lỗi khởi tạo Firebase: $e');
  }
}

// test main screen of home page without login screen
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Selling App',
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
      home: const MainScreen(),
    );
  }
}
