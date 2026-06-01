import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';
import '../models/offer.dart';
import '../services/firebase_chat_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/offer_card.dart';
import '../widgets/chat_input.dart';
import '../services/chat_extension_service.dart';
import 'package:project_flutter/firestore_service.dart';
import 'package:project_flutter/features/Notification/NotificationModel.dart';
import 'package:project_flutter/features/payment/screens/checkout_screen.dart';
import 'package:project_flutter/features/HomePage/Models/Product.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final bool isSellerViewInit;
  final String titleName;
  final bool autoShowOffer;
  final double? initOfferPrice;
  final String? initOfferImageUrl;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    this.isSellerViewInit = false,
    this.titleName = "Trò chuyện",
    this.autoShowOffer = false,
    this.initOfferPrice,
    this.initOfferImageUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _pController = TextEditingController();
  final TextEditingController _msgController = TextEditingController();
  final FirebaseChatService _chatService = FirebaseChatService();
  final FirestoreService _firestoreService = FirestoreService();

  File? _offerImage;
  String myUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String? partnerId;
  bool amISeller = false;
  String? productId;

  @override
  void initState() {
    super.initState();
    _loadRoomInfo();

    if (widget.autoShowOffer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pController.text = widget.initOfferPrice?.toInt().toString() ?? '';
        _showOfferDialog(existingImageUrl: widget.initOfferImageUrl);
      });
    }
  }

  Future<void> _loadRoomInfo() async {
    final doc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        if (data['buyerId'] == myUserId) {
          partnerId = data['sellerId'];
          amISeller = false;
        } else {
          partnerId = data['buyerId'];
          amISeller = true;
        }
        productId = data['productName'];
      });
    }
  }

  void _showOfferDialog({String? existingImageUrl}) {
    _offerImage = null;
    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            amISeller
                ? "BẠN LÀ NGƯỜI BÁN\nĐề xuất giá bán"
                : "BẠN LÀ NGƯỜI MUA\nĐề xuất giá mua",
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final f = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
                  if (f != null) {
                    setDialogState(() => _offerImage = File(f.path));
                  }
                },
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _offerImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_offerImage!, fit: BoxFit.cover),
                        )
                      : (existingImageUrl != null &&
                              existingImageUrl.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: existingImageUrl.startsWith('http')
                                  ? Image.network(
                                      existingImageUrl,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(existingImageUrl.replaceFirst('file://', '')),
                                      fit: BoxFit.cover,
                                    ),
                            )
                          : const Icon(Icons.add_a_photo, color: Colors.grey),
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
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCE00),
              ),
              onPressed: () async {
                String? imgUrl = existingImageUrl;
                if (_offerImage != null) {
                  imgUrl = await _chatService.uploadToImgBB(_offerImage!);
                }

                await _chatService.sendMessage(
                  widget.chatRoomId,
                  Message(
                    senderId: myUserId,
                    receiverId: partnerId ?? 'unknown',
                    content: "Đề nghị giá",
                    type: 'offer',
                    timestamp: Timestamp.now(),
                    offer: Offer(
                      price: double.tryParse(_pController.text) ?? 0,
                      productImageUrl: imgUrl,
                    ),
                  ),
                );
                if (partnerId != null) {
                  await _firestoreService.triggerNotification(
                    receiverId: partnerId!,
                    title: 'Đề nghị giá mới! 🤝',
                    body: 'Đối tác vừa gửi một mức giá mới cho bạn.',
                    type: NotificationType.offer_received,
                    relatedId: widget.chatRoomId,
                  );
                }

                _pController.clear();
                if (context.mounted) Navigator.pop(c);
              },
              child: const Text("Gửi", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: partnerId == null
            ? Text(widget.titleName)
            : FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(partnerId)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Text("Đang tải...");
                  var userData = snapshot.data?.data() as Map<String, dynamic>?;
                  return Text(userData?['displayName'] ?? widget.titleName);
                },
              ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessagesStream(widget.chatRoomId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final msgs = snapshot.data ?? [];
                return ListView.builder(
                  reverse: true,
                  itemCount: msgs.length,
                  itemBuilder: (c, i) {
                    final m = msgs[i];
                    final bool isMe = m.senderId == myUserId;

                    if (m.type == 'offer') {
                      return OfferCard(
                        message: m,
                        isMe: isMe,
                        isSeller: amISeller,
                        onAccept: () async {
                          await _chatService.updateOfferStatus(
                            widget.chatRoomId,
                            m.id!,
                            'accepted',
                          );
                          if (partnerId != null) {
                            await _firestoreService.triggerNotification(
                              receiverId: partnerId!,
                              title: 'Thương lượng thành công! 🎉',
                              body: 'Đối tác đã CHẤP NHẬN mức giá bạn đề xuất.',
                              type: NotificationType.offer_accepted,
                              relatedId: widget.chatRoomId,
                            );
                          }
                        },
                        onReject: () async {
                          await _chatService.updateOfferStatus(
                            widget.chatRoomId,
                            m.id!,
                            'rejected',
                          );
                          if (partnerId != null) {
                            await _firestoreService.triggerNotification(
                              receiverId: partnerId!,
                              title: 'Thương lượng thất bại ❌',
                              body: 'Mức giá bạn đưa ra đã bị đối tác từ chối.',
                              type: NotificationType.system,
                              relatedId: widget.chatRoomId,
                            );
                          }
                        },
                        onEdit: () {
                          _pController.text = m.offer!.price.toInt().toString();
                          _showOfferDialog(
                            existingImageUrl: m.offer!.productImageUrl,
                          );
                        },
                        onPay: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (c) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          try {
                            QuerySnapshot productSnap = await FirebaseFirestore
                                .instance
                                .collection('listings')
                                .where('name', isEqualTo: productId)
                                .limit(1)
                                .get();

                            if (context.mounted) Navigator.pop(context);

                            if (productSnap.docs.isNotEmpty) {
                              var doc = productSnap.docs.first;
                              ProductModel product = ProductModel.fromFirestore(
                                doc.data() as Map<String, dynamic>,
                                doc.id,
                              );

                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CheckoutScreen(
                                      product: product,
                                      dealPrice: m.offer!.price,
                                    ),
                                  ),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Sản phẩm không còn tồn tại!',
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
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
            onSendText: () async {
              String textToSend = _msgController.text.trim();
              if (textToSend.isEmpty) return;

              await _chatService.sendMessage(
                widget.chatRoomId,
                Message(
                  senderId: myUserId,
                  receiverId: partnerId ?? 'unknown',
                  content: textToSend,
                  type: 'text',
                  timestamp: Timestamp.now(),
                ),
              );
              _msgController.clear();
              if (partnerId != null) {
                await _firestoreService.triggerNotification(
                  receiverId: partnerId!,
                  title: 'Tin nhắn mới 💬',
                  body: textToSend,
                  type: NotificationType.chat,
                  relatedId: widget.chatRoomId,
                );
              }

              if (ChatExtensionService.isAutoReplyEnabled &&
                  partnerId != null) {
                Future.delayed(const Duration(seconds: 1), () async {
                  await _chatService.sendMessage(
                    widget.chatRoomId,
                    Message(
                      senderId: partnerId!,
                      receiverId: myUserId,
                      content: ChatExtensionService.autoReplyText,
                      type: 'text',
                      timestamp: Timestamp.now(),
                    ),
                  );
                });
              }
            },
            onSendImage: () async {
              final pickedFile = await ImagePicker().pickImage(
                source: ImageSource.gallery,
              );
              if (pickedFile == null) return;

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Đang gửi ảnh, vui lòng đợi..."),
                  ),
                );
              }

              String? imgUrl = await _chatService.uploadToImgBB(
                File(pickedFile.path),
              );

              if (imgUrl != null) {
                await _chatService.sendMessage(
                  widget.chatRoomId,
                  Message(
                    senderId: myUserId,
                    receiverId: partnerId ?? 'unknown',
                    content: imgUrl,
                    type: 'image',
                    timestamp: Timestamp.now(),
                  ),
                );
                if (partnerId != null) {
                  await _firestoreService.triggerNotification(
                    receiverId: partnerId!,
                    title: 'Tin nhắn hình ảnh 📷',
                    body: 'Đối tác vừa gửi một hình ảnh cho bạn.',
                    type: NotificationType.chat,
                    relatedId: widget.chatRoomId,
                  );
                }

                if (ChatExtensionService.isAutoReplyEnabled &&
                    partnerId != null) {
                  Future.delayed(const Duration(seconds: 1), () async {
                    await _chatService.sendMessage(
                      widget.chatRoomId,
                      Message(
                        senderId: partnerId!,
                        receiverId: myUserId,
                        content: ChatExtensionService.autoReplyText,
                        type: 'text',
                        timestamp: Timestamp.now(),
                      ),
                    );
                  });
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Lỗi tải ảnh, vui lòng thử lại!"),
                    ),
                  );
                }
              }
            },
            onSendOffer: () => _showOfferDialog(),
          ),
        ],
      ),
    );
  }
}