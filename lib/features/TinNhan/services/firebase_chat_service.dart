import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';

class FirebaseChatService {
  final String _imgBBKey = "3bed019711c18249979407b1683a75f6"; 
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getChatRoomsStream() {
    return _firestore.collection('chats').orderBy('timestamp', descending: true).snapshots();
  }

  Future<String> createNewChat() async {
    String myId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    DocumentReference doc = await _firestore.collection('chats').add({
      'buyerId': myId,
      'sellerId': 'unknown',
      'otherUserName': 'Khách hàng ${DateTime.now().second}',
      'lastMessage': 'Bắt đầu trò chuyện',
      'timestamp': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<String> getOrCreateChatRoom({
    required String buyerId,
    required String sellerId,
    required String productName,
    required String sellerName,
    bool isOffer = false,
    double? productPrice,
    String? productImageUrl,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('chats')
          .where('buyerId', isEqualTo: buyerId)
          .get();

      var existingRooms = snapshot.docs.where((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return data['sellerId'] == sellerId;
      }).toList();

      String chatRoomId;

      if (existingRooms.isNotEmpty) {
        chatRoomId = existingRooms.first.id;
      } else {
        DocumentReference doc = await _firestore.collection('chats').add({
          'buyerId': buyerId,
          'sellerId': sellerId,
          'productName': productName,
          'otherUserName': sellerName, 
          'lastMessage': isOffer ? '[Đề xuất giá]: $productName' : '[Yêu cầu tư vấn]: $productName',
          'timestamp': FieldValue.serverTimestamp(),
        });
        chatRoomId = doc.id;
      }

      if (isOffer && productPrice != null) {
        await _firestore.collection('chats').doc(chatRoomId).collection('messages').add({
             'senderId': buyerId,
             'receiverId': sellerId,
             'content': 'Tôi muốn đề xuất giá cho: $productName',
             'type': 'offer',
             'timestamp': FieldValue.serverTimestamp(),
             'offerDetails': {
               'price': productPrice,
               'productImageUrl': productImageUrl,
               'status': 'pending'
             }
        });
      } else {
        await _firestore.collection('chats').doc(chatRoomId).collection('messages').add({
             'senderId': buyerId,
             'receiverId': sellerId,
             'content': 'Tôi muốn hỏi mua: $productName',
             'type': 'text',
             'timestamp': FieldValue.serverTimestamp(),
        });
      }
      
      await _firestore.collection('chats').doc(chatRoomId).update({
        'lastMessage': isOffer ? 'Đề xuất giá: $productName' : 'Hỏi mua: $productName',
        'productName': productName, 
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      return chatRoomId;
    } catch (e) {
      print(e);
      return "";
    }
  }

  Future<String?> uploadToImgBB(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload?key=$_imgBBKey'));
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final data = json.decode(await response.stream.bytesToString());
        return data['data']['url'];
      }
    } catch (e) { 
      print(e);
    }
    return null;
  }

  Future<void> sendMessage(String chatRoomId, Message message) async {
    await _firestore.collection('chats').doc(chatRoomId).collection('messages').add(message.toMap());
    await _firestore.collection('chats').doc(chatRoomId).update({
      'lastMessage': message.type == 'text' ? message.content : '[Hình ảnh]',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Message>> getMessagesStream(String chatRoomId) {
    return _firestore.collection('chats').doc(chatRoomId).collection('messages')
        .orderBy('timestamp', descending: true).snapshots()
        .map((s) => s.docs.map((d) => Message.fromMap(d.data(), d.id)).toList());
  }

  Future<void> updateOfferStatus(String chatRoomId, String msgId, String status) async {
    await _firestore.collection('chats').doc(chatRoomId).collection('messages').doc(msgId).update({'offerDetails.status': status});
  }

  Future<void> deleteChat(String chatRoomId) async {
    try {
      var messages = await _firestore.collection('chats').doc(chatRoomId).collection('messages').get();
      
      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      await _firestore.collection('chats').doc(chatRoomId).delete();
    } catch (e) {
      print(e);
    }
  }
}