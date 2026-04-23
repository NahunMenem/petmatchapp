import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:badges/badges.dart' as badges;
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/chat_provider.dart';
import '../../providers/patitas_provider.dart';
import '../../providers/pets_provider.dart';
import '../explore/explore_screen.dart';
import '../chat/chat_list_screen.dart';
import '../adoption/adoption_screen.dart';
import '../lost_pets/lost_pets_screen.dart';
import '../profile/profile_screen.dart';

final _selectedTabProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Set<int> _loadedTabs = {0};

  static const _screens = [
    ExploreScreen(),
    AdoptionScreen(),
    LostPetsScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(_selectedTabProvider);
    final unreadCount = ref.watch(totalUnreadProvider);
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
                  ref.read(_selectedTabProvider.notifier).state = i;
                },
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.explore_outlined),
                    activeIcon: Icon(Icons.explore),
                    label: 'EXPLORAR',
                  ),
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
      color: AppColors.primary.withValues(alpha: 0.1),
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
