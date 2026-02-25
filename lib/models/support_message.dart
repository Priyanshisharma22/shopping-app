class SupportMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final Map<String, dynamic>? metadata;

  SupportMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.metadata,
  });
}

enum MessageType {
  text,
  action, // Quick action buttons
  order, // Order card
  product, // Product card
  image,
  error,
  typing,
}