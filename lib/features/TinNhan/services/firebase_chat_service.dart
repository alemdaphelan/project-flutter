import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class FirebaseChatService {
  final String _imgBBKey = "3bed019711c18249979407b1683a75f6"; 
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy danh sách các phòng chat thật từ Firestore
  Stream<QuerySnapshot> getChatRoomsStream() {
    return _firestore.collection('chats').orderBy('timestamp', descending: true).snapshots();
  }

  // Tạo phòng chat mới
  Future<String> createNewChat() async {
    DocumentReference doc = await _firestore.collection('chats').add({
      'otherUserName': 'Khách hàng ${DateTime.now().second}',
      'lastMessage': 'Bắt đầu trò chuyện',
      'timestamp': FieldValue.serverTimestamp(),
    });
    return doc.id;
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
    } catch (e) { print("Lỗi ImgBB: $e"); }
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

  // Hàm xóa vĩnh viễn phòng chat và toàn bộ lịch sử tin nhắn
  Future<void> deleteChat(String chatRoomId) async {
    try {
      // Lấy toàn bộ tin nhắn bên trong phòng chat này
      var messages = await _firestore.collection('chats').doc(chatRoomId).collection('messages').get();
      
      // Xóa từng tin nhắn một
      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      // Xóa phòng chat
      await _firestore.collection('chats').doc(chatRoomId).delete();
    } catch (e) {
      print("Lỗi khi xóa chat: $e");
    }
  }
}