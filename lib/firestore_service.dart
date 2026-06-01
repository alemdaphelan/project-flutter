import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_flutter/features/HomePage/Models/Product.dart';
import 'package:project_flutter/shared/models/user_profile.dart';
import 'package:project_flutter/features/Review/ReviewModel.dart';
import 'package:project_flutter/features/Notification/NotificationModel.dart';

// Tự tạo một class để lưu cấu hình, an toàn tuyệt đối
class CloudinaryConfig {
  static const String cloudName = 'db9hzryrx';
  static const Map<String, String> presets = {
    'avatar': 'selling_app_avatar',
    'product': 'selling_app_products',
  };
}

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
        return ProductModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList()..sort((a, b) => b.time.compareTo(a.time));

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
          .toList()
        ..sort((a, b) {
          String nameA = a['name'] ?? '';
          String nameB = b['name'] ?? '';
          return nameA.toLowerCase().compareTo(nameB.toLowerCase());
        });
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!, doc.id);
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

      List<ProductModel> userProducts =
          snapshot.docs.map((doc) {
              return ProductModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
            }).toList()
            //sắp xếp theo thời gian mới nhất
            ..sort((a, b) => b.time.compareTo(a.time));
      UserProfile? sellerProfile = await getUserProfile(userId);
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

  // Hàm đẩy 1 cái đánh giá lên Firebase
  Future<void> addReview(Map<String, dynamic> reviewData) async {
    try {
      String reviewerId = reviewData['reviewerId'];
      String sellerId = reviewData['sellerId'];
      String customDocId = "${reviewerId}_${sellerId}";
      await _firestore.collection('reviews').doc(customDocId).set(reviewData);
    } catch (e) {
      print('❌ Lỗi thêm đánh giá: $e');
      rethrow;
    }
  }

  Future<List<ReviewModel>> getReviewsForSeller(String sellerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('time', descending: true)
          .get();

      List<ReviewModel> reviews = [];
      for (var doc in snapshot.docs) {
        try {
          reviews.add(
            ReviewModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          );
        } catch (e) {
          print('❌ Lỗi data review ID [${doc.id}]: $e');
        }
      }

      await Future.wait(
        reviews.map((review) async {
          if (review.reviewerId.isNotEmpty) {
            review.reviewer = await getUserProfile(review.reviewerId);
          }
        }),
      );

      return reviews;
    } catch (e) {
      print('❌ Lỗi lấy danh sách đánh giá: $e');
      return [];
    }
  }

  Stream<QuerySnapshot> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markNotificationAsRead(String notiId) async {
    await _firestore.collection('notifications').doc(notiId).update({
      'isRead': true,
    });
  }

  Future<void> triggerNotification({
    required String receiverId,
    required String title,
    required String body,
    required NotificationType type,
    required String relatedId,
  }) async {
    try {
      final newNoti = {
        'userId': receiverId,
        'title': title,
        'body': body,
        'type': type.name,
        'relatedId': relatedId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('notifications').add(newNoti);

      print(
        "🚀 [Notification] Đã bắn tự động loại [${type.name}] tới User: $receiverId",
      );
    } catch (e) {
      print("❌ [Notification Error] Bắn thông báo thất bại: $e");
    }
  }
}
