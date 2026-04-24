import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shop_model.dart';
import '../services/shops_service.dart';

class ShopsLocation {
  final double latitude;
  final double longitude;

  const ShopsLocation({
    required this.latitude,
    required this.longitude,
  });
}

final shopsServiceProvider = Provider<ShopsService>((ref) {
  return ShopsService();
});

final shopsLocationProvider = StateProvider<ShopsLocation?>((ref) {
  return null;
});

final shopsTipoFilterProvider = StateProvider<String?>((ref) {
  return null;
});

final shopsSearchProvider = StateProvider<String>((ref) {
  return '';
});

final shopsProvider = FutureProvider.autoDispose<List<ShopModel>>((ref) {
  final location = ref.watch(shopsLocationProvider);
  final tipo = ref.watch(shopsTipoFilterProvider);
  final search = ref.watch(shopsSearchProvider);

  return ref.read(shopsServiceProvider).getShopsCercanos(
        lat: location?.latitude,
        lng: location?.longitude,
        tipo: tipo,
        search: search.isEmpty ? null : search,
      );
});
