import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import '../models/patitas_model.dart';
import '../services/patitas_service.dart';

final patitasServiceProvider = Provider<PatitasService>((ref) {
  return PatitasService();
});

final patitasPacksProvider = FutureProvider<List<PatitasPack>>((ref) async {
  try {
    return await ref.read(patitasServiceProvider).getPacks();
  } catch (_) {
    return PatitasFallback.packs;
  }
});

final patitasWalletProvider =
    AsyncNotifierProvider<PatitasWalletNotifier, PatitasWallet>(
  PatitasWalletNotifier.new,
);

class AdvancedFiltersNotifier extends AsyncNotifier<AdvancedFiltersAccess> {
  @override
  Future<AdvancedFiltersAccess> build() {
    return ref.read(patitasServiceProvider).getAdvancedFiltersAccess();
  }

  Future<void> activate() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final access =
          await ref.read(patitasServiceProvider).activateAdvancedFilters();
      await ref.read(patitasWalletProvider.notifier).refresh();
      return access;
    });
  }
}

final advancedFiltersProvider =
    AsyncNotifierProvider<AdvancedFiltersNotifier, AdvancedFiltersAccess>(
  AdvancedFiltersNotifier.new,
);

class PatitasWalletNotifier extends AsyncNotifier<PatitasWallet> {
  @override
  Future<PatitasWallet> build() async {
    final authState = ref.watch(authProvider).valueOrNull;
    final user = authState?.user;
    if (authState?.status != AuthStatus.authenticated ||
        user == null ||
        user.id == 'guest') {
      return PatitasFallback.wallet;
    }

    try {
      return await ref.read(patitasServiceProvider).getWallet();
    } catch (_) {
      return PatitasWallet(
        patitas: user.patitas,
        transactions: const [],
      );
    }
  }

  Future<void> refresh() async {
    final authState = ref.read(authProvider).valueOrNull;
    final user = authState?.user;
    if (authState?.status != AuthStatus.authenticated ||
        user == null ||
        user.id == 'guest') {
      state = const AsyncValue.data(PatitasFallback.wallet);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final wallet = await ref.read(patitasServiceProvider).getWallet();
      state = AsyncValue.data(wallet);
    } catch (_) {
      state = AsyncValue.data(
        PatitasWallet(
          patitas: user.patitas,
          transactions: const [],
        ),
      );
    }
  }

  Future<void> consume({
    required String action,
    String? description,
  }) async {
    state = await AsyncValue.guard(() {
      return ref.read(patitasServiceProvider).consume(
            action: action,
            description: description,
          );
    });
  }
}
