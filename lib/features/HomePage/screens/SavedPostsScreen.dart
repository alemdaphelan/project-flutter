import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_flutter/features/HomePage/Models/Product.dart';
import 'package:project_flutter/features/HomePage/widgets/ProductCard.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF1B6B60);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F7),
      appBar: AppBar(
        title: const Text(
          'Bài viết đã lưu',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryTeal),
            );
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return _buildEmptyState();
          }

          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> savedIds = userData['savedProducts'] ?? [];

          if (savedIds.isEmpty) {
            return _buildEmptyState();
          }

          return FutureBuilder<List<ProductModel>>(
            future: _fetchSavedProducts(List<String>.from(savedIds)),
            builder: (context, productSnapshot) {
              if (productSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: primaryTeal),
                );
              }

              if (!productSnapshot.hasData || productSnapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              List<ProductModel> savedProducts = productSnapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                itemCount: savedProducts.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: savedProducts[index]);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<ProductModel>> _fetchSavedProducts(
    List<String> productIds,
  ) async {
    List<ProductModel> products = [];
    for (var i = 0; i < productIds.length; i += 10) {
      var chunk = productIds.sublist(
        i,
        i + 10 > productIds.length ? productIds.length : i + 10,
      );

      var snapshot = await FirebaseFirestore.instance
          .collection('listings')
          .where(FieldPath.documentId, whereIn: chunk)
          .orderBy('time', descending: true)
          .get();

      for (var doc in snapshot.docs) {
        try {
          products.add(ProductModel.fromFirestore(doc.data(), doc.id));
        } catch (e) {
          debugPrint('Lỗi giải mã sản phẩm đã lưu: $e');
        }
      }
    }
    products.sort((a, b) => b.time.compareTo(a.time));
    return products;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có bài viết nào được lưu',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
