import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';
import '../services/storage_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final service = ref.read(authServiceProvider);
    final token = await StorageService.getAccessToken();

    if (token == null) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }

    try {
      final user = await service.getMe();
      return AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await StorageService.clearAll();
      return const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> loginAsGuest(String name) async {
    await StorageService.saveUsername(name.trim());
    state = AsyncValue.data(
      AuthState(
        status: AuthStatus.authenticated,
        user: UserModel(
          id: 'guest',
          email: '',
          name: name.trim(),
          createdAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(authServiceProvider);
      final user = await service.login(email: email, password: password);
      return AuthState(status: AuthStatus.authenticated, user: user);
    });
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(authServiceProvider);
      final user = await service.register(
        name: name,
        email: email,
        password: password,
      );
      return AuthState(status: AuthStatus.authenticated, user: user);
    });
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(authServiceProvider);
      final user = await service.signInWithGoogle();
      if (user == null) {
        return const AuthState(status: AuthStatus.unauthenticated);
      }
      return AuthState(status: AuthStatus.authenticated, user: user);
    });
  }

  Future<void> logout() async {
    final service = ref.read(authServiceProvider);
    await PushNotificationService.instance.unregisterDevice();
    await service.logout();
    state = const AsyncValue.data(
      AuthState(status: AuthStatus.unauthenticated),
    );
  }

  void updateUser(UserModel user) {
    state = AsyncValue.data(
      state.value!.copyWith(status: AuthStatus.authenticated, user: user),
    );
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
