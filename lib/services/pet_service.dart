import '../core/constants/api_constants.dart';
import '../models/pet_model.dart';
import '../models/received_like_model.dart';
import 'api_service.dart';

class SwipeResult {
  final bool isMatch;
  final String? conversationId;

  const SwipeResult({
    required this.isMatch,
    this.conversationId,
  });

  factory SwipeResult.fromJson(Map<String, dynamic> json) {
    return SwipeResult(
      isMatch: json['match'] as bool? ?? false,
      conversationId: json['conversation_id'] as String?,
    );
  }
}

class PetService {
  final _api = ApiService();

  Future<List<PetModel>> getExplorePets({
    String? type,
    String? breed,
    bool vaccinatedOnly = false,
    bool sterilizedOnly = false,
    double? lat,
    double? lng,
    int maxDistanceKm = 10,
    int page = 1,
  }) async {
    final response = await _api.get(
      ApiConstants.explore,
      queryParams: {
        if (type != null) 'type': type,
        if (breed != null && breed.trim().isNotEmpty) 'breed': breed.trim(),
        if (vaccinatedOnly) 'vaccinated': true,
        if (sterilizedOnly) 'sterilized': true,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'max_distance': maxDistanceKm,
        'page': page,
      },
    );
    final list = response.data as List;
    return list
        .map((e) => PetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PetModel>> getMyPets() async {
    final response = await _api.get(ApiConstants.myPets);
    final list = response.data as List;
    return list
        .map((e) => PetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PetModel> createPet(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConstants.pets, data: data);
    return PetModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PetModel> updatePet(String id, Map<String, dynamic> data) async {
    final response = await _api.put('${ApiConstants.pets}/$id', data: data);
    return PetModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePet(String id) async {
    await _api.delete('${ApiConstants.pets}/$id');
  }

  Future<SwipeResult> likePet(String petId) async {
    final response = await _api.post(ApiConstants.like, data: {'pet_id': petId});
    return SwipeResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SwipeResult> superLikePet(String petId) async {
    final response = await _api.post(
      ApiConstants.superLike,
      data: {'pet_id': petId},
    );
    return SwipeResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> dislikePet(String petId) async {
    await _api.post(ApiConstants.dislike, data: {'pet_id': petId});
  }

  Future<ReceivedLikesModel> getReceivedLikes() async {
    final response = await _api.get(ApiConstants.likesReceived);
    return ReceivedLikesModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ReceivedLikesModel> unlockReceivedLikes() async {
    final response = await _api.post(ApiConstants.unlockLikesReceived);
    return ReceivedLikesModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> uploadPhoto(String filePath) async {
    final response = await _api.uploadFile(
      ApiConstants.upload,
      filePath,
      fieldName: 'photo',
    );
    return response.data['url'] as String;
  }
}
