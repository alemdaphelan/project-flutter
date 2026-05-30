import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_flutter/features/HomePage/Models/Product.dart';
import 'package:project_flutter/features/HomePage/Models/UserProfile.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      await _firestore.collection('listings').add(productData);
    } catch (e) {
      print('Error adding product: $e');
    }
  }

  Future<List<ProductModel>> getProducts() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('listings').get();
      List<ProductModel> products = snapshot.docs.map((doc) {
        return ProductModel.FromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      await Future.wait(
        products.map((product) async {
          if (product.sellerId.isNotEmpty) {
            product.seller = await getUserProfile(product.sellerId);
          }
        }),
      );
      return products;
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('categories').get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<UserProfileModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfileModel.fromFirestore(doc.data()!, doc.id);
      }
    } catch (e) {
      print('Lỗi khi lấy thông tin seller: $e');
    }
    return null;
  }

  Future<List<ProductModel>> getProductsByUser(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('listings')
          .where('sellerId', isEqualTo: userId)
          .get();

      List<ProductModel> userProducts = snapshot.docs.map((doc) {
        return ProductModel.FromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
      UserProfileModel? sellerProfile = await getUserProfile(userId);
      if (sellerProfile != null) {
        for (var product in userProducts) {
          product.seller = sellerProfile;
        }
      }

      return userProducts;
    } catch (e) {
      print('Error fetching products by user: $e');
      return [];
    }
  }
}
