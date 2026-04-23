enum PetType { dog, cat }

enum PetSex { male, female }

enum PetSize { small, medium, large }

class PetModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerPhotoUrl;
  final bool ownerVerified;
  final String name;
  final PetType type;
  final String breed;
  final String age; // "2 años", "8 meses"
  final PetSex sex;
  final PetSize size;
  final bool vaccinesUpToDate;
  final bool sterilized;
  final List<String> photos;
  final String? description;
  final double? distanceKm;
  final bool isActive;
  final DateTime createdAt;

  const PetModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerPhotoUrl,
    this.ownerVerified = false,
    required this.name,
    required this.type,
    required this.breed,
    required this.age,
    required this.sex,
    required this.size,
    this.vaccinesUpToDate = false,
    this.sterilized = false,
    required this.photos,
    this.description,
    this.distanceKm,
    this.isActive = true,
    required this.createdAt,
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

  String get typeLabel => type == PetType.dog ? 'Perro' : 'Gato';

  String get sexLabel => sex == PetSex.male ? 'Macho' : 'Hembra';

  String get sizeLabel {
    switch (size) {
      case PetSize.small:
        return 'Pequeño';
      case PetSize.medium:
        return 'Mediano';
      case PetSize.large:
        return 'Grande';
    }
  }

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      ownerName: json['owner_name'] as String,
      ownerPhotoUrl: json['owner_photo_url'] as String?,
      ownerVerified: json['owner_verified'] as bool? ?? false,
      name: json['name'] as String,
      type: json['type'] == 'dog' ? PetType.dog : PetType.cat,
      breed: json['breed'] as String,
      age: json['age'] as String,
      sex: json['sex'] == 'male' ? PetSex.male : PetSex.female,
      size: _parseSize(json['size'] as String),
      vaccinesUpToDate: json['vaccines_up_to_date'] as bool? ?? false,
      sterilized: json['sterilized'] as bool? ?? false,
      photos: List<String>.from(json['photos'] as List? ?? []),
      description: json['description'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static PetSize _parseSize(String s) {
    switch (s) {
      case 'small':
        return PetSize.small;
      case 'large':
        return PetSize.large;
      default:
        return PetSize.medium;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'owner_name': ownerName,
        'owner_photo_url': ownerPhotoUrl,
        'owner_verified': ownerVerified,
        'name': name,
        'type': type == PetType.dog ? 'dog' : 'cat',
        'breed': breed,
        'age': age,
        'sex': sex == PetSex.male ? 'male' : 'female',
        'size': size.name,
        'vaccines_up_to_date': vaccinesUpToDate,
        'sterilized': sterilized,
        'photos': photos,
        'description': description,
        'distance_km': distanceKm,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  PetModel copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? ownerPhotoUrl,
    bool? ownerVerified,
    String? name,
    PetType? type,
    String? breed,
    String? age,
    PetSex? sex,
    PetSize? size,
    bool? vaccinesUpToDate,
    bool? sterilized,
    List<String>? photos,
    String? description,
    double? distanceKm,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return PetModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhotoUrl: ownerPhotoUrl ?? this.ownerPhotoUrl,
      ownerVerified: ownerVerified ?? this.ownerVerified,
      name: name ?? this.name,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      size: size ?? this.size,
      vaccinesUpToDate: vaccinesUpToDate ?? this.vaccinesUpToDate,
      sterilized: sterilized ?? this.sterilized,
      photos: photos ?? this.photos,
      description: description ?? this.description,
      distanceKm: distanceKm ?? this.distanceKm,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
