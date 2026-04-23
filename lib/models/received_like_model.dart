class ReceivedLikeModel {
  final String? petId;
  final String? petName;
  final String? petPhoto;
  final String? petType;
  final String? breed;
  final String? age;
  final String? sex;
  final String? size;
  final bool? vaccinesUpToDate;
  final bool? sterilized;
  final List<String> photos;
  final String? description;
  final bool responseSent;
  final String? ownerName;
  final String? likedMyPetId;
  final String? likedMyPetName;

  const ReceivedLikeModel({
    this.petId,
    this.petName,
    this.petPhoto,
    this.petType,
    this.breed,
    this.age,
    this.sex,
    this.size,
    this.vaccinesUpToDate,
    this.sterilized,
    this.photos = const [],
    this.description,
    this.responseSent = false,
    this.ownerName,
    this.likedMyPetId,
    this.likedMyPetName,
  });

  factory ReceivedLikeModel.fromJson(Map<String, dynamic> json) {
    return ReceivedLikeModel(
      petId: json['pet_id'] as String?,
      petName: json['pet_name'] as String?,
      petPhoto: json['pet_photo'] as String?,
      petType: json['pet_type'] as String?,
      breed: json['breed'] as String?,
      age: json['age'] as String?,
      sex: json['sex'] as String?,
      size: json['size'] as String?,
      vaccinesUpToDate: json['vaccines_up_to_date'] as bool?,
      sterilized: json['sterilized'] as bool?,
      photos: List<String>.from(json['photos'] as List? ?? []),
      description: json['description'] as String?,
      responseSent: json['response_sent'] as bool? ?? false,
      ownerName: json['owner_name'] as String?,
      likedMyPetId: json['liked_my_pet_id'] as String?,
      likedMyPetName: json['liked_my_pet_name'] as String?,
    );
  }
}

class ReceivedLikesModel {
  final int total;
  final bool unlocked;
  final List<ReceivedLikeModel> likes;

  const ReceivedLikesModel({
    required this.total,
    required this.unlocked,
    required this.likes,
  });

  factory ReceivedLikesModel.fromJson(Map<String, dynamic> json) {
    return ReceivedLikesModel(
      total: json['total'] as int? ?? 0,
      unlocked: json['unlocked'] as bool? ?? false,
      likes: (json['likes'] as List<dynamic>? ?? [])
          .map((item) => ReceivedLikeModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
