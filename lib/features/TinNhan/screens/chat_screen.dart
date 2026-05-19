import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../models/offer.dart';
import '../services/firebase_chat_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/offer_card.dart';
import '../widgets/chat_input.dart';
import '../services/chat_extension_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  const ChatScreen({Key? key, required this.chatRoomId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _pController = TextEditingController();
  final TextEditingController _msgController = TextEditingController();
  final FirebaseChatService _chatService = FirebaseChatService();
  bool isSellerView = false;
  File? _offerImage;

  // Mở hộp thoại (Dialog) cho phép người dùng đính kèm ảnh và nhập giá đề xuất
  void _showOfferDialog() {
    _offerImage = null;
    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isSellerView ? "BẠN LÀ NGƯỜI BÁN\nĐề xuất giá bán" : "BẠN LÀ NGƯỜI MUA\nĐề xuất giá mua",
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final f = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (f != null) setDialogState(() => _offerImage = File(f.path));
                },
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _offerImage == null
                      ? const Icon(Icons.add_a_photo, color: Colors.grey)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_offerImage!, fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _pController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Nhập giá mong muốn",
                  suffixText: "VNĐ",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text("Hủy")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCE00)),
              onPressed: () async {
                String? imgUrl;
                if (_offerImage != null) {
                  imgUrl = await _chatService.uploadToImgBB(_offerImage!);
                }

                await _chatService.sendMessage(
                  widget.chatRoomId,
                  Message(
                    senderId: isSellerView ? 'seller' : 'buyer',
                    receiverId: isSellerView ? 'buyer' : 'seller',
                    content: "Đề nghị giá",
                    type: 'offer',
                    timestamp: Timestamp.now(),
                    offer: Offer(
                      price: double.tryParse(_pController.text) ?? 0,
                      productImageUrl: imgUrl,
                    ),
                  ),
                );
                _pController.clear();
                Navigator.pop(c);
              },
              child: const Text("Gửi", style: TextStyle(color: Colors.black)),
            )
          ],
        ),
      ),
    );
  }

  // Xây dựng giao diện toàn bộ màn hình Chat
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isSellerView ? "Đang test: NGƯỜI BÁN" : "Đang test: NGƯỜI MUA"),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => setState(() => isSellerView = !isSellerView),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessagesStream(widget.chatRoomId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final msgs = snapshot.data ?? [];
                return ListView.builder(
                  reverse: true,
                  itemCount: msgs.length,
                  itemBuilder: (c, i) {
                    final m = msgs[i];
                    final String myId = isSellerView ? 'seller' : 'buyer';
                    final bool isMe = m.senderId == myId;

                    if (m.type == 'offer') {
                      return OfferCard(
                        message: m,
                        isMe: isMe,
                        isSeller: isSellerView,
                        onAccept: () => _chatService.updateOfferStatus(widget.chatRoomId, m.id!, 'accepted'),
                        onReject: () => _chatService.updateOfferStatus(widget.chatRoomId, m.id!, 'rejected'),
                        onEdit: () {
                          _pController.text = m.offer!.price.toInt().toString();
                          _showOfferDialog();
                        },
                        onPay: () => print("Thanh toán"),
                      );
                    }
                    return ChatBubble(message: m, isMe: isMe);
                  },
                );
              },
            ),
          ),
          ChatInput(
            controller: _msgController, 
            
            // Xử lý gửi tin nhắn văn bản và tự động phản hồi (nếu đối phương đang bật Bot)
            onSendText: () async {
              if (_msgController.text.trim().isEmpty) return;

              String myRole = isSellerView ? 'seller' : 'buyer';
              String partnerRole = isSellerView ? 'buyer' : 'seller';

              await _chatService.sendMessage(
                widget.chatRoomId,
                Message(
                  senderId: myRole,
                  receiverId: partnerRole,
                  content: _msgController.text.trim(), 
                  type: 'text', 
                  timestamp: Timestamp.now(),
                ),
              );
              _msgController.clear();

              if (ChatExtensionService.isAutoReplyEnabled) {
                Future.delayed(const Duration(seconds: 1), () async {
                  await _chatService.sendMessage(
                    widget.chatRoomId,
                    Message(
                      senderId: partnerRole,
                      receiverId: myRole,
                      content: ChatExtensionService.autoReplyText, 
                      type: 'text', 
                      timestamp: Timestamp.now(),
                    ),
                  );
                });
              }
            },
            
            // Xử lý chọn ảnh, upload lên ImgBB, gửi đi và tự động phản hồi (nếu đối phương bật Bot)
            onSendImage: () async {
              final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (pickedFile == null) return; 

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đang gửi ảnh, vui lòng đợi..."))
              );

              String? imgUrl = await _chatService.uploadToImgBB(File(pickedFile.path));

              if (imgUrl != null) {
                String myRole = isSellerView ? 'seller' : 'buyer';
                String partnerRole = isSellerView ? 'buyer' : 'seller';

                await _chatService.sendMessage(
                  widget.chatRoomId,
                  Message(
                    senderId: myRole,
                    receiverId: partnerRole,
                    content: imgUrl, 
                    type: 'image', 
                    timestamp: Timestamp.now(),
                  ),
                );

                if (ChatExtensionService.isAutoReplyEnabled) {
                  Future.delayed(const Duration(seconds: 1), () async {
                    await _chatService.sendMessage(
                      widget.chatRoomId,
                      Message(
                        senderId: partnerRole,
                        receiverId: myRole,
                        content: ChatExtensionService.autoReplyText,
                        type: 'text',
                        timestamp: Timestamp.now(),
                      ),
                    );
                  });
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Lỗi tải ảnh, vui lòng thử lại!"))
                );
              }
            },
            
            onSendOffer: _showOfferDialog,
          ),
        ],
      ),
    );
  }
}