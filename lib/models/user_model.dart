class UserModel {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String? location;
  final double? latitude;
  final double? longitude;
  final bool isVerified;
  final bool isPremium;
  final int patitas;
  final String? referralCode;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.location,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.isPremium = false,
    this.patitas = 0,
    this.referralCode,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      photoUrl: json['photo_url'] as String?,
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isVerified: json['is_verified'] as bool? ?? false,
      isPremium: json['is_premium'] as bool? ?? false,
      patitas: json['patitas'] as int? ?? 0,
      referralCode: json['referral_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'photo_url': photoUrl,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'is_verified': isVerified,
        'is_premium': isPremium,
        'patitas': patitas,
        'referral_code': referralCode,
        'created_at': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? location,
    double? latitude,
    double? longitude,
    bool? isVerified,
    bool? isPremium,
    int? patitas,
    String? referralCode,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      isPremium: isPremium ?? this.isPremium,
      patitas: patitas ?? this.patitas,
      referralCode: referralCode ?? this.referralCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
