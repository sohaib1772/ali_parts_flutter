class UserModel {
  final String id;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final bool isBlocked;
  final int pointsBalance;
  final bool isAdmin;
  final String? createdAt;

  UserModel({
    required this.id,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.isBlocked = false,
    this.pointsBalance = 0,
    this.isAdmin = false,
    this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? avatarUrl,
    bool? isBlocked,
    int? pointsBalance,
    bool? isAdmin,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isBlocked: isBlocked ?? this.isBlocked,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json, {bool isAdmin = false}) {
    return UserModel(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isBlocked: json['is_blocked'] as bool? ?? false,
      pointsBalance: (json['points_balance'] as num?)?.toInt() ?? 0,
      isAdmin: isAdmin,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'phone': phone,
    'avatar_url': avatarUrl,
    'is_blocked': isBlocked,
    'points_balance': pointsBalance,
    'created_at': createdAt,
  };
}
