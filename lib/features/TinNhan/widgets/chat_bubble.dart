import 'package:flutter/material.dart';
import '../models/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const ChatBubble({Key? key, required this.message, required this.isMe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: message.type == 'text'
            ? Text(message.content, style: TextStyle(color: isMe ? Colors.white : Colors.black))
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(message.content, width: 220, fit: BoxFit.cover),
              ),
      ),
    );
  }
}