import '../core/constants/api_constants.dart';
import '../models/lost_pet_model.dart';
import 'api_service.dart';

class LostPetsService {
  final ApiService _api = ApiService();

  Future<List<LostPetModel>> getLostPets({
    int page = 1,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _api.get(
      ApiConstants.lostPets,
      queryParams: {
        'page': page,
        if (latitude != null) 'lat': latitude,
        if (longitude != null) 'lng': longitude,
      },
    );
    return (response.data as List)
        .map((item) => LostPetModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<LostPetModel> createLostPet({
    String? petId,
    required String name,
    required String type,
    required String description,
    required String phone,
    required List<String> photos,
    required String location,
    double? latitude,
    double? longitude,
    int? rewardAmount,
    int? alertRadiusKm,
  }) async {
    final response = await _api.post(
      ApiConstants.lostPets,
      data: {
        'pet_id': petId,
        'name': name,
        'type': type,
        'description': description,
        'phone': phone,
        'photos': photos,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'reward_amount': rewardAmount,
        'alert_radius_km': alertRadiusKm,
      },
    );
    return LostPetModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LostPetModel> updateStatus({
    required String lostPetId,
    required String status,
  }) async {
    final response = await _api.patch(
      '${ApiConstants.lostPets}/$lostPetId/status',
      data: {'status': status},
    );
    return LostPetModel.fromJson(response.data as Map<String, dynamic>);
  }
}
