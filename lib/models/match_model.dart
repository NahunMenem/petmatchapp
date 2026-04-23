class MatchModel {
  final String id;
  final String petId;
  final String petName;
  final String petPhoto;
  final String ownerName;
  final String ownerPhoto;
  final String conversationId;
  final DateTime matchedAt;

  const MatchModel({
    required this.id,
    required this.petId,
    required this.petName,
    required this.petPhoto,
    required this.ownerName,
    required this.ownerPhoto,
    required this.conversationId,
    required this.matchedAt,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      petName: json['pet_name'] as String,
      petPhoto: json['pet_photo'] as String,
      ownerName: json['owner_name'] as String,
      ownerPhoto: json['owner_photo'] as String? ?? '',
      conversationId: json['conversation_id'] as String,
      matchedAt: DateTime.parse(json['matched_at'] as String),
    );
  }
}
