import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/utils/app_snack_bar.dart';
import '../../core/theme/app_colors.dart';
import '../../models/pet_model.dart';
import '../../models/adoption_model.dart';
import '../../providers/adoption_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/patitas_provider.dart';
import '../../providers/pets_provider.dart';
import '../../widgets/home_intro_dialog.dart';
import 'paw_points_screen.dart';
import 'pet_detail_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(myPetsProvider));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider).value;
    final user = authState?.user;
    final myPetsAsync = ref.watch(myPetsProvider);
    final conversationsAsync = ref.watch(conversationsProvider);
    final myAdoptionsAsync = ref.watch(myAdoptionsProvider);
    final patitas = ref.watch(patitasWalletProvider).valueOrNull?.patitas ??
        user?.patitas ??
        0;
    final receivedLikes =
        ref.watch(receivedLikesProvider).valueOrNull?.total ?? 0;
    final petCount = myPetsAsync.valueOrNull?.length ?? 0;
    final matchCount = conversationsAsync.valueOrNull?.length ?? 0;
    final adoptedCount = myAdoptionsAsync.valueOrNull
            ?.where((adoption) => adoption.status == AdoptionStatus.adopted)
            .length ??
        0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with profile
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.matchGradient,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: user?.photoUrl != null
                            ? CachedNetworkImageProvider(user!.photoUrl!)
                            : null,
                        child: user?.photoUrl == null
                            ? Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user?.name ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (user?.isVerified == true) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      if (user?.location != null)
                        Text(
                          user!.location!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // Stats
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _StatCard(value: petCount, label: 'Mascotas'),
                      _StatCard(value: matchCount, label: 'Matches'),
                      _StatCard(value: adoptedCount, label: 'Adoptados'),
                    ],
                  ),
                ),

                // My pets
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Mis mascotas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => context.push('/create-pet'),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                ),

                myPetsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (pets) => pets.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No tenés mascotas aún. ¡Agregá una!',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: pets.length,
                          itemBuilder: (_, i) => _PetListTile(
                            pet: pets[i],
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PetDetailScreen(pet: pets[i]),
                                ),
                              );
                              ref.invalidate(myPetsProvider);
                            },
                            onDelete: () =>
                                _confirmDeletePet(context, ref, pets[i]),
                          ),
                        ),
                ),

                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(),
                ),

                // Options
                _PawPointsTile(
                  points: patitas,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PawPointsScreen(),
                    ),
                  ),
                ),
                _LikesTile(
                  likes: receivedLikes,
                  onTap: () => context.push('/likes-received'),
                ),
                _OptionTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notificaciones',
                  onTap: () => context.push('/notifications'),
                ),
                _OptionTile(
                  icon: Icons.slideshow_rounded,
                  label: 'Cómo funciona PawMatch',
                  onTap: () => showHomeIntroDialog(context),
                ),
                _OptionTile(
                  icon: Icons.logout_outlined,
                  label: 'Cerrar sesión',
                  color: AppColors.error,
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePet(
    BuildContext context,
    WidgetRef ref,
    PetModel pet,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar mascota'),
        content: Text(
          '¿Querés eliminar a ${pet.name}? También se van a cerrar sus matches y chats asociados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(petServiceProvider).deletePet(pet.id);
      ref.invalidate(myPetsProvider);
      ref.invalidate(exploreProvider);
      ref.invalidate(conversationsProvider);
      ref.invalidate(receivedLikesProvider);
      if (!context.mounted) return;
      AppSnackBar.success(
        context,
        title: 'Mascota eliminada',
        message: '${pet.name} fue eliminada de tu perfil.',
      );
    } catch (_) {
      if (!context.mounted) return;
      AppSnackBar.error(
        context,
        message: 'No se pudo eliminar la mascota.',
      );
    }
  }
}

class _PawPointsTile extends StatelessWidget {
  static const double _tileHeight = 68;
  final int points;
  final VoidCallback onTap;

  const _PawPointsTile({
    required this.points,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: const Color(0xFFFFF4DE),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            height: _tileHeight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(
                  Icons.pets_outlined,
                  color: AppColors.primary,
                  size: 26,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Mis Patitas',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$points',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.pets,
                        color: Colors.white,
                        size: 13,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LikesTile extends StatelessWidget {
  static const double _tileHeight = 68;
  final int likes;
  final VoidCallback onTap;

  const _LikesTile({
    required this.likes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            height: _tileHeight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Te dieron likes',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$likes likes',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetListTile extends StatelessWidget {
  final PetModel pet;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PetListTile({
    required this.pet,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 52,
            height: 52,
            child: pet.mainPhoto.isNotEmpty
                ? CachedNetworkImage(imageUrl: pet.mainPhoto, fit: BoxFit.cover)
                : Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.pets, color: AppColors.textHint),
                  ),
          ),
        ),
        title:
            Text(pet.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${pet.breed} · ${pet.age}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: pet.isActive
                    ? AppColors.success.withOpacity(0.12)
                    : AppColors.textHint.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                pet.isActive ? 'Buscando pareja' : 'Desactivada',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color:
                      pet.isActive ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Eliminar mascota',
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  static const double _tileHeight = 68;
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            height: _tileHeight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: (color ?? AppColors.primary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color ?? AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color ?? AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
