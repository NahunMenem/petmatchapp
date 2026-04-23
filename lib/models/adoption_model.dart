enum AdoptionStatus { available, reserved, adopted }

class AdoptionModel {
  final String id;
  final String publisherId;
  final String publisherName;
  final String? publisherPhoto;
  final String name;
  final String type; // 'dog' | 'cat'
  final String age;
  final String? breed;
  final String size;
  final String healthStatus;
  final String description;
  final List<String> photos;
  final String location;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final String phone;
  final AdoptionStatus status;
  final DateTime publishedAt;

  const AdoptionModel({
    required this.id,
    required this.publisherId,
    required this.publisherName,
    this.publisherPhoto,
    required this.name,
    required this.type,
    required this.age,
    this.breed,
    required this.size,
    required this.healthStatus,
    required this.description,
    required this.photos,
    required this.location,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.phone = '',
    this.status = AdoptionStatus.available,
    required this.publishedAt,
  });

  String get mainPhoto => photos.isNotEmpty ? photos[0] : '';

  String? get distanceLabel {
    final distance = distanceKm;
    if (distance == null) return null;
    if (distance < 1) {
      final meters = (distance * 1000).round().clamp(50, 999);
      return 'A $meters m';
    }
    return 'A ${distance.toStringAsFixed(distance < 10 ? 1 : 0)} km';
  }

  String get statusLabel {
    switch (status) {
      case AdoptionStatus.available:
        return 'En adopción';
      case AdoptionStatus.reserved:
        return 'Reservado';
      case AdoptionStatus.adopted:
        return 'Adoptado';
    }
  }

  String get typeLabel => type == 'dog' ? 'Perro' : 'Gato';

  factory AdoptionModel.fromJson(Map<String, dynamic> json) {
    AdoptionStatus parseStatus(String s) {
      switch (s) {
        case 'reserved':
          return AdoptionStatus.reserved;
        case 'adopted':
          return AdoptionStatus.adopted;
        default:
          return AdoptionStatus.available;
      }
    }

    return AdoptionModel(
      id: json['id'] as String,
      publisherId: json['publisher_id'] as String,
      publisherName: json['publisher_name'] as String,
      publisherPhoto: json['publisher_photo'] as String?,
      name: json['name'] as String,
      type: json['type'] as String,
      age: json['age'] as String,
      breed: json['breed'] as String?,
      size: json['size'] as String,
      healthStatus: json['health_status'] as String,
      description: json['description'] as String,
      photos: List<String>.from(json['photos'] as List? ?? []),
      location: json['location'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      phone: json['phone'] as String? ?? '',
      status: parseStatus(json['status'] as String? ?? 'available'),
      publishedAt: DateTime.parse(json['published_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'publisher_id': publisherId,
        'publisher_name': publisherName,
        'publisher_photo': publisherPhoto,
        'name': name,
        'type': type,
        'age': age,
        'breed': breed,
        'size': size,
        'health_status': healthStatus,
        'description': description,
        'photos': photos,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'distance_km': distanceKm,
        'phone': phone,
        'status': status.name,
        'published_at': publishedAt.toIso8601String(),
      };
}
