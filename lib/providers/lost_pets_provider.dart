import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/lost_pet_model.dart';
import '../services/lost_pets_service.dart';

class LostPetsLocation {
  final double latitude;
  final double longitude;

  const LostPetsLocation({
    required this.latitude,
    required this.longitude,
  });
}

final lostPetsServiceProvider = Provider<LostPetsService>((ref) {
  return LostPetsService();
});

final lostPetsLocationProvider = StateProvider<LostPetsLocation?>((ref) {
  return null;
});

final lostPetsProvider = FutureProvider.autoDispose<List<LostPetModel>>((ref) {
  final location = ref.watch(lostPetsLocationProvider);
  return ref.read(lostPetsServiceProvider).getLostPets(
        latitude: location?.latitude,
        longitude: location?.longitude,
      );
});
