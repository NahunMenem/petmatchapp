import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/adoption_model.dart';
import '../services/adoption_service.dart';

final adoptionServiceProvider =
    Provider<AdoptionService>((ref) => AdoptionService());

class AdoptionFilters {
  final String? type; // 'dog' | 'cat' | null = all
  final int maxDistanceKm;
  final String? size;
  final String? sex;

  const AdoptionFilters({
    this.type,
    this.maxDistanceKm = 15,
    this.size,
    this.sex,
  });

  AdoptionFilters copyWith({
    String? type,
    int? maxDistanceKm,
    String? size,
    String? sex,
    bool clearType = false,
    bool clearSize = false,
    bool clearSex = false,
  }) {
    return AdoptionFilters(
      type: clearType ? null : (type ?? this.type),
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      size: clearSize ? null : (size ?? this.size),
      sex: clearSex ? null : (sex ?? this.sex),
    );
  }
}

final adoptionFiltersProvider =
    StateProvider<AdoptionFilters>((ref) => const AdoptionFilters());

class AdoptionLocation {
  final double latitude;
  final double longitude;

  const AdoptionLocation({
    required this.latitude,
    required this.longitude,
  });
}

final adoptionLocationProvider =
    StateProvider<AdoptionLocation?>((ref) => null);

final adoptionsProvider = FutureProvider<List<AdoptionModel>>((ref) async {
  final filters = ref.watch(adoptionFiltersProvider);
  final location = ref.watch(adoptionLocationProvider);
  final service = ref.read(adoptionServiceProvider);
  return service.getAdoptions(
    type: filters.type,
    maxDistanceKm: filters.maxDistanceKm,
    size: filters.size,
    sex: filters.sex,
    latitude: location?.latitude,
    longitude: location?.longitude,
  );
});

final myAdoptionsProvider = FutureProvider<List<AdoptionModel>>((ref) async {
  return ref.read(adoptionServiceProvider).getMyAdoptions();
});
