import 'package:flutter/material.dart';
import 'package:project_flutter/features/HomePage/screens/DetailListing.dart';
import 'package:project_flutter/features/HomePage/Models/ProductDetailModel.dart';
import 'package:project_flutter/features/HomePage/screens/UserProfile.dart';
import 'package:project_flutter/features/HomePage/Models/UserProfile.dart';
import 'package:project_flutter/features/HomePage/Models/Post.dart';
import 'package:project_flutter/features/HomePage/Models/Notification.dart';
import 'package:project_flutter/features/HomePage/screens/Notification.dart';

import 'package:project_flutter/features/payment/screens/checkout_screen.dart';
import 'package:project_flutter/features/payment/screens/order_status_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Màu chủ đạo Teal mà bạn đã chọn cho module Thanh toán
  static const Color oldieTeal = Color(0xFF1B6B60);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oldie App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: oldieTeal,
        scaffoldBackgroundColor: const Color(0xFFF4F9F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.grid_view, 'label': 'Tất cả'},
    {'icon': Icons.phone_iphone, 'label': 'Điện thoại'},
    {'icon': Icons.checkroom, 'label': 'Thời trang'},
    {'icon': Icons.chair_outlined, 'label': 'Nội thất'},
    {'icon': Icons.computer, 'label': 'Điện tử'},
    {'icon': Icons.menu_book, 'label': 'Sách'},
  ];
  final List<Map<String, dynamic>> allProducts = [
    {
      'title': 'iPhone 13 Pro 256GB - Mới 98%',
      'category': 'Điện thoại',
      'price': '18,500,000đ',
      'user': 'Minh Hưng',
      'location': 'Quận 1, TP.HCM',
      'image':
          'https://images.unsplash.com/photo-1632661674596-df8be070a5c5?auto=format&fit=crop&q=80&w=800',
      'desc': 'Máy còn rất mới, pin 91%, full phụ kiện, bao test.',
    },
    {
      'title': 'Áo Hoodie MCK - Phiên bản giới hạn',
      'category': 'Thời trang',
      'price': '850,000đ',
      'user': 'Ronboogz Fan',
      'location': 'Thanh Xuân, Hà Nội',
      'image':
          'https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&q=80&w=800',
      'desc': 'Áo mới mặc 2 lần, size L, chất vải dày dặn.',
    },
    {
      'title': 'Bàn làm việc gỗ Sồi tự nhiên',
      'category': 'Nội thất',
      'price': '2,200,000đ',
      'user': 'Nội Thất Cũ',
      'location': 'Hải Châu, Đà Nẵng',
      'image':
          'https://images.unsplash.com/photo-1518455027359-f3f816b1a22a?auto=format&fit=crop&q=80&w=800',
      'desc': 'Bàn còn chắc chắn, ít trầy xước, dài 1m2.',
    },
    {
      'title': 'Sách Deep Learning with Python',
      'category': 'Sách',
      'price': '350,000đ',
      'user': 'Tuấn IT',
      'location': 'Tân Phú, TP.HCM',
      'image':
          'https://images.unsplash.com/photo-1512428559087-560fa5ceab42?auto=format&fit=crop&q=80&w=800',
      'desc': 'Sách chuyên ngành IT, còn mới 95%.',
    },
    {
      'title': 'Tai nghe Sony WH-1000XM4',
      'category': 'Điện tử',
      'price': '4,500,000đ',
      'user': 'Âm Thanh Số',
      'location': 'Quận 3, TP.HCM',
      'image':
          'https://images.unsplash.com/photo-1618366712277-70778c392331?auto=format&fit=crop&q=80&w=800',
      'desc': 'Chống ồn cực tốt, full box, hết bảo hành.',
    },
    {
      'title': 'Artbook Black Myth: Wukong',
      'category': 'Sách',
      'price': '1,200,000đ',
      'user': 'Gamer Store',
      'location': 'Bình Thạnh, TP.HCM',
      'image':
          'https://images.unsplash.com/photo-1544652478-6653e09f18a2?auto=format&fit=crop&q=80&w=800',
      'desc': 'Sách ảnh game cực đẹp, bản sưu tầm hiếm.',
    },
    {
      'title': 'Samsung Galaxy S22 Ultra',
      'category': 'Điện thoại',
      'price': '12,000,000đ',
      'user': 'Thanh Thanh',
      'location': 'TP. Huế',
      'image':
          'https://images.unsplash.com/photo-1661347333292-386f9173c387?auto=format&fit=crop&q=80&w=800',
      'desc': 'Màn hình đẹp, camera zoom 100x.',
    },
    {
      'title': 'Ghế Gaming AKRacing',
      'category': 'Nội thất',
      'price': '3,800,000đ',
      'user': 'Phòng Net Thanh Lý',
      'location': 'Quận 10, TP.HCM',
      'image':
          'https://images.unsplash.com/photo-1598550476439-6847785fce66?auto=format&fit=crop&q=80&w=800',
      'desc': 'Ghế còn da đẹp, không lún, ngồi êm.',
    },
  ];
  final dummyNotifications = [
    NotificationModel(
      id: '1',
      title: 'Tin nhắn mới',
      timeAgo: '5 phút trước',
      content: 'Người mua Lê Trần: "Form áo này có rộng không shop?"',
      type: NotificationType.message,
    ),
    NotificationModel(
      id: '2',
      title: 'Đơn hàng đã giao thành công',
      timeAgo: '1 giờ trước',
      content: 'Đơn hàng #345 (Áo Sơ Mi Nam) đã được giao đến tay người mua.',
      type: NotificationType.orderSuccess,
    ),
    NotificationModel(
      id: '3',
      title: 'Đơn hàng #342 đã bị hủy',
      timeAgo: '3 giờ trước',
      content: 'Người mua đã hủy đơn hàng #342 (Quần Jean Nam).',
      type: NotificationType.orderCancelled,
    ),
    NotificationModel(
      id: '4',
      title: 'Đề nghị giá mới cho Giày Sneaker',
      timeAgo: 'Hôm qua',
      content:
          'Người dùng Minh Bong Air đề nghị giá 1.100.000đ cho đôi Giày Sneaker Trắng (giá gốc 1.200.000đ).',
      type: NotificationType.priceOffer,
    ),
    NotificationModel(
      id: '5',
      title: 'Đơn hàng mới chờ xác nhận',
      timeAgo: '2 ngày trước',
      content:
          'Khách hàng Minh Hưng đã mua đôi Giày Sneaker Trắng của bạn. Vui lòng xác nhận đơn hàng.',
      type: NotificationType.actionRequired,
    ),
  ];
  List<Map<String, dynamic>> displayedProducts = [];
  @override
  void initState() {
    super.initState();
    displayedProducts = allProducts;
  }

  void _filterProducts() {
    String query = _searchController.text.toLowerCase();
    String category = categories[_selectedCategoryIndex]['label'];

    setState(() {
      displayedProducts = allProducts.where((p) {
        bool matchesSearch = p['title'].toLowerCase().contains(query);
        bool matchesCategory =
            (category == 'Tất cả') || (p['category'] == category);
        return matchesSearch && matchesCategory;
      }).toList();
    });
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
      setState(() {
        _selectedIndex = index;
      });
    } else if (index == 3) {
      setState(() {
        _selectedIndex = index;
      });
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatListScreen()),
      );
      setState(() => _selectedIndex = 0);
    } else if (index == 3) {
      setState(() {
        _selectedIndex = index;
      });
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotificationScreen(notifications: dummyNotifications),
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
                onChanged: (value) => _filterProducts(),
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
                if (_isSearching) {
                  _searchController.clear();
                  _filterProducts();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _showProfileOptions(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CategorySelector(
              categories: categories,
              selectedIndex: _selectedCategoryIndex,
              onCategorySelected: (index) {
                setState(() {
                  _selectedCategoryIndex = index;
                });
                _filterProducts();
              },
            ),
            const SizedBox(height: 10),
            displayedProducts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(top: 50.0),
                    child: Text(
                      'Không tìm thấy sản phẩm nào!',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: displayedProducts.length,
                    itemBuilder: (context, index) {
                      return ProductCard(product: displayedProducts[index]);
                    },
                  ),
          ],
        ),
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
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class CategorySelector extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final int selectedIndex;
  final Function(int) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 95,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isActive = index == selectedIndex;

          return GestureDetector(
            onTap: () => onCategorySelected(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFD6EBE0)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      color: isActive ? const Color(0xFF4C9A82) : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isActive
                          ? const Color(0xFF4C9A82)
                          : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

final dummyProduct = ProductDetailModel(
  shopName: 'Shop Thời Trang ABC',
  shopHandle: '@minhhung9x',
  shopAvatarUrl: 'https://i.pravatar.cc/150?img=11', // Link ảnh test
  timeAgo: '5 phút trước',
  productImageUrl:
      'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?q=80&w=600&auto=format&fit=crop', // Link áo sơ mi test
  productName: 'Áo Sơ Mi Nam Cotton',
  price: '350,000đ',
  specifications: {
    'Kích thước': 'L',
    'Màu sắc': 'Hồng phấn',
    'Chất liệu': 'Cotton',
    'Tình trạng': 'Mới 99%',
  },
  description:
      'Áo sơ mi nam chất liệu cotton thoáng mát, form dáng regular, màu hồng phấn trẻ trung. Hàng chính hãng, chỉ mặc 1 lần, còn như mới. Phù hợp đi làm, đi chơi.',
);

final dummyProfile = UserProfileModel(
  name: 'Minh Hưng',
  email: 'minhhung.abc@gmail.com',
  location: 'Quận 1, TP.HCM',
  totalReviews: 215,
  averageRating: 4.9,
  avatarUrl: 'https://i.pravatar.cc/150?img=11',
);

final dummyPosts = [
  UserPostModel(
    authorName: 'Minh Hưng',
    timeAgo: '5 phút trước',
    authorAvatarUrl: 'https://i.pravatar.cc/150?img=11',
    productImageUrl:
        'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?q=80&w=600',
    productName: 'Áo Sơ Mi Nam Linen',
    price: '280,000đ',
  ),
  UserPostModel(
    authorName: 'Minh Hưng',
    timeAgo: '5 phút trước',
    authorAvatarUrl: 'https://i.pravatar.cc/150?img=11',
    productImageUrl:
        'https://images.unsplash.com/photo-1549298916-b41d501d3772?q=80&w=600', // Hình giày
    productName: 'Giày Sneaker Trắng',
    price: '1,200,000đ',
  ),
];

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product; // Thay vì index, nhận Data Model
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(
                      userProfile: dummyProfile,
                      userPosts: dummyPosts,
                    ),
                  ),
                ),
                child: const CircleAvatar(
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150'),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['user'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '@${product['user'].toString().replaceAll(" ", "").toLowerCase()}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'Vừa xong',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: dummyProduct),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    product['image'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  product['price'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product['desc'],
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                product['location'],
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Spacer(),
              const Icon(Icons.favorite_border, color: Colors.grey, size: 16),
              const SizedBox(width: 4),
              const Text(
                '12',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chat_bubble_outline,
                color: Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 4),
              const Text(
                '3',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                  ),
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Mua hàng',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C9A82),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatDetailScreen()),
                  ),
                  icon: const Icon(
                    Icons.chat_outlined,
                    size: 16,
                    color: Color(0xFF4C9A82),
                  ),
                  label: const Text(
                    'Liên hệ người bán',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4C9A82)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF4C9A82)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MakeOfferScreen()),
                  ),
                  icon: const Icon(
                    Icons.local_offer_outlined,
                    size: 16,
                    color: Colors.orange,
                  ),
                  label: const Text(
                    'Thương lượng',
                    style: TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?img=11',
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Minh Hưng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildDrawerItem(Icons.settings_outlined, 'Cài đặt chung'),
            const Divider(height: 1),
            _buildDrawerItem(Icons.bookmark_border, 'Bài viết đã lưu'),
            const Divider(height: 1),
            _buildDrawerItem(Icons.help_outline, 'Trợ giúp và hỗ trợ'),
            const Divider(height: 1),
            _buildDrawerItem(Icons.lock_outline, 'Quyền riêng tư'),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      onTap: () {},
    );
  }
}


class ChatDetailScreen extends StatelessWidget {
  const ChatDetailScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chat')),
    body: const Center(child: Text('Khung chat')),
  );
}

class MakeOfferScreen extends StatelessWidget {
  const MakeOfferScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thương lượng')),
    body: const Center(child: Text('Form thương lượng giá')),
  );
}

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tin nhắn')),
    body: const Center(child: Text('Danh sách chat')),
  );
}

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đơn hàng')),
    body: const Center(child: Text('Danh sách đơn hàng')),
  );
}
