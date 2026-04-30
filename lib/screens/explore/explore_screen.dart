import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_snack_bar.dart';
import '../../models/pet_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/patitas_provider.dart';
import '../../providers/pets_provider.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/patitas_insufficient_dialog.dart';
import '../../widgets/pet_card.dart';
import '../home/home_screen.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  bool _askedLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentLocation();
    });
  }

  Future<void> _loadCurrentLocation() async {
    if (_askedLocation) return;
    _askedLocation = true;
    if (ref.read(exploreLocationProvider) != null) return;
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
      ref.read(exploreLocationProvider.notifier).state = ExploreLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final updatedUser = await ref.read(authServiceProvider).updateLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          );
      ref.read(authProvider.notifier).updateUser(updatedUser);
    } catch (_) {}
  }

  Future<void> _sendSuperLike() async {
    const cost = 10;
    final wallet = ref.read(patitasWalletProvider).valueOrNull;
    if ((wallet?.patitas ?? 0) < cost) {
      if (!mounted) return;
      showPatitasInsufficientDialog(
        context,
        currentPatitas: wallet?.patitas ?? 0,
        requiredPatitas: cost,
        featureName: 'enviar un Super Like',
      );
      return;
    }

    try {
      await ref.read(exploreProvider.notifier).superLikeCurrentPet();
      ref.invalidate(patitasWalletProvider);
      ref.invalidate(receivedLikesProvider);
      if (!mounted) return;
      AppSnackBar.success(
        context,
        title: 'Super Like',
        message: 'Super Like enviado.',
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        message: 'No se pudo enviar el Super Like.',
        actionLabel: 'Comprar',
        onAction: () => context.push('/paw-points/buy'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(exploreProvider);
    final matchPet = ref.watch(matchPetProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(width: 145, height: 40),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showFilterSheet(context),
          ),
          const NotificationBell(),
        ],
      ),
      body: Stack(
        children: [
          petsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                _ErrorView(onRetry: () => ref.invalidate(exploreProvider)),
            data: (pets) {
              if (pets.isEmpty) {
                return const _EmptyView();
              }
              return _SwipeView(
                pets: pets,
                onSuperLike: _sendSuperLike,
                onDislike: () {
                  ref.read(exploreProvider.notifier).dislikeCurrentPet();
                },
                onLike: () {
                  ref.read(exploreProvider.notifier).likeCurrentPet();
                },
                onSkip: () {
                  ref.read(exploreProvider.notifier).removeCurrent();
                },
              );
            },
          ),

          // Match overlay
          if (matchPet != null)
            _MatchOverlay(
              pet: matchPet,
              onDismiss: () {
                ref.read(matchPetProvider.notifier).state = null;
              },
              onMessage: () {
                ref.read(matchPetProvider.notifier).state = null;
                ref.read(selectedHomeTabProvider.notifier).state = 3;
                ref.invalidate(conversationsProvider);
                context.go('/home');
              },
            ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PremiumFilterSheet(),
    );
  }
}

class _SwipeView extends StatelessWidget {
  final List<PetModel> pets;
  final VoidCallback onSuperLike;
  final VoidCallback onDislike;
  final VoidCallback onLike;
  final VoidCallback onSkip;

  const _SwipeView({
    required this.pets,
    required this.onSuperLike,
    required this.onDislike,
    required this.onLike,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (pets.length > 1)
                  Transform.translate(
                    offset: const Offset(0, -16),
                    child: Transform.scale(
                      scale: 0.94,
                      child: PetCard(
                        key: ValueKey('next-${pets[1].id}'),
                        pet: pets[1],
                      ),
                    ),
                  ),
                Dismissible(
                  key: ValueKey('current-${pets.first.id}'),
                  direction: DismissDirection.horizontal,
                  resizeDuration: null,
                  movementDuration: const Duration(milliseconds: 180),
                  onDismissed: (_) => onSkip(),
                  child: PetCard(
                    pet: pets.first,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 60),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Dislike
              _ActionButton(
                icon: Icons.close_rounded,
                color: AppColors.dislikeRed,
                size: 52,
                onTap: onDislike,
              ),
              // Super like
              _ActionButton(
                icon: Icons.star_rounded,
                color: AppColors.gold,
                size: 44,
                onTap: onSuperLike,
              ),
              // Like
              _ActionButton(
                icon: Icons.favorite_rounded,
                color: AppColors.likeGreen,
                size: 52,
                onTap: onLike,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}

class _MatchOverlay extends StatelessWidget {
  final PetModel pet;
  final VoidCallback onDismiss;
  final VoidCallback onMessage;

  const _MatchOverlay({
    required this.pet,
    required this.onDismiss,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.matchGradient.createShader(bounds),
              child: const Text(
                '¡Es un Match!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A ${pet.name} y a tu mascota les gustaron mutuamente',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Pet photo
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: ClipOval(
                child: pet.mainPhoto.isNotEmpty
                    ? Image.network(pet.mainPhoto, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.pets, size: 60),
                      ),
              ),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Enviar mensaje',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: onDismiss,
                    child: Text(
                      'Seguir explorando',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 80, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'No hay más mascotas cerca',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Volvé más tarde o ampliá los filtros',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: AppColors.error),
          const SizedBox(height: 16),
          const Text('Error al cargar mascotas'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

// ── Paywall de filtros premium ─────────────────────────────────────────────

class _PremiumFilterSheet extends ConsumerWidget {
  const _PremiumFilterSheet();

  static const _features = [
    (Icons.pets_outlined, 'Tipo de mascota', 'Perros, gatos y más'),
    (Icons.biotech_outlined, 'Raza específica', 'Golden, Labrador, Siamés...'),
    (Icons.cake_outlined, 'Rango de edad', 'Cachorro, adulto, mayor'),
    (
      Icons.map_outlined,
      'Radio ampliado',
      'Gratis 10 km, hasta 50 km con Patitas'
    ),
    (
      Icons.health_and_safety_outlined,
      'Solo vacunados / castrados',
      'Filtrá por estado sanitario'
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(advancedFiltersProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) {
          final insufficient = error.toString().contains('402');
          if (insufficient) {
            final wallet = ref.read(patitasWalletProvider).valueOrNull;
            showPatitasInsufficientDialog(
              context,
              currentPatitas: wallet?.patitas ?? 0,
              requiredPatitas: 30,
              featureName: 'activar filtros avanzados',
            );
          } else {
            AppSnackBar.error(
              context,
              message: 'No se pudieron activar los filtros avanzados.',
            );
          }
        },
      );
    });

    final access = ref.watch(advancedFiltersProvider);
    if (access.valueOrNull?.active == true) {
      return const _AdvancedFiltersSheet();
    }

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Badge PREMIUM
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'FUNCIÓN PREMIUM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Filtros Avanzados',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Encontrá exactamente la mascota que buscás',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),

          // Features list
          ...(_features.map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(f.$1, color: AppColors.primary, size: 19),
                  ),
                  SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.$2,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        f.$3,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )),

          // Precio
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pago único · Sin renovación',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '30 Patitas',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.verified_rounded,
                      color: AppColors.success, size: 32),
                ],
              ),
            ),
          ),

          // Botón Mercado Pago
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: access.isLoading
                    ? null
                    : () async {
                        await ref
                            .read(advancedFiltersProvider.notifier)
                            .activate();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.pets_rounded),
                label: const Text(
                  'Activar con 30 Patitas',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ),

          // Link "ahora no"
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Ahora no · Ver sin filtros',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _AdvancedFiltersSheet extends ConsumerStatefulWidget {
  const _AdvancedFiltersSheet();

  @override
  ConsumerState<_AdvancedFiltersSheet> createState() =>
      _AdvancedFiltersSheetState();
}

class _AdvancedFiltersSheetState extends ConsumerState<_AdvancedFiltersSheet> {
  static const List<String> _dogBreeds = [
    'Labrador Retriever',
    'Golden Retriever',
    'Caniche',
    'Bulldog',
    'Bulldog Frances',
    'Beagle',
    'Boxer',
    'Chihuahua',
    'Cocker Spaniel',
    'Dachshund',
    'Doberman',
    'Husky Siberiano',
    'Mestizo',
    'Pastor Aleman',
    'Pug',
    'Rottweiler',
    'Shih Tzu',
    'Yorkshire Terrier',
  ];
  static const List<String> _catBreeds = [
    'Siames',
    'Persa',
    'Maine Coon',
    'Angora',
    'Bengali',
    'British Shorthair',
    'Esfinge',
    'Mestizo',
    'Ragdoll',
    'Siberiano',
  ];

  String? _selectedType;
  String _selectedBreed = '';

  @override
  void initState() {
    super.initState();
    _selectedType = ref.read(exploreTypeProvider);
    _selectedBreed = ref.read(exploreBreedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final radius = ref.watch(exploreMaxDistanceProvider).clamp(10, 50);
    final typeValue = _selectedType;
    final vaccinated = ref.watch(exploreVaccinatedOnlyProvider);
    final sterilized = ref.watch(exploreSterilizedOnlyProvider);

    return Container(
      margin: const EdgeInsets.only(top: 80),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Filtros Avanzados',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String?>(
            value: typeValue,
            decoration: const InputDecoration(
              labelText: 'Tipo de mascota',
              prefixIcon: Icon(Icons.pets_outlined),
            ),
            items: const [
              DropdownMenuItem<String?>(
                value: null,
                child: Text('Todos'),
              ),
              DropdownMenuItem<String?>(
                value: 'dog',
                child: Text('Perros'),
              ),
              DropdownMenuItem<String?>(
                value: 'cat',
                child: Text('Gatos'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedType = value;
                final nextBreedOptions = _breedOptionsFor(value);
                if (_selectedBreed.isNotEmpty &&
                    !nextBreedOptions.contains(_selectedBreed)) {
                  _selectedBreed = '';
                }
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedBreed.isEmpty ? '' : _selectedBreed,
            decoration: const InputDecoration(
              labelText: 'Raza',
              prefixIcon: Icon(Icons.biotech_outlined),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: '',
                child: Text('Todas'),
              ),
              ..._breedOptionsFor(_selectedType).map(
                (breed) => DropdownMenuItem<String>(
                  value: breed,
                  child: Text(breed),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedBreed = value ?? '';
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.map_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Radio de busqueda: $radius km',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          Slider(
            min: 10,
            max: 50,
            divisions: 40,
            value: radius.toDouble().clamp(10, 50),
            onChanged: (value) {
              ref.read(exploreMaxDistanceProvider.notifier).state =
                  value.round();
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Solo vacunados'),
            value: vaccinated,
            onChanged: (value) =>
                ref.read(exploreVaccinatedOnlyProvider.notifier).state = value,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Solo castrados'),
            value: sterilized,
            onChanged: (value) =>
                ref.read(exploreSterilizedOnlyProvider.notifier).state = value,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                ref.read(exploreTypeProvider.notifier).state = _selectedType;
                ref.read(exploreBreedProvider.notifier).state = _selectedBreed;
                ref.invalidate(exploreProvider);
                Navigator.pop(context);
              },
              child: const Text('Aplicar filtros'),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = null;
                _selectedBreed = '';
              });
              ref.read(exploreTypeProvider.notifier).state = null;
              ref.read(exploreBreedProvider.notifier).state = '';
              ref.read(exploreMaxDistanceProvider.notifier).state = 10;
              ref.read(exploreVaccinatedOnlyProvider.notifier).state = false;
              ref.read(exploreSterilizedOnlyProvider.notifier).state = false;
              ref.invalidate(exploreProvider);
              Navigator.pop(context);
            },
            child: const Text('Limpiar filtros'),
          ),
        ],
      ),
    );
  }

  List<String> _breedOptionsFor(String? type) {
    final options = switch (type) {
      'dog' => _dogBreeds,
      'cat' => _catBreeds,
      _ => [..._dogBreeds, ..._catBreeds],
    };
    final unique = options.toSet().toList()..sort();
    return unique;
  }
}
