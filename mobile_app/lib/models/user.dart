/// Users and roles — mirrors shared `users` / `roles` tables (Member 1 owns
/// provisioning; inspector accounts are created by the administration/backend).
enum UserRole { inspector, business }

UserRole? userRoleFromName(String? name) {
  switch (name?.toUpperCase()) {
    case 'INSPECTOR':
      return UserRole.inspector;
    case 'BUSINESS':
    case 'RETAILER':
      return UserRole.business;
    default:
      return null;
  }
}

String userRoleName(UserRole role) =>
    role == UserRole.inspector ? 'INSPECTOR' : 'BUSINESS';

class User {
  const User({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.phone,
    this.designation,
    this.badgeId,
    this.jurisdiction,
    this.businessId,
  });

  final String id;
  final String name;
  final UserRole role;
  final String? email;
  final String? phone;

  /// e.g. "Food Safety Inspector, Grade II" — display only.
  final String? designation;

  /// Official inspector badge number.
  final String? badgeId;

  /// e.g. "Pune Zone 3, Maharashtra".
  final String? jurisdiction;

  /// Set only for business users; links to `businesses.id`.
  final String? businessId;

  bool get isInspector => role == UserRole.inspector;
  bool get isBusiness => role == UserRole.business;

  User copyWith({
    String? id,
    String? name,
    UserRole? role,
    String? email,
    String? phone,
    String? designation,
    String? badgeId,
    String? jurisdiction,
    String? businessId,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      designation: designation ?? this.designation,
      badgeId: badgeId ?? this.badgeId,
      jurisdiction: jurisdiction ?? this.jurisdiction,
      businessId: businessId ?? this.businessId,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        role: userRoleFromName(json['role'] as String?) ?? UserRole.business,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        designation: json['designation'] as String?,
        badgeId: json['badgeId'] as String?,
        jurisdiction: json['jurisdiction'] as String?,
        businessId: json['businessId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': userRoleName(role),
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (designation != null) 'designation': designation,
        if (badgeId != null) 'badgeId': badgeId,
        if (jurisdiction != null) 'jurisdiction': jurisdiction,
        if (businessId != null) 'businessId': businessId,
      };
}
