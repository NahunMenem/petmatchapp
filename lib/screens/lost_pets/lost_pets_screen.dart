import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_snack_bar.dart';
import '../../models/lost_pet_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lost_pets_provider.dart';
import '../../providers/patitas_provider.dart';
import '../../providers/pets_provider.dart';
import '../../services/google_places_service.dart';
import '../../widgets/brand_logo.dart';

class LostPetsScreen extends ConsumerStatefulWidget {
  const LostPetsScreen({super.key});

  @override
  ConsumerState<LostPetsScreen> createState() => _LostPetsScreenState();
}

class _LostPetsScreenState extends ConsumerState<LostPetsScreen> {
  LatLng? _currentLocation;
  bool _askedLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationForLostPets();
    });
  }

  Future<void> _requestLocationForLostPets() async {
    if (_askedLocation) return;
    _askedLocation = true;

    final storedLostLocation = ref.read(lostPetsLocationProvider);
    if (storedLostLocation != null) {
      setState(() {
        _currentLocation = LatLng(
          storedLostLocation.latitude,
          storedLostLocation.longitude,
        );
      });
      return;
    }

    final exploreLocation = ref.read(exploreLocationProvider);
    if (exploreLocation != null) {
      setState(() {
        _currentLocation = LatLng(
          exploreLocation.latitude,
          exploreLocation.longitude,
        );
      });
      ref.read(lostPetsLocationProvider.notifier).state = LostPetsLocation(
        latitude: exploreLocation.latitude,
        longitude: exploreLocation.longitude,
      );
      return;
    }

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
      final location = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _currentLocation = location);
      ref.read(lostPetsLocationProvider.notifier).state = LostPetsLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // La pantalla sigue funcionando con el mapa y listado sin distancia local.
    }
  }

  @override
  Widget build(BuildContext context) {
    final lostPetsAsync = ref.watch(lostPetsProvider);
    final currentUserId = ref.watch(authProvider).valueOrNull?.user?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 20,
        title: const BrandLogo(width: 156, height: 42),
      ),
      body: lostPetsAsync.when(
        loading: () => Column(
          children: [
            _MapSection(
              pets: const [],
              currentLocation: _currentLocation,
              onReport: () => _showReportSheet(context),
            ),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ],
        ),
        error: (_, __) => Column(
          children: [
            _MapSection(
              pets: const [],
              currentLocation: _currentLocation,
              onReport: () => _showReportSheet(context),
            ),
            Expanded(
              child: _LostPetsError(
                onRetry: () => ref.invalidate(lostPetsProvider),
              ),
            ),
          ],
        ),
        data: (lostPets) {
          final nearbyCount = lostPets
              .where((pet) => (pet.distanceKm ?? double.infinity) < 1)
              .length;

          return Column(
            children: [
              _MapSection(
                pets: lostPets,
                currentLocation: _currentLocation,
                nearbyCount: nearbyCount,
                onReport: () => _showReportSheet(context),
              ),
              Expanded(
                child: lostPets.isEmpty
                    ? const _EmptyLostPets()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async {
                          ref.invalidate(lostPetsProvider);
                          await ref.read(lostPetsProvider.future);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          itemCount: lostPets.length,
                          itemBuilder: (_, i) => _LostPetCard(
                            pet: lostPets[i],
                            canMarkFound:
                                lostPets[i].reporterId == currentUserId,
                            onMarkFound: () => _markLostPetFound(lostPets[i]),
                            onEdit: () => _showEditSheet(context, lostPets[i]),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ReportSheet(),
    );
  }

  void _showEditSheet(BuildContext context, LostPetModel pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReportSheet(existingPet: pet),
    );
  }

  Future<void> _markLostPetFound(LostPetModel pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Marcar como encontrado'),
        content: Text(
          'Confirmas que ${pet.name} ya aparecio? La publicacion dejara de mostrarse en Perdidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Lo encontre'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(lostPetsServiceProvider).updateStatus(
            lostPetId: pet.id,
            status: 'found',
          );
      ref.invalidate(lostPetsProvider);
      ref.invalidate(myPetsProvider);
      if (!mounted) return;
      AppSnackBar.success(
        context,
        title: 'Actualizado',
        message: '${pet.name} se marco como encontrado.',
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        message: 'No se pudo actualizar la publicacion.',
      );
    }
  }
}

class _MapPlaceholder extends StatefulWidget {
  final List<LostPetModel> pets;
  final LatLng? currentLocation;

  const _MapPlaceholder({
    required this.pets,
    this.currentLocation,
  });

  @override
  State<_MapPlaceholder> createState() => _MapPlaceholderState();
}

class _MapSection extends StatelessWidget {
  final List<LostPetModel> pets;
  final LatLng? currentLocation;
  final int nearbyCount;
  final VoidCallback onReport;

  const _MapSection({
    required this.pets,
    required this.currentLocation,
    required this.onReport,
    this.nearbyCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            _MapPlaceholder(
              pets: pets,
              currentLocation: currentLocation,
            ),
            Positioned(
              bottom: -24,
              child: _ReportMapButton(onTap: onReport),
            ),
          ],
        ),
        const SizedBox(height: 34),
        if (nearbyCount > 0) _AlertBanner(count: nearbyCount),
      ],
    );
  }
}

class _ReportMapButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ReportMapButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Reportar mascota'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _MapPlaceholderState extends State<_MapPlaceholder> {
  Set<Marker> _markers = const {};

  static const _petmatchMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#FFF0E6"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#6C3B21"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#FFF3EA"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#FFB28F"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#FFE6D8"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#FFD5C0"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#FFD1B6"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#FFB092"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#FF7A33"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#FF8A3D"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#FF5A1F"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#9C210B"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#FF9E68"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#FFD8C6"}]}
]
''';

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  @override
  void didUpdateWidget(covariant _MapPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pets != widget.pets ||
        oldWidget.currentLocation != widget.currentLocation) {
      _loadMarkers();
    }
  }

  Future<void> _loadMarkers() async {
    final colors = [
      const Color(0xFFFF5B1A),
      const Color(0xFFFF2E1F),
      const Color(0xFF4D4B59),
    ];

    final markers = <Marker>{};
    for (var i = 0; i < widget.pets.length; i++) {
      final pet = widget.pets[i];
      if (pet.latitude == null || pet.longitude == null) continue;
      final icon = await _buildPetMarker(
        pet.name,
        colors[i % colors.length],
      );
      markers.add(
        Marker(
          markerId: MarkerId('lost-${pet.id}'),
          position: LatLng(pet.latitude!, pet.longitude!),
          icon: icon,
          anchor: const Offset(0.5, 0.95),
          infoWindow: InfoWindow(title: pet.name, snippet: pet.location),
        ),
      );
    }

    markers.add(
      Marker(
        markerId: const MarkerId('my-zone'),
        position: widget.currentLocation ?? const LatLng(-34.5787, -58.4245),
        icon: await _buildLocationMarker(),
        anchor: const Offset(0.5, 0.5),
        infoWindow: const InfoWindow(title: 'Tu zona'),
      ),
    );

    if (mounted) {
      setState(() => _markers = markers);
    }
  }

  Future<BitmapDescriptor> _buildPetMarker(String label, Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(132, 108);
    final center = Offset(size.width / 2, 32);
    final paint = Paint()..isAntiAlias = true;

    paint.color = color.withOpacity(0.28);
    canvas.drawCircle(center.translate(0, 6), 28, paint);

    paint.color = color;
    canvas.drawCircle(center, 24, paint);

    paint.color = Colors.white;
    canvas.drawCircle(center.translate(-10, -4), 4.2, paint);
    canvas.drawCircle(center.translate(-3, -11), 4.2, paint);
    canvas.drawCircle(center.translate(5, -11), 4.2, paint);
    canvas.drawCircle(center.translate(12, -4), 4.2, paint);
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(1, 7), width: 22, height: 18),
      paint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 18);

    final labelWidth = textPainter.width + 22;
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        (size.width - labelWidth) / 2,
        60,
        labelWidth,
        34,
      ),
      const Radius.circular(10),
    );
    paint.color = Colors.black.withOpacity(0.12);
    canvas.drawRRect(labelRect.shift(const Offset(0, 3)), paint);
    paint.color = Colors.white;
    canvas.drawRRect(labelRect, paint);
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, 67),
    );

    final image = await recorder.endRecording().toImage(
          size.width.toInt(),
          size.height.toInt(),
        );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _buildLocationMarker() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(38, 38);
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..isAntiAlias = true;

    paint.color = AppColors.info.withOpacity(0.24);
    canvas.drawCircle(center, 15, paint);
    paint.color = Colors.white;
    canvas.drawCircle(center, 10, paint);
    paint.color = AppColors.info;
    canvas.drawCircle(center, 6, paint);

    final image = await recorder.endRecording().toImage(
          size.width.toInt(),
          size.height.toInt(),
        );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final mapHeight = MediaQuery.sizeOf(context).height * 0.48;

    return Container(
      height: mapHeight.clamp(330.0, 430.0),
      width: double.infinity,
      color: const Color(0xFFFFE6D8),
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target:
                  widget.currentLocation ?? const LatLng(-34.5787, -58.4245),
              zoom: 12.3,
            ),
            markers: _markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            style: _petmatchMapStyle,
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final int count;

  const _AlertBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFFFFF3E0),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hay $count mascota${count > 1 ? 's' : ''} perdida${count > 1 ? 's' : ''} a menos de 1 km de vos!',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLostPets extends StatelessWidget {
  const _EmptyLostPets();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Todavia no hay mascotas perdidas cerca de tu zona.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LostPetsError extends StatelessWidget {
  final VoidCallback onRetry;

  const _LostPetsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No se pudieron cargar las mascotas perdidas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LostPetCard extends StatelessWidget {
  final LostPetModel pet;
  final bool canMarkFound;
  final VoidCallback onMarkFound;
  final VoidCallback? onEdit;

  const _LostPetCard({
    required this.pet,
    required this.canMarkFound,
    required this.onMarkFound,
    this.onEdit,
  });

  void _openViewer(BuildContext context, List<String> photos, int initialIndex) {
    final safeInitialIndex =
        photos.isEmpty ? 0 : initialIndex.clamp(0, photos.length - 1);
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => _LostPetPhotoViewerModal(
        photos: photos,
        initialIndex: safeInitialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            GestureDetector(
              onTap: pet.photos.isEmpty
                  ? null
                  : () => _openViewer(context, pet.photos, 0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 76,
                      height: 76,
                      child: pet.photoUrl != null
                          ? Image.network(
                              pet.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _petPlaceholder(),
                            )
                          : _petPlaceholder(),
                    ),
                  ),
                  if (pet.photos.isNotEmpty)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fullscreen_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre + badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pet.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (pet.isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'URGENTE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Distancia y tiempo
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${pet.distanceLabel} - ${pet.timeAgo}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Text(
                    pet.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (pet.rewardAmount != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Recompensa \$${pet.rewardAmount}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ContactChip(
                        icon: Icons.phone_outlined,
                        label: 'Llamar',
                        onTap: () => _callOwner(pet.phone),
                      ),
                      _ContactChip(
                        icon: Icons.chat_outlined,
                        label: 'WhatsApp',
                        onTap: () => _openWhatsApp(pet.phone, pet.name),
                      ),
                      if (canMarkFound)
                        _ContactChip(
                          icon: Icons.check_circle_outline_rounded,
                          label: 'Lo encontre',
                          onTap: onMarkFound,
                        ),
                      if (canMarkFound && onEdit != null)
                        _ContactChip(
                          icon: Icons.edit_outlined,
                          label: 'Editar',
                          onTap: onEdit!,
                        ),
                    ],
                  ),
                  /*GestureDetector(
                    onTap: () => _callOwner(pet.phone),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_outlined,
                              size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Contactar dueño',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),*/
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _petPlaceholder() => Container(
        color: AppColors.surfaceVariant,
        child: const Icon(Icons.pets, size: 32, color: AppColors.textHint),
      );

  Future<void> _callOwner(String phone) async {
    final uri = Uri.parse('tel:${_normalizePhone(phone)}');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _openWhatsApp(String phone, String petName) async {
    final message = Uri.encodeComponent(
      'Hola, vi en PawMatch la alerta de $petName.',
    );
    final uri =
        Uri.parse('https://wa.me/${_normalizePhone(phone)}?text=$message');
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }
}

class _LostPetPhotoViewerModal extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const _LostPetPhotoViewerModal({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_LostPetPhotoViewerModal> createState() =>
      _LostPetPhotoViewerModalState();
}

class _LostPetPhotoViewerModalState extends State<_LostPetPhotoViewerModal> {
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
              onPageChanged: (index) => setState(() => _current = index),
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
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
            if (widget.photos.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.photos.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: index == _current ? 18 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: index == _current
                            ? Colors.white
                            : Colors.white.withOpacity(0.45),
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

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportSheet extends ConsumerStatefulWidget {
  final LostPetModel? existingPet;

  const _ReportSheet({this.existingPet});

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _PhoneCountry {
  final String name;
  final String dialCode;

  const _PhoneCountry(this.name, this.dialCode);
}

const _phoneCountries = [
  _PhoneCountry('Argentina', '+54'),
  _PhoneCountry('Uruguay', '+598'),
  _PhoneCountry('Chile', '+56'),
  _PhoneCountry('Paraguay', '+595'),
  _PhoneCountry('Brasil', '+55'),
  _PhoneCountry('Bolivia', '+591'),
  _PhoneCountry('Peru', '+51'),
  _PhoneCountry('Colombia', '+57'),
  _PhoneCountry('Mexico', '+52'),
  _PhoneCountry('Estados Unidos', '+1'),
];

class _AlertReach {
  final String title;
  final String subtitle;
  final int cost;
  final int radiusKm;

  const _AlertReach({
    required this.title,
    required this.subtitle,
    required this.cost,
    required this.radiusKm,
  });
}

const _alertReach2km = _AlertReach(
  title: 'Notificar a 2 km',
  subtitle: 'Ideal si se perdio cerca de tu zona',
  cost: 50,
  radiusKm: 2,
);

const _alertReach5km = _AlertReach(
  title: 'Notificar a 5 km',
  subtitle: 'Mas alcance para casos urgentes',
  cost: 100,
  radiusKm: 5,
);

const _alertReach10km = _AlertReach(
  title: 'Notificar a 10 km',
  subtitle: 'Maximo alcance para casos muy urgentes',
  cost: 200,
  radiusKm: 10,
);

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _rewardCtrl = TextEditingController();
  final _placesService = GooglePlacesService();
  Timer? _locationDebounce;
  List<PlaceSuggestion> _locationSuggestions = const [];
  final List<File> _photos = [];
  String _type = 'dog';
  String? _selectedPetId;
  List<String> _selectedPetPhotos = const [];
  _PhoneCountry _phoneCountry = _phoneCountries.first;
  bool _hasReward = false;
  bool _loadingLocation = false;
  bool _loadingSuggestions = false;
  bool _publishing = false;
  _AlertReach? _selectedReach;
  double? _latitude;
  double? _longitude;

  bool get _isEditing => widget.existingPet != null;

  @override
  void initState() {
    super.initState();
    _prefillFromExistingPet();
  }

  @override
  void dispose() {
    _locationDebounce?.cancel();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _rewardCtrl.dispose();
    super.dispose();
  }

  void _prefillFromExistingPet() {
    final existingPet = widget.existingPet;
    if (existingPet == null) return;

    _nameCtrl.text = existingPet.name;
    _descCtrl.text = existingPet.description;
    _locationCtrl.text = existingPet.location;
    _rewardCtrl.text = existingPet.rewardAmount?.toString() ?? '';
    _type = existingPet.type;
    _selectedPetId = existingPet.petId;
    _selectedPetPhotos = List<String>.from(existingPet.photos);
    _hasReward = existingPet.rewardAmount != null;
    _latitude = existingPet.latitude;
    _longitude = existingPet.longitude;
    _selectedReach = existingPet.alertRadiusKm == _alertReach2km.radiusKm
        ? _alertReach2km
        : existingPet.alertRadiusKm == _alertReach5km.radiusKm
            ? _alertReach5km
            : null;

    final phone = existingPet.phone.trim();
    final matchingCountry = _phoneCountries
        .where((country) => phone.startsWith(country.dialCode))
        .toList()
      ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
    if (matchingCountry.isNotEmpty) {
      _phoneCountry = matchingCountry.first;
      _phoneCtrl.text = phone.substring(_phoneCountry.dialCode.length);
    } else {
      _phoneCtrl.text = phone;
    }
  }

  Future<void> _pickPhotos() async {
    final totalPhotos = _photos.length + _selectedPetPhotos.length;
    if (totalPhotos >= 6) return;

    final picked = await ImagePicker().pickMultiImage(limit: 6 - totalPhotos);
    if (picked.isNotEmpty && mounted) {
      setState(() {
        _photos.addAll(picked.map((image) => File(image.path)));
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationSnack(
          'Activa la ubicacion del dispositivo',
          actionLabel: 'Abrir',
          onAction: Geolocator.openLocationSettings,
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showLocationSnack(
          'Permiso de ubicacion denegado',
          actionLabel:
              permission == LocationPermission.deniedForever ? 'Ajustes' : null,
          onAction: permission == LocationPermission.deniedForever
              ? Geolocator.openAppSettings
              : null,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationCtrl.text =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        _locationSuggestions = const [];
      });

      final place = await _placesService.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (place != null && mounted) {
        setState(() {
          _locationCtrl.text = place.formattedAddress;
          _latitude = place.latitude;
          _longitude = place.longitude;
        });
      }
    } catch (_) {
      _showLocationSnack('No pudimos obtener tu ubicacion');
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _onLocationChanged(String value) {
    _latitude = null;
    _longitude = null;
    _locationDebounce?.cancel();

    if (value.trim().length < 3) {
      setState(() {
        _locationSuggestions = const [];
        _loadingSuggestions = false;
      });
      return;
    }

    setState(() => _loadingSuggestions = true);
    _locationDebounce = Timer(const Duration(milliseconds: 450), () async {
      final suggestions = await _placesService.autocomplete(value);
      if (!mounted || value != _locationCtrl.text) return;
      setState(() {
        _locationSuggestions = suggestions;
        _loadingSuggestions = false;
      });
      if (suggestions.isEmpty && _placesService.lastError != null) {
        _showLocationSnack(
          'No se pudo consultar Google Places. Revisa la API key.',
        );
      }
    });
  }

  Future<void> _selectLocationSuggestion(PlaceSuggestion suggestion) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _locationCtrl.text = suggestion.description;
      _locationSuggestions = const [];
      _loadingSuggestions = true;
    });

    final details = await _placesService.getDetails(suggestion.placeId);
    if (!mounted) return;

    setState(() {
      _loadingSuggestions = false;
      if (details != null) {
        _locationCtrl.text = details.formattedAddress.isNotEmpty
            ? details.formattedAddress
            : suggestion.description;
        _latitude = details.latitude;
        _longitude = details.longitude;
      }
    });
  }

  Future<void> _submitAlert() async {
    if (_publishing) return;

    final name = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final phoneNumber = _phoneCtrl.text.trim();
    final phone = '${_phoneCountry.dialCode}$phoneNumber';
    final location = _locationCtrl.text.trim();
    if (name.isEmpty ||
        description.isEmpty ||
        phoneNumber.isEmpty ||
        location.isEmpty) {
      _showLocationSnack('Completa nombre, descripcion, ubicacion y telefono');
      return;
    }
    if (_selectedPetPhotos.isEmpty && _photos.isEmpty) {
      _showLocationSnack('Agrega al menos una foto de la mascota');
      return;
    }

    final selectedReach = _selectedReach;
    final wallet = ref.read(patitasWalletProvider).valueOrNull;
    if (selectedReach != null && (wallet?.patitas ?? 0) < selectedReach.cost) {
      _showLocationSnack('No tenes Patitas suficientes para ese alcance');
      return;
    }

    setState(() => _publishing = true);
    try {
      final rewardAmount =
          _hasReward ? int.tryParse(_rewardCtrl.text.trim()) : null;
      if ((_latitude == null || _longitude == null) && location.isNotEmpty) {
        final details = await _placesService.forwardGeocode(location);
        if (details != null) {
          _latitude = details.latitude;
          _longitude = details.longitude;
        }
      }

      final photoUrls = <String>[..._selectedPetPhotos];
      final petService = ref.read(petServiceProvider);
      for (final photo in _photos) {
        photoUrls.add(await petService.uploadPhoto(photo.path));
      }

      if (_isEditing) {
        await ref.read(lostPetsServiceProvider).updateLostPet(
              lostPetId: widget.existingPet!.id,
              petId: _selectedPetId,
              name: name,
              type: _type,
              description: description,
              phone: phone,
              photos: photoUrls,
              location: location,
              latitude: _latitude,
              longitude: _longitude,
              rewardAmount: rewardAmount,
              alertRadiusKm:
                  widget.existingPet?.alertRadiusKm ?? selectedReach?.radiusKm,
            );
      } else {
        await ref.read(lostPetsServiceProvider).createLostPet(
              petId: _selectedPetId,
              name: name,
              type: _type,
              description: description,
              phone: phone,
              photos: photoUrls,
              location: location,
              latitude: _latitude,
              longitude: _longitude,
              rewardAmount: rewardAmount,
              alertRadiusKm: selectedReach?.radiusKm,
            );
      }

      ref.invalidate(lostPetsProvider);
      if (!_isEditing && selectedReach != null) {
        await ref.read(patitasWalletProvider.notifier).refresh();
      }

      if (!mounted) return;
      Navigator.pop(context);
      AppSnackBar.success(
        context,
        title: _isEditing ? 'Alerta actualizada' : 'Alerta publicada',
        message: _isEditing
            ? 'Alerta actualizada.'
            : selectedReach == null
                ? 'Alerta publicada.'
                : 'Alerta publicada y ${selectedReach.title.toLowerCase()} activada.',
      );
    } catch (_) {
      if (!mounted) return;
      _showLocationSnack('No se pudo publicar la alerta. Reintenta.');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _openInGoogleMaps() async {
    final query = _latitude != null && _longitude != null
        ? '$_latitude,$_longitude'
        : _locationCtrl.text.trim();
    if (query.isEmpty) {
      _showLocationSnack('Escribi una ubicacion o usa tu ubicacion actual');
      return;
    }

    final uri = Uri.https(
      'www.google.com',
      '/maps/search/',
      {'api': '1', 'query': query},
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) _showLocationSnack('No se pudo abrir Google Maps');
  }

  void _showLocationSnack(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    AppSnackBar.error(
      context,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final myPetsAsync = ref.watch(myPetsProvider);
    final walletAsync = ref.watch(patitasWalletProvider);
    final availablePatitas = walletAsync.valueOrNull?.patitas ?? 0;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Row(
              children: [
                Text(_isEditing ? 'Editar alerta' : 'Reportar mascota perdida',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            myPetsAsync.maybeWhen(
              data: (pets) => pets.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Elegir una de mis mascotas',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 84,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: pets.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (_, index) {
                              final pet = pets[index];
                              return _MyPetChoice(
                                petName: pet.name,
                                photoUrl: pet.mainPhoto,
                                selected: _selectedPetId == pet.id,
                                onTap: () {
                                  setState(() {
                                    _selectedPetId = pet.id;
                                    _selectedPetPhotos = pet.photos;
                                    _nameCtrl.text = pet.name;
                                    _type = pet.type.name;
                                    _descCtrl.text = [
                                      pet.description,
                                      pet.breed,
                                      pet.age,
                                    ]
                                        .whereType<String>()
                                        .where((value) => value.isNotEmpty)
                                        .join(' - ');
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
            Text(
              'Fotos de la mascota',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            _LostPetPhotoGrid(
              existingPhotos: _selectedPetPhotos,
              photos: _photos,
              onAdd: _pickPhotos,
              onRemoveExisting: (index) => setState(() {
                _selectedPetPhotos = [
                  ..._selectedPetPhotos.take(index),
                  ..._selectedPetPhotos.skip(index + 1),
                ];
              }),
              onRemovePhoto: (index) => setState(() => _photos.removeAt(index)),
            ),
            const SizedBox(height: 16),
            // Tipo
            Row(
              children: [
                _TypeBtn(
                  label: 'Perro',
                  selected: _type == 'dog',
                  onTap: () => setState(() {
                    _type = 'dog';
                    _selectedPetId = null;
                    _selectedPetPhotos = const [];
                  }),
                ),
                const SizedBox(width: 10),
                _TypeBtn(
                  label: 'Gato',
                  selected: _type == 'cat',
                  onTap: () => setState(() {
                    _type = 'cat';
                    _selectedPetId = null;
                    _selectedPetPhotos = const [];
                  }),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la mascota',
                prefixIcon: Icon(Icons.pets_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripcion (color, collar, senas particulares...)',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationCtrl,
              onChanged: _onLocationChanged,
              decoration: InputDecoration(
                labelText: 'Ubicacion donde se perdio',
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: IconButton(
                  tooltip: 'Abrir en Google Maps',
                  icon: const Icon(Icons.map_outlined),
                  onPressed: _openInGoogleMaps,
                ),
              ),
            ),
            if (_loadingSuggestions)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (_locationSuggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 190),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _locationSuggestions.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (_, index) {
                    final suggestion = _locationSuggestions[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.place_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        suggestion.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => _selectLocationSuggestion(suggestion),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loadingLocation ? null : _useCurrentLocation,
                    icon: _loadingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded, size: 18),
                    label: const Text('Mi ubicacion actual'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 52,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: _openInGoogleMaps,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Icon(Icons.map_outlined, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 112,
                  child: DropdownButtonFormField<_PhoneCountry>(
                    value: _phoneCountry,
                    decoration: const InputDecoration(
                      labelText: 'Pais',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    isExpanded: true,
                    selectedItemBuilder: (context) => _phoneCountries
                        .map(
                          (country) => Text(
                            country.dialCode,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                        .toList(),
                    items: _phoneCountries
                        .map(
                          (country) => DropdownMenuItem(
                            value: country,
                            child: Text(
                              '${country.dialCode} ${country.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _phoneCountry = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefono de contacto',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SwitchListTile(
                value: _hasReward,
                onChanged: (value) => setState(() => _hasReward = value),
                activeColor: AppColors.primary,
                title: const Text('Agregar recompensa'),
                subtitle: const Text('Opcional para incentivar la ayuda'),
                secondary: const Icon(Icons.volunteer_activism_outlined),
              ),
            ),
            if (_hasReward) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _rewardCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto de recompensa',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_isEditing && widget.existingPet?.alertRadiusKm != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Alcance de alerta actual: ${widget.existingPet!.alertRadiusKm} km',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              _AlertReachSection(
                availablePatitas: availablePatitas,
                selectedReach: _selectedReach,
                onSelected: (reach) {
                  setState(() {
                    _selectedReach = _selectedReach == reach ? null : reach;
                  });
                },
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _publishing ? null : _submitAlert,
                icon: _publishing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _publishing
                      ? (_isEditing ? 'Guardando...' : 'Publicando...')
                      : (_isEditing ? 'Guardar cambios' : 'Publicar alerta'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyPetChoice extends StatelessWidget {
  final String petName;
  final String photoUrl;
  final bool selected;
  final VoidCallback onTap;

  const _MyPetChoice({
    required this.petName,
    required this.photoUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 42,
                height: 42,
                child: photoUrl.isNotEmpty
                    ? Image.network(photoUrl, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.surface,
                        child: const Icon(
                          Icons.pets,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              petName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LostPetPhotoGrid extends StatelessWidget {
  final List<String> existingPhotos;
  final List<File> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemovePhoto;

  const _LostPetPhotoGrid({
    required this.existingPhotos,
    required this.photos,
    required this.onAdd,
    required this.onRemoveExisting,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final total = existingPhotos.length + photos.length;
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: total < 6 ? total + 1 : total,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          if (index < existingPhotos.length) {
            return _PhotoThumb(
              image: Image.network(existingPhotos[index], fit: BoxFit.cover),
              onRemove: () => onRemoveExisting(index),
            );
          }

          final fileIndex = index - existingPhotos.length;
          if (fileIndex < photos.length) {
            return _PhotoThumb(
              image: Image.file(photos[fileIndex], fit: BoxFit.cover),
              onRemove: () => onRemovePhoto(fileIndex),
            );
          }

          return GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                  SizedBox(height: 6),
                  Text(
                    'Agregar',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final Image image;
  final VoidCallback onRemove;

  const _PhotoThumb({
    required this.image,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 88,
            height: 88,
            child: image,
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _AlertReachSection extends StatelessWidget {
  final int availablePatitas;
  final _AlertReach? selectedReach;
  final ValueChanged<_AlertReach> onSelected;

  const _AlertReachSection({
    required this.availablePatitas,
    required this.selectedReach,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final needsPatitas = availablePatitas < _alertReach2km.cost;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ampliar notificacion',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              InkWell(
                onTap: () => context.push('/paw-points'),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$availablePatitas Patitas',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Opcional. Sin Patitas la alerta se publica igual, pero no se envian notificaciones por cercania.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _showAlertReachInfo(context),
              icon: const Icon(Icons.info_outline_rounded, size: 17),
              label: const Text('Mas informacion'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (needsPatitas) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/paw-points'),
                icon: const Icon(Icons.pets_rounded, size: 18),
                label: const Text('Recargar Patitas'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary.withOpacity(0.32),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _AlertReachOption(
            reach: _alertReach2km,
            selected: selectedReach == _alertReach2km,
            disabled: availablePatitas < _alertReach2km.cost,
            onTap: () => onSelected(_alertReach2km),
          ),
          const SizedBox(height: 8),
          _AlertReachOption(
            reach: _alertReach5km,
            selected: selectedReach == _alertReach5km,
            disabled: availablePatitas < _alertReach5km.cost,
            onTap: () => onSelected(_alertReach5km),
          ),
          const SizedBox(height: 8),
          _AlertReachOption(
            reach: _alertReach10km,
            selected: selectedReach == _alertReach10km,
            disabled: availablePatitas < _alertReach10km.cost,
            onTap: () => onSelected(_alertReach10km),
          ),
        ],
      ),
    );
  }
}

void _showAlertReachInfo(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.campaign_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Como funciona la notificacion',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _InfoRow(
            title: 'Notificar a 2 km',
            text:
                'PawMatch avisa a usuarios de la comunidad que esten cerca del lugar donde se perdio, dentro de un radio de hasta 2 km.',
          ),
          const SizedBox(height: 12),
          const _InfoRow(
            title: 'Notificar a 5 km',
            text:
                'Amplia el alcance para que mas personas cercanas vean la alerta y puedan ayudarte dentro de un radio de hasta 5 km.',
          ),
          const SizedBox(height: 12),
          const _InfoRow(
            title: 'Notificar a 10 km',
            text:
                'Activa el alcance maximo para avisar a muchas mas personas de la comunidad dentro de un radio de hasta 10 km.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Si no activas una opcion con Patitas, la alerta se publica normalmente en Perdidos pero no se envian notificaciones a usuarios cercanos.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Las Patitas se descuentan solo cuando publicas la alerta con alcance de 2 km, 5 km o 10 km.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String text;

  const _InfoRow({
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlertReachOption extends StatelessWidget {
  final _AlertReach reach;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _AlertReachOption({
    required this.reach,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.textPrimary;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: disabled
                  ? AppColors.textHint
                  : selected
                      ? Colors.white
                      : AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reach.title,
                    style: TextStyle(
                      color: disabled ? AppColors.textHint : foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    disabled ? 'Saldo insuficiente' : reach.subtitle,
                    style: TextStyle(
                      color: disabled
                          ? AppColors.textHint
                          : selected
                              ? Colors.white.withOpacity(0.78)
                              : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${reach.cost} Patitas',
              style: TextStyle(
                color: disabled
                    ? AppColors.textHint
                    : selected
                        ? Colors.white
                        : AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
