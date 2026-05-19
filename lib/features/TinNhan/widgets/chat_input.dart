import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendText, onSendImage, onSendOffer;

  const ChatInput({Key? key, required this.controller, required this.onSendText, 
                  required this.onSendImage, required this.onSendOffer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8), color: Colors.white,
      child: Row(children: [
        IconButton(icon: const Icon(Icons.add_box, color: Colors.blue), onPressed: onSendOffer),
        IconButton(icon: const Icon(Icons.image, color: Colors.blue), onPressed: onSendImage),
        Expanded(child: TextField(controller: controller, decoration: const InputDecoration(hintText: "Nhập tin nhắn...", border: InputBorder.none))),
        IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: onSendText),
      ]),
    );
  }
}