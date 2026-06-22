class ProviderModel {
  final String id;
  final String name;
  final String phone;
  final String serviceType;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? description;
  final String? avatarUrl;
  final bool isActive;
  final String? userId;
  final DateTime? createdAt;
  final double? distance;
  final int savesCount;
  final DateTime? lastSeenAt;

  const ProviderModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.serviceType,
    this.latitude,
    this.longitude,
    this.address,
    this.description,
    this.avatarUrl,
    this.isActive = true,
    this.userId,
    this.createdAt,
    this.distance,
    this.savesCount = 0,
    this.lastSeenAt,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      serviceType: json['service_type'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      userId: json['user_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'service_type': serviceType,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'description': description,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'user_id': userId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  ProviderModel copyWithDistance(double? distance) {
    return ProviderModel(
      id: id, name: name, phone: phone, serviceType: serviceType,
      latitude: latitude, longitude: longitude, address: address,
      description: description, avatarUrl: avatarUrl, isActive: isActive,
      userId: userId, createdAt: createdAt,
      distance: distance, savesCount: savesCount, lastSeenAt: lastSeenAt,
    );
  }

  ProviderModel copyWithSaves(int savesCount) {
    return ProviderModel(
      id: id, name: name, phone: phone, serviceType: serviceType,
      latitude: latitude, longitude: longitude, address: address,
      description: description, avatarUrl: avatarUrl, isActive: isActive,
      userId: userId, createdAt: createdAt,
      distance: distance, savesCount: savesCount, lastSeenAt: lastSeenAt,
    );
  }

  ProviderModel copyWithLastSeen(DateTime? lastSeenAt) {
    return ProviderModel(
      id: id, name: name, phone: phone, serviceType: serviceType,
      latitude: latitude, longitude: longitude, address: address,
      description: description, avatarUrl: avatarUrl, isActive: isActive,
      userId: userId, createdAt: createdAt,
      distance: distance, savesCount: savesCount, lastSeenAt: lastSeenAt,
    );
  }
}
