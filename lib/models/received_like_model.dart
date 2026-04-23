class ReceivedLikeModel {
  final String? petId;
  final String? petName;
  final String? petPhoto;
  final String? ownerName;
  final String? likedMyPetId;
  final String? likedMyPetName;

  const ReceivedLikeModel({
    this.petId,
    this.petName,
    this.petPhoto,
    this.ownerName,
    this.likedMyPetId,
    this.likedMyPetName,
  });

  factory ReceivedLikeModel.fromJson(Map<String, dynamic> json) {
    return ReceivedLikeModel(
      petId: json['pet_id'] as String?,
      petName: json['pet_name'] as String?,
      petPhoto: json['pet_photo'] as String?,
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
