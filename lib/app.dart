import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'models/message_model.dart';
import 'providers/auth_provider.dart';
import 'providers/pets_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/onboarding/create_pet_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/chat/chat_detail_screen.dart';
import 'screens/adoption/publish_adoption_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/likes/received_likes_screen.dart';
import 'screens/profile/paw_points_screen.dart';
import 'screens/profile/referrals_screen.dart';
import 'services/push_notification_service.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  final authRouteState = ref.watch(
    authProvider.select(
      (state) => (
        isLoading: state.isLoading,
        status: state.valueOrNull?.status,
      ),
    ),
  );

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final status = authRouteState.status;
      final isAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (authRouteState.isLoading) return null;

      if (status == AuthStatus.authenticated) {
        if (isAuthPage) return '/home';
      } else if (status == AuthStatus.unauthenticated) {
        if (!isAuthPage) return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/create-pet',
        builder: (_, __) => const CreatePetScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (_, state) {
          final conversationId = state.pathParameters['conversationId']!;
          final conversation = state.extra as ConversationModel?;
          return ChatDetailScreen(
            conversationId: conversationId,
            conversation: conversation,
          );
        },
      ),
      GoRoute(
        path: '/adoption/publish',
        builder: (_, __) => const PublishAdoptionScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/likes-received',
        builder: (_, __) => const ReceivedLikesScreen(),
      ),
      GoRoute(
        path: '/paw-points',
        builder: (_, __) => const PawPointsScreen(),
      ),
      GoRoute(
        path: '/paw-points/buy',
        builder: (_, __) => const BuyPawPointsScreen(),
      ),
      GoRoute(
        path: '/referrals',
        builder: (_, __) => const ReferralsScreen(),
      ),
    ],
  );
});

class PawMatchApp extends ConsumerWidget {
  const PawMatchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    ref.listen(authProvider, (previous, next) {
      final previousStatus = previous?.valueOrNull?.status;
      final status = next.valueOrNull?.status;
      if (status == AuthStatus.authenticated &&
          previousStatus != AuthStatus.authenticated) {
        ref.invalidate(myPetsProvider);
        ref.invalidate(exploreProvider);
        ref.invalidate(receivedLikesProvider);
        PushNotificationService.instance.start();
        PushNotificationService.instance.registerDeviceForUser();
      }
    });

    return MaterialApp.router(
      title: 'PawMatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
