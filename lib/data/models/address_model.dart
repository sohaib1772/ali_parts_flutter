class AddressModel {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String? phone2;
  final String city;
  final String? area;
  final String? street;
  final String? notes;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    this.phone2,
    required this.city,
    this.area,
    this.street,
    this.notes,
    this.isDefault = false,
  });

  String get fullAddressText {
    final parts = [city, area, street, notes].where((s) => s != null && s.trim().isNotEmpty).toList();
    return parts.join(' - ');
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      phone2: json['phone2'] as String?,
      city: json['city'] as String? ?? '',
      area: json['area'] as String?,
      street: json['street'] as String?,
      notes: json['notes'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'full_name': fullName,
    'phone': phone,
    'phone2': phone2,
    'city': city,
    'area': area,
    'street': street,
    'notes': notes,
    'is_default': isDefault,
  };
}
