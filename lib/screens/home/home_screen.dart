import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:badges/badges.dart' as badges;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/lost_pets_provider.dart';
import '../../providers/patitas_provider.dart';
import '../../providers/pets_provider.dart';
import '../../services/push_notification_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/home_intro_dialog.dart';
import '../explore/explore_screen.dart';
import '../chat/chat_list_screen.dart';
import '../adoption/adoption_screen.dart';
import '../lost_pets/lost_pets_screen.dart';
import '../profile/profile_screen.dart';

final selectedHomeTabProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Set<int> _loadedTabs = {0};
  bool _checkedWelcomePermissions = false;
  bool _checkedIntroModal = false;

  static const _screens = [
    AdoptionScreen(),
    LostPetsScreen(),
    ExploreScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowIntroModal();
      _maybeShowPermissionsPrompt();
    });
  }

  Future<void> _maybeShowIntroModal() async {
    if (!mounted || _checkedIntroModal) return;
    _checkedIntroModal = true;

    final seenIntro = await StorageService.getHomeIntroSeen();
    if (!mounted || seenIntro) return;

    await showHomeIntroDialog(context);
  }

  Future<void> _maybeShowPermissionsPrompt() async {
    if (!mounted || _checkedWelcomePermissions) return;
    _checkedWelcomePermissions = true;

    final notificationEnabled =
        await PushNotificationService.instance.areNotificationsEnabled();
    final locationEnabled = await _hasUsableLocationPermission();

    if (!mounted || (notificationEnabled && locationEnabled)) return;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PermissionsWelcomeSheet(
        needsNotifications: !notificationEnabled,
        needsLocation: !locationEnabled,
      ),
    );

    if (result == true && mounted) {
      await _requestMissingPermissions(
        requestNotifications: !notificationEnabled,
        requestLocation: !locationEnabled,
      );
    }
  }

  Future<bool> _hasUsableLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _requestMissingPermissions({
    required bool requestNotifications,
    required bool requestLocation,
  }) async {
    if (requestNotifications) {
      await PushNotificationService.instance.requestPermissionAndRegister();
    }

    if (requestLocation) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          ref.read(exploreLocationProvider.notifier).state = ExploreLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          );
          final updatedUser =
              await ref.read(authServiceProvider).updateLocation(
                    latitude: position.latitude,
                    longitude: position.longitude,
                  );
          ref.read(authProvider.notifier).updateUser(updatedUser);
          ref.invalidate(exploreProvider);
        } catch (_) {}
      } else if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      }
    }
  }

  Future<void> _refreshLostPetsLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      ref.read(lostPetsLocationProvider.notifier).state = LostPetsLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      ref.invalidate(lostPetsProvider);
    } catch (_) {
      // Perdidos sigue funcionando con la ultima ubicacion disponible.
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawSelectedTab = ref.watch(selectedHomeTabProvider);
    final selectedTab = rawSelectedTab.clamp(0, _screens.length - 1);
    final unreadCount = ref.watch(totalUnreadProvider);

    if (rawSelectedTab != selectedTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(selectedHomeTabProvider.notifier).state = selectedTab;
      });
    }

    _loadedTabs.add(selectedTab);

    return Scaffold(
      body: IndexedStack(
        index: selectedTab,
        children: List.generate(
          _screens.length,
          (index) => _loadedTabs.contains(index)
              ? _screens[index]
              : const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _NavQuickStats(),
              BottomNavigationBar(
                currentIndex: selectedTab,
                onTap: (i) {
                  setState(() => _loadedTabs.add(i));
                  ref.read(selectedHomeTabProvider.notifier).state = i;
                  if (i == 1) {
                    _refreshLostPetsLocation();
                  }
                  if (i == 3) {
                    ref.invalidate(conversationsProvider);
                  }
                },
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.favorite_border_rounded),
                    activeIcon: Icon(Icons.favorite_rounded),
                    label: 'ADOPTAR',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.location_on_outlined),
                    activeIcon: Icon(Icons.location_on_rounded),
                    label: 'PERDIDOS',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.explore_outlined),
                    activeIcon: Icon(Icons.explore),
                    label: 'EXPLORAR',
                  ),
                  BottomNavigationBarItem(
                    icon: badges.Badge(
                      showBadge: unreadCount > 0,
                      badgeContent: Text(
                        '$unreadCount',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 9),
                      ),
                      badgeStyle: const badges.BadgeStyle(
                        badgeColor: AppColors.secondary,
                      ),
                      child: const Icon(Icons.chat_bubble_outline),
                    ),
                    activeIcon: const Icon(Icons.chat_bubble),
                    label: 'CHAT',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'PERFIL',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionsWelcomeSheet extends StatelessWidget {
  final bool needsNotifications;
  final bool needsLocation;

  const _PermissionsWelcomeSheet({
    required this.needsNotifications,
    required this.needsLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.matchGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Mejorá tu experiencia en PawMatch',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Activá permisos clave para encontrar mascotas cerca, recibir avisos útiles y ayudar más rápido a mascotas perdidas o extraviadas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            if (needsNotifications)
              const _PermissionFeatureTile(
                icon: Icons.notifications_active_rounded,
                title: 'Notificaciones',
                subtitle:
                    'Recibí likes, matches, mensajes y alertas importantes.',
              ),
            if (needsNotifications && needsLocation) const SizedBox(height: 12),
            if (needsLocation)
              const _PermissionFeatureTile(
                icon: Icons.location_on_rounded,
                title: 'Ubicación',
                subtitle:
                    'Mostrá mascotas cercanas y ayudá con casos de extravío.',
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.favorite_rounded),
                label: Text(
                  needsNotifications && needsLocation
                      ? 'Activar permisos'
                      : needsNotifications
                          ? 'Activar notificaciones'
                          : 'Activar ubicación',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Ahora no',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionFeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PermissionFeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavQuickStats extends ConsumerWidget {
  const _NavQuickStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patitas = ref.watch(patitasWalletProvider).valueOrNull?.patitas ?? 0;
    final likes = ref.watch(receivedLikesProvider).valueOrNull?.total ?? 0;

    return Container(
      height: 36,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NavChip(
              icon: Icons.pets,
              label: '$patitas Patitas',
              onTap: () => context.push('/paw-points'),
            ),
            const SizedBox(width: 8),
            _NavChip(
              icon: Icons.favorite_rounded,
              label: '$likes Likes',
              onTap: () => context.push('/likes-received'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 15),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
