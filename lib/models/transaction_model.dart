class TransactionModel {
  final String id;
  final String type; // 'credit' or 'debit'
  final double amount;
  final String description;
  final DateTime timestamp;
  final String? reference; // UPI ID, Order ID, etc.
  final String status; // 'completed', 'pending', 'failed'

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
    this.reference,
    this.status = 'completed',
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'reference': reference,
      'status': status,
    };
  }

  // Create from JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'debit',
      amount: _parseAmount(json['amount']),
      description: json['description']?.toString() ?? 'No description',
      timestamp: _parseDateTime(json['timestamp']),
      reference: json['reference']?.toString(),
      status: json['status']?.toString() ?? 'completed',
    );
  }

  // Helper method to parse amount
  static double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is double) return amount;
    if (amount is int) return amount.toDouble();
    if (amount is String) return double.tryParse(amount) ?? 0.0;
    return 0.0;
  }

  // Helper method to parse datetime
  static DateTime _parseDateTime(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    if (timestamp is DateTime) return timestamp;

    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    }

    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    return DateTime.now();
  }

  // Copy with method for updates
  TransactionModel copyWith({
    String? id,
    String? type,
    double? amount,
    String? description,
    DateTime? timestamp,
    String? reference,
    String? status,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      reference: reference ?? this.reference,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, type: $type, amount: $amount, description: $description, timestamp: $timestamp, reference: $reference, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TransactionModel &&
        other.id == id &&
        other.type == type &&
        other.amount == amount &&
        other.description == description &&
        other.timestamp == timestamp &&
        other.reference == reference &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    type.hashCode ^
    amount.hashCode ^
    description.hashCode ^
    timestamp.hashCode ^
    reference.hashCode ^
    status.hashCode;
  }

  // Convenience getters for backward compatibility
  String? get receiverUpiId => reference;
}