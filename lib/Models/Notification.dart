enum NotificationType {
  message,
  orderSuccess,
  orderCancelled,
  priceOffer,
  actionRequired,
}

class NotificationModel {
  final String id;
  final String title;
  final String timeAgo;
  final String content;
  final NotificationType type;

  NotificationModel({
    required this.id,
    required this.title,
    required this.timeAgo,
    required this.content,
    required this.type,
  });
}
