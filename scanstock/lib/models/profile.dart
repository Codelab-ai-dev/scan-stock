class Profile {
  final String id;
  final String email;
  final String? fullName;
  final String role;
  final DateTime createdAt;
  final String? businessId;
  final bool isSuperAdmin;

  Profile({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    required this.createdAt,
    this.businessId,
    this.isSuperAdmin = false,
  });

  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';
  bool get hasNegocio => businessId != null;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      role: json['role'] as String? ?? 'user',
      createdAt: DateTime.parse(json['created_at'] as String),
      businessId: json['business_id'] as String?,
      isSuperAdmin: json['is_super_admin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'business_id': businessId,
      'is_super_admin': isSuperAdmin,
    };
  }

  Profile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    DateTime? createdAt,
    String? businessId,
    bool? isSuperAdmin,
  }) {
    return Profile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      businessId: businessId ?? this.businessId,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
    );
  }
}
