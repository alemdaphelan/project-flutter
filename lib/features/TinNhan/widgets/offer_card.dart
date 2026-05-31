import 'package:flutter/material.dart';
import '../models/message.dart';

class OfferCard extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isSeller;
  final VoidCallback onAccept, onReject, onPay, onEdit;

  const OfferCard({
    Key? key, required this.message, required this.isMe,
    required this.isSeller, required this.onAccept,
    required this.onReject, required this.onPay, required this.onEdit
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final offer = message.offer!;
    
    bool senderIsSeller = isMe ? isSeller : !isSeller;
    String title = senderIsSeller ? "NGƯỜI BÁN ĐỀ XUẤT GIÁ" : "NGƯỜI MUA ĐỀ XUẤT GIÁ";

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 280, margin: const EdgeInsets.all(10),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              if (offer.productImageUrl != null && offer.productImageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.network(offer.productImageUrl!, height: 120, width: double.infinity, fit: BoxFit.cover),
                ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text("${offer.price.toInt()} VNĐ", style: const TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.bold)),
                    const Divider(),
                    if (offer.status == 'pending')
                      (!isMe) 
                        ? Row(
                            children: [
                              Expanded(child: OutlinedButton(onPressed: onReject, child: const Text("Từ chối"))),
                              const SizedBox(width: 8),
                              Expanded(child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCE00)),
                                onPressed: onAccept, 
                                child: const Text("Đồng ý", style: TextStyle(color: Colors.black))
                              )),
                            ],
                          )
                        : Column(
                            children: [
                              const Text("Đang chờ đối phương phản hồi...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.edit, size: 16),
                                onPressed: onEdit, 
                                label: const Text("Sửa đề nghị"),
                                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 36)),
                              ),
                            ],
                          )
                    else 
                      Text(
                        offer.status == 'accepted' ? "ĐÃ CHẤP NHẬN" : "ĐÃ TỪ CHỐI",
                        style: TextStyle(fontWeight: FontWeight.bold, color: offer.status == 'accepted' ? Colors.green : Colors.red),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}