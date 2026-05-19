import 'package:cloud_firestore/cloud_firestore.dart';
import 'offer.dart';

class Message {
  String? id;
  final String senderId, receiverId, content, type;
  final Timestamp timestamp;
  final Offer? offer;

  Message({this.id, required this.senderId, required this.receiverId, 
          required this.content, this.type = 'text', required this.timestamp, this.offer});

  Map<String, dynamic> toMap() => {
    'senderId': senderId, 'receiverId': receiverId, 'content': content,
    'type': type, 'timestamp': timestamp,
    if (offer != null) 'offerDetails': offer!.toMap(),
  };

  factory Message.fromMap(Map<String, dynamic> map, String docId) => Message(
    id: docId,
    senderId: map['senderId'] ?? '',
    receiverId: map['receiverId'] ?? '',
    content: map['content'] ?? '',
    type: map['type'] ?? 'text',
    timestamp: map['timestamp'] ?? Timestamp.now(),
    offer: map['offerDetails'] != null ? Offer.fromMap(map['offerDetails']) : null,
  );
}