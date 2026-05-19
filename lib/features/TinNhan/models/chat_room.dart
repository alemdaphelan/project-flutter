import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final String otherUserName;
  final String lastMessage;
  final Timestamp timestamp;

  ChatRoom({
    required this.id,
    required this.otherUserName,
    required this.lastMessage,
    required this.timestamp,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return ChatRoom(
      id: doc.id,
      otherUserName: data['otherUserName'] ?? 'Người dùng',
      lastMessage: data['lastMessage'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}