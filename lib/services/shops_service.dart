import '../core/constants/api_constants.dart';
import '../models/shop_model.dart';
import 'api_service.dart';

class ShopsService {
  final ApiService _api = ApiService();

  Future<List<ShopModel>> getShopsCercanos({
    double? lat,
    double? lng,
    String? tipo,
    String? search,
  }) async {
    final response = await _api.get(
      ApiConstants.shopsCercanos,
      queryParams: {
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (tipo != null) 'tipo': tipo,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return (response.data as List)
        .map((item) => ShopModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ShopModel> getShop(String id) async {
    final response = await _api.get('${ApiConstants.shopsDetail}/$id');
    return ShopModel.fromJson(response.data as Map<String, dynamic>);
  }
}
