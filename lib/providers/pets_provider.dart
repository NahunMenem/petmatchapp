import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pet_model.dart';
import '../models/received_like_model.dart';
import 'auth_provider.dart';
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
final exploreBreedProvider = StateProvider<String>((ref) => '');
final exploreVaccinatedOnlyProvider = StateProvider<bool>((ref) => false);
final exploreSterilizedOnlyProvider = StateProvider<bool>((ref) => false);

// My Pets
final myPetsProvider = FutureProvider<List<PetModel>>((ref) async {
  return ref.read(petServiceProvider).getMyPets();
});

// Explore pets (swipe stack)
class ExploreNotifier extends AsyncNotifier<List<PetModel>> {
  int _page = 1;
  String? _typeFilter;

  @override
  Future<List<PetModel>> build() async {
    ref.watch(authProvider.select((state) => state.valueOrNull?.user?.id));
    ref.watch(exploreLocationProvider);
    ref.watch(exploreMaxDistanceProvider);
    ref.watch(exploreBreedProvider);
    ref.watch(exploreVaccinatedOnlyProvider);
    ref.watch(exploreSterilizedOnlyProvider);
    _page = 1;
    return _fetch();
  }

  Future<List<PetModel>> _fetch() async {
    final service = ref.read(petServiceProvider);
    final location = ref.read(exploreLocationProvider);
    final maxDistanceKm = ref.read(exploreMaxDistanceProvider);
    final breed = ref.read(exploreBreedProvider);
    final vaccinatedOnly = ref.read(exploreVaccinatedOnlyProvider);
    final sterilizedOnly = ref.read(exploreSterilizedOnlyProvider);
    return service.getExplorePets(
      type: _typeFilter,
      breed: breed,
      vaccinatedOnly: vaccinatedOnly,
      sterilizedOnly: sterilizedOnly,
      lat: location?.latitude,
      lng: location?.longitude,
      maxDistanceKm: maxDistanceKm,
      page: _page,
    );
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
    await ref.read(petServiceProvider).likePet(pet.id);
  }

  Future<void> superLikeCurrentPet() async {
    final current = state.value;
    if (current == null || current.isEmpty) return;
    final pet = current[0];
    removeCurrent();
    await ref.read(petServiceProvider).superLikePet(pet.id);
  }

  Future<void> dislikeCurrentPet() async {
    final current = state.value;
    if (current == null || current.isEmpty) return;
    final pet = current[0];
    removeCurrent();
    await ref.read(petServiceProvider).dislikePet(pet.id);
  }

  void setTypeFilter(String? type) {
    _typeFilter = type;
    _page = 1;
    ref.invalidateSelf();
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
