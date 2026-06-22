enum UserRole { user, provider }

class ProfileModel {
  final String userId;
  final String? displayName;
  final String? phone;
  final UserRole? role;

  const ProfileModel({
    required this.userId,
    this.displayName,
    this.phone,
    this.role,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      phone: json['phone'] as String?,
      role: switch (json['role']) {
        'user' => UserRole.user,
        'provider' => UserRole.provider,
        _ => null,
      },
    );
  }
}
