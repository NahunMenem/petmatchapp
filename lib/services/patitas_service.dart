import '../core/constants/api_constants.dart';
import '../models/patitas_model.dart';
import 'api_service.dart';

class PatitasService {
  final ApiService _api = ApiService();

  Future<List<PatitasPack>> getPacks() async {
    final response = await _api.get(ApiConstants.patitasPacks);
    return (response.data as List<dynamic>)
        .map((item) => PatitasPack.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PatitasWallet> getWallet() async {
    final response = await _api.get(ApiConstants.patitasWallet);
    return PatitasWallet.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PatitasPreference> createPreference(String packId) async {
    final response = await _api.post(
      ApiConstants.createPatitasPreference,
      data: {'pack_id': packId},
    );
    return PatitasPreference.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PatitasWallet> consume({
    required String action,
    String? description,
  }) async {
    await _api.post(
      ApiConstants.patitasConsume,
      data: {
        'action': action,
        if (description != null) 'descripcion': description,
      },
    );
    return getWallet();
  }

  Future<AdvancedFiltersAccess> getAdvancedFiltersAccess() async {
    final response = await _api.get(ApiConstants.advancedFilters);
    return AdvancedFiltersAccess.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<AdvancedFiltersAccess> activateAdvancedFilters() async {
    final response = await _api.post(ApiConstants.activateAdvancedFilters);
    return AdvancedFiltersAccess.fromJson(
        response.data as Map<String, dynamic>);
  }
}
