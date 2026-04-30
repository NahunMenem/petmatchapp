import '../core/constants/api_constants.dart';
import '../models/adoption_model.dart';
import 'api_service.dart';

class AdoptionService {
  final _api = ApiService();

  Future<List<AdoptionModel>> getAdoptions({
    String? type,
    int? maxDistanceKm,
    String? size,
    double? latitude,
    double? longitude,
    int page = 1,
  }) async {
    final response = await _api.get(
      ApiConstants.adoptions,
      queryParams: {
        if (type != null) 'type': type,
        if (maxDistanceKm != null) 'max_distance': maxDistanceKm,
        if (size != null) 'size': size,
        if (latitude != null) 'lat': latitude,
        if (longitude != null) 'lng': longitude,
        'page': page,
      },
    );
    final list = response.data as List;
    return list
        .map((e) => AdoptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdoptionModel> publishAdoption(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConstants.adoptions, data: data);
    return AdoptionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AdoptionModel>> getMyAdoptions() async {
    final response = await _api.get(ApiConstants.myAdoptions);
    final list = response.data as List;
    return list
        .map((e) => AdoptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdoptionModel> updateAdoptionStatus(
    String adoptionId,
    AdoptionStatus status,
  ) async {
    final response = await _api.patch(
      '${ApiConstants.adoptions}/$adoptionId/status',
      data: {'status': status.name},
    );
    return AdoptionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAdoption(String adoptionId) async {
    await _api.delete('${ApiConstants.adoptions}/$adoptionId');
  }

  Future<void> contactForAdoption(String adoptionId) async {
    await _api.post('${ApiConstants.adoptions}/$adoptionId/contact');
  }
}
