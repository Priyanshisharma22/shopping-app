import 'package:upi_mock_app/models/support_message.dart';

class SupportTicket {
  final String id;
  final String userId;
  final String subject;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final List<SupportMessage> messages;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.description,
    required this.status,
    this.priority = TicketPriority.medium,
    required this.createdAt,
    this.resolvedAt,
    this.messages = const [],
  });
}

enum TicketStatus {
  open,
  inProgress,
  resolved,
  escalated,
}

enum TicketPriority {
  low,
  medium,
  high,
  urgent,
}