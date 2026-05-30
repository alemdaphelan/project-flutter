import 'package:flutter/material.dart';
import 'package:project_flutter/firestore_service.dart';
import 'package:project_flutter/features/HomePage/widgets/CategorySelector.dart';
import 'package:project_flutter/features/HomePage/widgets/CustomDrawer.dart';
import 'package:project_flutter/features/TinNhan/screens/management_screens.dart';
import 'package:project_flutter/features/HomePage/widgets/ProductList.dart';
import 'package:project_flutter/features/HomePage/screens/Notification.dart';
import 'package:project_flutter/features/HomePage/screens/CreatePost.dart';

//moi them
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_flutter/features/login-register/screens/login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  bool _isSearching = false;
  final FirestoreService firestore = FirestoreService();
  late Future<List<Map<String, dynamic>>> categories;

  @override
  void initState() {
    super.initState();
    categories = firestore.getCategories();
  }

  void _onItemTapped(int index) async {
    if (index == 1) {
      setState(() {
        _selectedIndex = index;
      });
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OrderScreen()),
      );

      setState(() => _selectedIndex = 0);
    } else if (index == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreatePostScreen()),
      );
      setState(() {
        _selectedIndex = index;
      });
    } else if (index == 3) {
      setState(() {
        _selectedIndex = index;
      });
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
      );
      setState(() => _selectedIndex = 0);
    } else if (index == 4) {
      setState(() {
        _selectedIndex = index;
      });
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotificationScreen(notifications: []),
        ),
      );
      setState(() => _selectedIndex = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F9F6),
      drawer: const CustomDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Nhập tên sản phẩm...',
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() {}),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'O',
                    style: TextStyle(
                      color: Color(0xFF4C9A82),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ldie',
                    style: TextStyle(
                      color: Color(0xFF2A5C8D),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _showProfileOptions(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4C9A82)),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải danh mục: ${snapshot.error}'));
          }
          final List<Map<String, dynamic>> loadedCategories =
              snapshot.data != null && snapshot.data!.isNotEmpty
              ? snapshot.data!
              : [
                  {'name': 'All', 'icon': 'all'},
                ];
          if (_selectedCategoryIndex >= loadedCategories.length) {
            _selectedCategoryIndex = 0;
          }
          String currentCategoryName =
              loadedCategories[_selectedCategoryIndex]['name'] ?? 'All';

          return SingleChildScrollView(
            child: Column(
              children: [
                CategorySelector(
                  categories: loadedCategories,
                  selectedIndex: _selectedCategoryIndex,
                  onCategorySelected: (index) {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                  },
                ),
                const SizedBox(height: 10),
                ProductList(
                  firestore: firestore,
                  searchQuery: _searchController.text,
                  selectedCategory: currentCategoryName,
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4C9A82),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.check_box_outlined),
            label: 'Đơn hàng',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.add), label: "Thêm"),
          const BottomNavigationBarItem(
            icon: Icon(Icons.mail_outline),
            label: 'Tin nhắn',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(color: Colors.white, fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            label: 'Thông báo',
          ),
        ],
      ),
    );
  }

  void _showProfileOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Chỉnh sửa thông tin cá nhân'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context); // Đóng menu dưới lên

                // Gọi lệnh Đăng xuất của Firebase
                await FirebaseAuth.instance.signOut();

                // Đẩy văng người dùng về lại trang Login
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) =>
                        false, // Xóa sạch lịch sử trang, không cho lùi lại
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn hàng của tôi')),
      body: const Center(
        child: Text('Tính năng quản lý đơn hàng sẽ được phát triển sau!'),
      ),
    );
  }
}
