class AddressModel {
  final String id;
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String label; // 'Home', 'Work', 'Other'
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;
  final bool isDefault;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AddressModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.label,
    required this.addressLine1,
    this.addressLine2 = '',
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    this.isDefault = false,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.updatedAt,
  });

  // ─────────────────────────────────────────────
  //  Compatibility Getters
  // ─────────────────────────────────────────────

  /// Alias for label  (e.g. 'Home', 'Work', 'Other')
  String get addressType => label;

  /// Street address – alias for addressLine1
  String get streetAddress => addressLine1;

  /// One-line compact address  (no pincode)
  String get shortAddress => addressLine1;

  // ─────────────────────────────────────────────
  //  Formatted Address Getters
  // ─────────────────────────────────────────────

  /// City + State only  →  "Mumbai, Maharashtra"
  String get cityState => '$city, $state';

  /// addressLine1 + addressLine2 (if present), city, state
  /// e.g. "123 Main St, Apt 4B, Mumbai, Maharashtra"
  String get formattedAddress {
    final parts = <String>[
      addressLine1,
      if (addressLine2.trim().isNotEmpty) addressLine2.trim(),
      city,
      state,
    ];
    return parts.join(', ');
  }

  /// Full address with pincode
  /// e.g. "123 Main St, Apt 4B, Mumbai, Maharashtra - 400001"
  String get fullAddress {
    final parts = <String>[
      addressLine1,
      if (addressLine2.trim().isNotEmpty) addressLine2.trim(),
      city,
      '$state - $pincode',
    ];
    return parts.join(', ');
  }

  /// Full address including landmark (if present)
  String get fullAddressWithLandmark {
    final parts = <String>[
      addressLine1,
      if (addressLine2.trim().isNotEmpty) addressLine2.trim(),
      if (landmark != null && landmark!.trim().isNotEmpty)
        'Near ${landmark!.trim()}',
      city,
      '$state - $pincode',
    ];
    return parts.join(', ');
  }

  /// Display string used in checkout / order summaries
  /// Includes full name, address, and phone number
  String get displayAddress {
    return '$fullName\n$fullAddress\nPhone: $phoneNumber';
  }

  // ─────────────────────────────────────────────
  //  Validation Helpers
  // ─────────────────────────────────────────────

  bool get isValid =>
      id.isNotEmpty &&
          userId.isNotEmpty &&
          fullName.trim().isNotEmpty &&
          phoneNumber.trim().isNotEmpty &&
          addressLine1.trim().isNotEmpty &&
          city.trim().isNotEmpty &&
          state.trim().isNotEmpty &&
          pincode.trim().isNotEmpty;

  bool get hasCoordinates => latitude != null && longitude != null;

  // ─────────────────────────────────────────────
  //  JSON Serialization
  // ─────────────────────────────────────────────

  /// Supports both snake_case (API) and camelCase (local) keys
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      label: json['label'] ?? 'Home',
      addressLine1: json['address_line1'] ?? json['addressLine1'] ?? '',
      addressLine2: json['address_line2'] ?? json['addressLine2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      landmark: json['landmark'],
      isDefault: json['is_default'] ?? json['isDefault'] ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? _parseDateTime(json['updated_at'] ?? json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'label': label,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'is_default': isDefault,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─────────────────────────────────────────────
  //  CopyWith
  // ─────────────────────────────────────────────

  AddressModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phoneNumber,
    String? label,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pincode,
    String? landmark,
    bool? isDefault,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      label: label ?? this.label,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      landmark: landmark ?? this.landmark,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─────────────────────────────────────────────
  //  Private Helpers
  // ─────────────────────────────────────────────

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  // ─────────────────────────────────────────────
  //  Overrides
  // ─────────────────────────────────────────────

  @override
  String toString() =>
      'AddressModel(id: $id, fullName: $fullName, city: $city, isDefault: $isDefault)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AddressModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}