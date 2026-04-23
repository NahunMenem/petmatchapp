class LostPetModel {
  final String id;
  final String reporterId;
  final String reporterName;
  final String? reporterPhoto;
  final String? petId;
  final String name;
  final String type;
  final String description;
  final String location;
  final String phone;
  final List<String> photos;
  final double? distanceKm;
  final double? latitude;
  final double? longitude;
  final int? rewardAmount;
  final int? alertRadiusKm;
  final String status;
  final DateTime reportedAt;

  const LostPetModel({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    this.reporterPhoto,
    this.petId,
    required this.name,
    required this.type,
    required this.description,
    required this.location,
    required this.phone,
    required this.photos,
    this.distanceKm,
    this.latitude,
    this.longitude,
    this.rewardAmount,
    this.alertRadiusKm,
    required this.status,
    required this.reportedAt,
  });

  String get typeLabel => type == 'cat' ? 'Gato' : 'Perro';
  String get breed => typeLabel;
  String? get photoUrl => photos.isNotEmpty ? photos.first : null;
  bool get isUrgent => alertRadiusKm != null || rewardAmount != null;

  String get distanceLabel {
    final distance = distanceKm;
    if (distance == null) return location;
    return '${distance.toStringAsFixed(1)} km';
  }

  String get timeAgo {
    final diff = DateTime.now().difference(reportedAt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} hs';
    return 'Hace ${diff.inDays} dias';
  }

  factory LostPetModel.fromJson(Map<String, dynamic> json) {
    return LostPetModel(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      reporterName: json['reporter_name'] as String? ?? '',
      reporterPhoto: json['reporter_photo'] as String?,
      petId: json['pet_id'] as String?,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'dog',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      photos: List<String>.from(json['photos'] as List? ?? []),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rewardAmount: (json['reward_amount'] as num?)?.toInt(),
      alertRadiusKm: (json['alert_radius_km'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'active',
      reportedAt: DateTime.tryParse(json['reported_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
