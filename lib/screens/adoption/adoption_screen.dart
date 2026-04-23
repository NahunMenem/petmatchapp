import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_snack_bar.dart';
import '../../models/adoption_model.dart';
import '../../providers/adoption_provider.dart';
import '../../providers/auth_provider.dart';

class AdoptionScreen extends ConsumerStatefulWidget {
  static const String _adoptionLogoUrl =
      'https://res.cloudinary.com/dqsacd9ez/image/upload/v1776962386/PawMatch_upljxz.png';

  const AdoptionScreen({super.key});

  @override
  ConsumerState<AdoptionScreen> createState() => _AdoptionScreenState();
}

class _AdoptionScreenState extends ConsumerState<AdoptionScreen> {
  bool _askedLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApproxLocation();
    });
  }

  Future<void> _loadApproxLocation() async {
    if (_askedLocation) return;
    _askedLocation = true;
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
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
      ref.read(adoptionLocationProvider.notifier).state = AdoptionLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final adoptionsAsync = ref.watch(adoptionsProvider);
    final filters = ref.watch(adoptionFiltersProvider);
    final cachedAdoptions = adoptionsAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Image(
            image: NetworkImage(AdoptionScreen._adoptionLogoUrl),
            height: 42,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Mis publicaciones',
            icon: const Icon(Icons.assignment_turned_in_outlined),
            onPressed: () => _showMyAdoptionsSheet(context, ref),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showFiltersSheet(context, ref),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded,
                        size: 15, color: AppColors.primary),
                    SizedBox(width: 5),
                    Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/adoption/publish'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Publicar'),
      ),
      body: Column(
        children: [
          // ── Chips de filtro ─────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TypeFilterChip(
                    label: 'Todos',
                    selected: filters.type == null,
                    onTap: () => ref
                        .read(adoptionFiltersProvider.notifier)
                        .update((s) => s.copyWith(clearType: true)),
                  ),
                  const SizedBox(width: 8),
                  _TypeFilterChip(
                    label: '🐶 Perros',
                    selected: filters.type == 'dog',
                    onTap: () => ref
                        .read(adoptionFiltersProvider.notifier)
                        .update((s) => s.copyWith(type: 'dog')),
                  ),
                  const SizedBox(width: 8),
                  _TypeFilterChip(
                    label: '🐱 Gatos',
                    selected: filters.type == 'cat',
                    onTap: () => ref
                        .read(adoptionFiltersProvider.notifier)
                        .update((s) => s.copyWith(type: 'cat')),
                  ),
                  const SizedBox(width: 8),
                  _TypeFilterChip(
                    label: '📍 Cerca mío',
                    selected: filters.maxDistanceKm <= 5,
                    onTap: () => ref
                        .read(adoptionFiltersProvider.notifier)
                        .update((s) => s.copyWith(maxDistanceKm: 5)),
                  ),
                ],
              ),
            ),
          ),

          // ── Lista de mascotas ────────────────────────────────────────
          Expanded(
            child: cachedAdoptions != null
                ? _AdoptionsList(adoptions: cachedAdoptions)
                : adoptionsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => _AdoptionError(
                      message: 'No pudimos cargar las publicaciones',
                      onRetry: () => ref.invalidate(adoptionsProvider),
                    ),
                    data: (adoptions) => _AdoptionsList(adoptions: adoptions),
                  ),
          ),
        ],
      ),
    );
  }

  void _showFiltersSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FiltersSheet(
        onApply: (newFilters) {
          ref.read(adoptionFiltersProvider.notifier).state = newFilters;
        },
        current: ref.read(adoptionFiltersProvider),
      ),
    );
  }

  void _showMyAdoptionsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _MyAdoptionsSheet(),
    );
  }
}

class _AdoptionsList extends ConsumerWidget {
  final List<AdoptionModel> adoptions;

  const _AdoptionsList({required this.adoptions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (adoptions.isEmpty) {
      return const _EmptyAdoptions();
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(adoptionsProvider.future),
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        itemCount: adoptions.length,
        itemBuilder: (_, i) => _AdoptionCard(adoption: adoptions[i]),
      ),
    );
  }
}

// ignore: unused_element
class _AdoptionHero extends StatelessWidget {
  final String activeCount;

  const _AdoptionHero({required this.activeCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF5EF), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'ADOPCION RESPONSABLE',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Mascotas listas para encontrar un nuevo hogar',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Un feed mas claro, con mejor jerarquia visual y fotos estables aunque una URL falle.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroStat(
                icon: Icons.pets_rounded,
                label: 'Publicaciones',
                value: activeCount,
              ),
              const SizedBox(width: 10),
              const _HeroStat(
                icon: Icons.verified_user_outlined,
                label: 'Proceso',
                value: 'Seguro',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _AdoptionCard extends ConsumerWidget {
  final AdoptionModel adoption;

  const _AdoptionCard({required this.adoption});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authProvider).value?.user?.id;
    final isOwner = currentUserId == adoption.publisherId;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AdoptionPhotoGallery(adoption: adoption),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adoption.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${adoption.typeLabel} · ${adoption.age}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(label: adoption.statusLabel),
                  ],
                ),
                const SizedBox(height: 14),
                _PublisherRow(adoption: adoption),
                const SizedBox(height: 14),
                Text(
                  adoption.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.78),
                        height: 1.45,
                      ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      icon: Icons.location_on_outlined,
                      label:
                          adoption.distanceLabel ?? 'Distancia no disponible',
                    ),
                    _InfoPill(
                      icon: Icons.straighten_outlined,
                      label: _sizeLabel(adoption.size),
                    ),
                    _InfoPill(
                      icon: Icons.health_and_safety_outlined,
                      label: adoption.healthStatus,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isOwner)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: adoption.status == AdoptionStatus.adopted
                                ? null
                                : () async {
                                    await ref
                                        .read(adoptionServiceProvider)
                                        .updateAdoptionStatus(
                                          adoption.id,
                                          AdoptionStatus.adopted,
                                        );
                                    ref.invalidate(adoptionsProvider);
                                    ref.invalidate(myAdoptionsProvider);
                                  },
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Marcar adoptado'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 46,
                        width: 52,
                        child: OutlinedButton(
                          onPressed: () => _confirmDelete(context, ref),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Icon(Icons.delete_outline, size: 20),
                        ),
                      ),
                    ],
                  )
                else if (adoption.status != AdoptionStatus.available)
                  const _AdoptedNotice()
                else
                  adoption.phone.trim().isEmpty
                      ? SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await ref
                                  .read(adoptionServiceProvider)
                                  .contactForAdoption(adoption.id);
                              if (!context.mounted) return;
                              AppSnackBar.success(
                                context,
                                title: 'Chat iniciado',
                                message:
                                    'Conversacion iniciada con el publicador.',
                              );
                              context.go('/chat');
                            },
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                            ),
                            label: const Text('Contactar'),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _ContactButton(
                                icon: Icons.phone_outlined,
                                label: 'Llamar',
                                onTap: () => _callOwner(adoption.phone),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ContactButton(
                                icon: Icons.chat_outlined,
                                label: 'WhatsApp',
                                onTap: () => _openWhatsApp(adoption),
                              ),
                            ),
                          ],
                        ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar publicacion'),
        content: const Text('Seguro que queres eliminar esta publicacion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(adoptionServiceProvider).deleteAdoption(adoption.id);
      ref.invalidate(adoptionsProvider);
      ref.invalidate(myAdoptionsProvider);
    }
  }

  Future<void> _callOwner(String phone) async {
    final uri = Uri.parse('tel:${_normalizePhone(phone)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(AdoptionModel adoption) async {
    final message = Uri.encodeComponent(
      'Hola, vi en PawMatch la publicacion de ${adoption.name} en adopcion.',
    );
    final uri = Uri.parse(
      'https://wa.me/${_normalizePhone(adoption.phone)}?text=$message',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }
}

class _AdoptedNotice extends StatelessWidget {
  const _AdoptedNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: const Text(
        'Adoptado',
        style: TextStyle(
          color: AppColors.success,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MyAdoptionsSheet extends ConsumerWidget {
  const _MyAdoptionsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myAdoptionsAsync = ref.watch(myAdoptionsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(
                children: [
                  Text(
                    'Mis publicaciones',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: myAdoptionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(
                  child: Text(
                    'No pudimos cargar tus publicaciones',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                data: (adoptions) {
                  if (adoptions.isEmpty) {
                    return const Center(
                      child: Text(
                        'Todavia no publicaste mascotas en adopcion',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    itemCount: adoptions.length,
                    itemBuilder: (_, index) => _MyAdoptionTile(
                      adoption: adoptions[index],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MyAdoptionTile extends ConsumerWidget {
  final AdoptionModel adoption;

  const _MyAdoptionTile({required this.adoption});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdopted = adoption.status == AdoptionStatus.adopted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              height: 64,
              child: adoption.mainPhoto.isNotEmpty
                  ? Image.network(adoption.mainPhoto, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.pets),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adoption.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  adoption.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isAdopted ? AppColors.success : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () async {
              await ref.read(adoptionServiceProvider).updateAdoptionStatus(
                    adoption.id,
                    isAdopted
                        ? AdoptionStatus.available
                        : AdoptionStatus.adopted,
                  );
              ref.invalidate(myAdoptionsProvider);
              ref.invalidate(adoptionsProvider);
            },
            style: FilledButton.styleFrom(
              backgroundColor:
                  isAdopted ? AppColors.surfaceVariant : AppColors.primary,
              foregroundColor: isAdopted ? AppColors.textPrimary : Colors.white,
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(isAdopted ? 'Disponible' : 'Adoptado'),
          ),
        ],
      ),
    );
  }
}

class _AdoptionPhotoGallery extends StatefulWidget {
  final AdoptionModel adoption;

  const _AdoptionPhotoGallery({required this.adoption});

  @override
  State<_AdoptionPhotoGallery> createState() => _AdoptionPhotoGalleryState();
}

class _AdoptionPhotoGalleryState extends State<_AdoptionPhotoGallery> {
  final PageController _controller = PageController();
  final Set<String> _failedUrls = <String>{};
  int _currentIndex = 0;

  List<String> get _photos => widget.adoption.photos
      .map((photo) => photo.trim())
      .where((photo) => _isValidUrl(photo) && !_failedUrls.contains(photo))
      .toList();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openViewer(
      BuildContext context, List<String> photos, int initialIndex) {
    final safeInitialIndex = photos.isEmpty
        ? 0
        : initialIndex.clamp(0, photos.length - 1);
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) =>
          _PhotoViewerModal(photos: photos, initialIndex: safeInitialIndex),
    );
  }

  void _markUrlAsFailed(String url) {
    if (_failedUrls.contains(url)) return;

    setState(() {
      _failedUrls.add(url);
      final remaining = _photos.length;
      if (remaining == 0) {
        _currentIndex = 0;
      } else if (_currentIndex >= remaining) {
        _currentIndex = remaining - 1;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.hasClients && _photos.isNotEmpty) {
        _controller.jumpToPage(_currentIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos;

    if (photos.isEmpty) {
      return _photoPlaceholder(height: 220);
    }

    final safeIndex =
        _currentIndex >= photos.length ? photos.length - 1 : _currentIndex;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: photos.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final photoUrl = photos[index];
                return GestureDetector(
                  onTap: () => _openViewer(context, photos, index),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        photoUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: AppColors.surfaceVariant,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _markUrlAsFailed(photoUrl);
                          });
                          return _photoPlaceholder(height: 220);
                        },
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0xAA000000)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // Ícono de expansión
                      const Positioned(
                        top: 12,
                        right: 12,
                        child: _ExpandIcon(),
                      ),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  widget.adoption.typeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (photos.length > 1)
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    photos.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: index == safeIndex ? 18 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: index == safeIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpandIcon extends StatelessWidget {
  const _ExpandIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
      child:
          const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
    );
  }
}

class _PhotoViewerModal extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const _PhotoViewerModal({required this.photos, required this.initialIndex});

  @override
  State<_PhotoViewerModal> createState() => _PhotoViewerModalState();
}

class _PhotoViewerModalState extends State<_PhotoViewerModal> {
  late final PageController _controller;
  late int _current;

  int get _safeInitialIndex {
    if (widget.photos.isEmpty) return 0;
    return widget.initialIndex.clamp(0, widget.photos.length - 1);
  }

  @override
  void initState() {
    super.initState();
    _current = _safeInitialIndex;
    _controller = PageController(initialPage: _safeInitialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      widget.photos[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white38,
                        size: 64,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Close button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
            // Dots indicator
            if (widget.photos.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.photos.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: i == _current ? 18 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _current
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PublisherRow extends StatelessWidget {
  final AdoptionModel adoption;

  const _PublisherRow({required this.adoption});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.surfaceVariant,
          backgroundImage: _isValidUrl(adoption.publisherPhoto ?? '')
              ? NetworkImage(adoption.publisherPhoto!)
              : null,
          child: !_isValidUrl(adoption.publisherPhoto ?? '')
              ? const Icon(Icons.person_outline, color: AppColors.textSecondary)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                adoption.publisherName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Publicado recientemente',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.success,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF3E0),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyAdoptions extends StatelessWidget {
  const _EmptyAdoptions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(
                Icons.pets,
                size: 42,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No hay mascotas en adopcion',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando aparezcan nuevas publicaciones, vas a verlas aca con sus fotos y datos principales.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdoptionError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AdoptionError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 14),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Si habia una imagen rota, ahora la pantalla mantiene el layout y sigue mostrando el resto.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersSheet extends StatefulWidget {
  final Function(AdoptionFilters) onApply;
  final AdoptionFilters current;

  const _FiltersSheet({required this.onApply, required this.current});

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late AdoptionFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    setState(() => _filters = const AdoptionFilters()),
                child: const Text('Restablecer'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Distancia maxima',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Slider(
            value: _filters.maxDistanceKm.toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            label: '${_filters.maxDistanceKm} km',
            activeColor: AppColors.primary,
            onChanged: (v) => setState(
              () => _filters = _filters.copyWith(maxDistanceKm: v.round()),
            ),
          ),
          const SizedBox(height: 12),
          Text('Edad', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Cachorro', 'Joven', 'Adulto', 'Senior'].map((age) {
              final ageKey = age.toLowerCase();
              return FilterChip(
                label: Text(age),
                selected: _filters.age == ageKey,
                onSelected: (selected) => setState(
                  () => _filters = _filters.copyWith(
                    age: selected ? ageKey : null,
                    clearAge: !selected,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text('Tamano', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ('Pequeno', 'small'),
              ('Mediano', 'medium'),
              ('Grande', 'large'),
            ].map((entry) {
              return FilterChip(
                label: Text(entry.$1),
                selected: _filters.size == entry.$2,
                onSelected: (selected) => setState(
                  () => _filters = _filters.copyWith(
                    size: selected ? entry.$2 : null,
                    clearSize: !selected,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_filters);
                Navigator.pop(context);
              },
              child: const Text('Aplicar filtros'),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isValidUrl(String url) =>
    url.startsWith('http://') || url.startsWith('https://');

String _sizeLabel(String size) {
  switch (size) {
    case 'small':
      return 'Pequeno';
    case 'large':
      return 'Grande';
    default:
      return 'Mediano';
  }
}

Widget _photoPlaceholder({double height = 180}) => Container(
      height: height,
      color: AppColors.surfaceVariant,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pets, size: 42, color: AppColors.textHint),
          SizedBox(height: 8),
          Text(
            'Foto no disponible',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
