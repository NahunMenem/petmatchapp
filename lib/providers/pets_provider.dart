import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pet_model.dart';
import '../models/received_like_model.dart';
import 'auth_provider.dart';
import 'chat_provider.dart';
import 'patitas_provider.dart';
import '../services/pet_service.dart';

final petServiceProvider = Provider<PetService>((ref) => PetService());

class ExploreLocation {
  final double latitude;
  final double longitude;

  const ExploreLocation({
    required this.latitude,
    required this.longitude,
  });
}

final exploreLocationProvider = StateProvider<ExploreLocation?>((ref) => null);
final exploreMaxDistanceProvider = StateProvider<int>((ref) => 10);
final exploreTypeProvider = StateProvider<String?>((ref) => null);
final exploreBreedProvider = StateProvider<String>((ref) => '');
final exploreSexProvider = StateProvider<String?>((ref) => null);
final exploreVaccinatedOnlyProvider = StateProvider<bool>((ref) => false);
final exploreSterilizedOnlyProvider = StateProvider<bool>((ref) => false);

// My Pets
final myPetsProvider = FutureProvider<List<PetModel>>((ref) async {
  return ref.read(petServiceProvider).getMyPets();
});

// Explore pets (swipe stack)
class ExploreNotifier extends AsyncNotifier<List<PetModel>> {
  int _page = 1;
  @override
  Future<List<PetModel>> build() async {
    ref.watch(authProvider.select((state) => state.valueOrNull?.user?.id));
    ref.watch(exploreLocationProvider);
    ref.watch(exploreMaxDistanceProvider);
    ref.watch(exploreTypeProvider);
    ref.watch(exploreBreedProvider);
    ref.watch(exploreSexProvider);
    ref.watch(exploreVaccinatedOnlyProvider);
    ref.watch(exploreSterilizedOnlyProvider);
    ref.watch(
      advancedFiltersProvider.select((state) => state.valueOrNull?.active ?? false),
    );
    _page = 1;
    return _fetch();
  }

  Future<List<PetModel>> _fetch() async {
    final service = ref.read(petServiceProvider);
    final location = ref.read(exploreLocationProvider);
    final maxDistanceKm = ref.read(exploreMaxDistanceProvider);
    final type = ref.read(exploreTypeProvider);
    final breed = ref.read(exploreBreedProvider);
    final sex = ref.read(exploreSexProvider);
    final vaccinatedOnly = ref.read(exploreVaccinatedOnlyProvider);
    final sterilizedOnly = ref.read(exploreSterilizedOnlyProvider);
    final advancedFiltersActive =
        ref.read(advancedFiltersProvider).valueOrNull?.active ?? false;
    final effectiveMaxDistanceKm = advancedFiltersActive
        ? maxDistanceKm.clamp(10, 50)
        : 10;
    final pets = await service.getExplorePets(
      type: type,
      breed: breed,
      sex: sex,
      vaccinatedOnly: vaccinatedOnly,
      sterilizedOnly: sterilizedOnly,
      lat: location?.latitude,
      lng: location?.longitude,
      maxDistanceKm: effectiveMaxDistanceKm,
      page: _page,
    );
    return pets.where((pet) => pet.isActive).toList();
  }

  Future<void> loadMore() async {
    _page++;
    final more = await _fetch();
    if (more.isEmpty) {
      _page--;
      return;
    }
    state = AsyncValue.data([...state.value ?? [], ...more]);
  }

  void removeCurrent() {
    final current = state.value ?? [];
    if (current.isNotEmpty) {
      state = AsyncValue.data(current.sublist(1));
      if (current.length <= 3) loadMore();
    }
  }

  Future<void> likeCurrentPet() async {
    final current = state.value;
    if (current == null || current.isEmpty) return;
    final pet = current[0];
    removeCurrent();
    final result = await ref.read(petServiceProvider).likePet(pet.id);
    if (result.isMatch) {
      ref.read(matchPetProvider.notifier).state = pet;
      ref.invalidate(conversationsProvider);
    }
  }

  Future<void> superLikeCurrentPet() async {
    final current = state.value;
    if (current == null || current.isEmpty) return;
    final pet = current[0];
    removeCurrent();
    final result = await ref.read(petServiceProvider).superLikePet(pet.id);
    if (result.isMatch) {
      ref.read(matchPetProvider.notifier).state = pet;
      ref.invalidate(conversationsProvider);
    }
  }

  Future<void> dislikeCurrentPet() async {
    final current = state.value;
    if (current == null || current.isEmpty) return;
    removeCurrent();
  }
}

final exploreProvider = AsyncNotifierProvider<ExploreNotifier, List<PetModel>>(
  ExploreNotifier.new,
);

// Match popup state
final matchPetProvider = StateProvider<PetModel?>((ref) => null);

class ReceivedLikesNotifier extends AsyncNotifier<ReceivedLikesModel> {
  @override
  Future<ReceivedLikesModel> build() async {
    try {
      return await ref.read(petServiceProvider).getReceivedLikes();
    } catch (_) {
      return const ReceivedLikesModel(total: 0, unlocked: false, likes: []);
    }
  }

  Future<void> unlock() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(petServiceProvider).unlockReceivedLikes();
    });
  }
}

final receivedLikesProvider =
    AsyncNotifierProvider<ReceivedLikesNotifier, ReceivedLikesModel>(
  ReceivedLikesNotifier.new,
);
