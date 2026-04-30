import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_snack_bar.dart';
import '../../models/shop_model.dart';
import '../../providers/shops_provider.dart';
import '../../widgets/brand_logo.dart';

class ShopsScreen extends ConsumerStatefulWidget {
  const ShopsScreen({super.key});

  @override
  ConsumerState<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends ConsumerState<ShopsScreen> {
  LatLng? _currentLocation;
  bool _askedLocation = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocation();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _requestLocation() async {
    if (_askedLocation) return;
    _askedLocation = true;

    final stored = ref.read(shopsLocationProvider);
    if (stored != null) {
      setState(() {
        _currentLocation = LatLng(stored.latitude, stored.longitude);
      });
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
      ref.read(shopsLocationProvider.notifier).state = ShopsLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // La pantalla sigue funcionando sin ubicacion precisa.
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(shopsSearchProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(shopsProvider);
    final selectedTipo = ref.watch(shopsTipoFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 20,
        title: const BrandLogo(width: 156, height: 42),
      ),
      body: Column(
        children: [
          // Header + search + filters
          _ShopsHeader(
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            selectedTipo: selectedTipo,
            onTipoSelected: (tipo) {
              ref.read(shopsTipoFilterProvider.notifier).state = tipo;
            },
          ),

          // Map + list
          Expanded(
            child: shopsAsync.when(
              loading: () => Column(
                children: [
                  _ShopsMap(
                    shops: const [],
                    currentLocation: _currentLocation,
                  ),
                  const Expanded(
                    child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              error: (_, __) => Column(
                children: [
                  _ShopsMap(
                    shops: const [],
                    currentLocation: _currentLocation,
                  ),
                  Expanded(
                    child: _ShopsError(
                      onRetry: () => ref.invalidate(shopsProvider),
                    ),
                  ),
                ],
              ),
              data: (shops) {
                final featured = shops.where((s) => s.esDestacado).toList();

                return Column(
                  children: [
                    _ShopsMap(
                      shops: shops,
                      currentLocation: _currentLocation,
                    ),
                    Expanded(
                      child: shops.isEmpty
                          ? const _EmptyShops()
                          : RefreshIndicator(
                              color: AppColors.primary,
                              onRefresh: () async {
                                ref.invalidate(shopsProvider);
                                await ref.read(shopsProvider.future);
                              },
                              child: ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                children: [
                                  // Featured horizontal section
                                  if (featured.isNotEmpty) ...[
                                    const _SectionTitle(
                                        title: '⭐ Destacados cerca tuyo'),
                                    const SizedBox(height: 10),
                                    _FeaturedCarousel(shops: featured),
                                    const SizedBox(height: 20),
                                  ],

                                  // All shops list
                                  if (shops.isNotEmpty)
                                    const _SectionTitle(
                                        title: 'Todos los comercios'),
                                  const SizedBox(height: 10),
                                  ...shops.map(
                                    (s) => GestureDetector(
                                      onTap: () => context.push(
                                        '/shops/${s.id}',
                                        extra: s,
                                      ),
                                      child: _ShopCard(shop: s),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header (search + filters)
// ---------------------------------------------------------------------------

class _ShopsHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String? selectedTipo;
  final ValueChanged<String?> onTipoSelected;

  const _ShopsHeader({
    required this.searchController,
    required this.onSearchChanged,
    required this.selectedTipo,
    required this.onTipoSelected,
  });

  static const _categories = [
    (label: 'Todos', value: null),
    (label: 'Pet Shops', value: 'petshop'),
    (label: 'Veterinarias', value: 'veterinaria'),
    (label: 'Peluquerías', value: 'peluqueria'),
    (label: 'Paseadores', value: 'paseador'),
    (label: 'Guarderías', value: 'guarderia'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Cerca tuyo 🐾',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Pet shops, veterinarias y más en tu zona',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Search bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors.textHint,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textHint,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Category filter chips
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isSelected = selectedTipo == cat.value;
                return GestureDetector(
                  onTap: () => onTipoSelected(cat.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Map
// ---------------------------------------------------------------------------

class _ShopsMap extends StatefulWidget {
  final List<ShopModel> shops;
  final LatLng? currentLocation;

  const _ShopsMap({
    required this.shops,
    this.currentLocation,
  });

  @override
  State<_ShopsMap> createState() => _ShopsMapState();
}

class _ShopsMapState extends State<_ShopsMap> {
  Set<Marker> _markers = const {};

  static const _mapStyle = '''
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

  // Colors by shop type
  static Color _colorForTipo(String tipo) {
    switch (tipo) {
      case 'petshop':
        return const Color(0xFFFF6B35);
      case 'veterinaria':
        return const Color(0xFF4CAF7D);
      case 'peluqueria':
        return const Color(0xFFAB47BC);
      case 'paseador':
        return const Color(0xFF29B6F6);
      case 'guarderia':
        return const Color(0xFFFFB300);
      default:
        return const Color(0xFFFF6B35);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  @override
  void didUpdateWidget(covariant _ShopsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shops != widget.shops ||
        oldWidget.currentLocation != widget.currentLocation) {
      _loadMarkers();
    }
  }

  Future<void> _loadMarkers() async {
    final markers = <Marker>{};

    for (final shop in widget.shops) {
      final color = _colorForTipo(shop.tipo);
      final icon = await _buildShopMarker(shop.nombre, color);
      markers.add(
        Marker(
          markerId: MarkerId('shop-${shop.id}'),
          position: LatLng(shop.lat, shop.lng),
          icon: icon,
          anchor: const Offset(0.5, 0.95),
          infoWindow: InfoWindow(
            title: shop.nombre,
            snippet: shop.tipoLabel,
          ),
        ),
      );
    }

    markers.add(
      Marker(
        markerId: const MarkerId('my-location'),
        position: widget.currentLocation ?? const LatLng(-34.5787, -58.4245),
        icon: await _buildLocationMarker(),
        anchor: const Offset(0.5, 0.5),
        infoWindow: const InfoWindow(title: 'Tu ubicación'),
      ),
    );

    if (mounted) {
      setState(() => _markers = markers);
    }
  }

  Future<BitmapDescriptor> _buildShopMarker(String label, Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(132, 108);
    final center = Offset(size.width / 2, 32);
    final paint = Paint()..isAntiAlias = true;

    // Shadow circle
    paint.color = color.withOpacity(0.28);
    canvas.drawCircle(center.translate(0, 6), 28, paint);

    // Main circle
    paint.color = color;
    canvas.drawCircle(center, 24, paint);

    // Store icon (simple bag shape)
    paint.color = Colors.white;
    final iconRect =
        Rect.fromCenter(center: center.translate(0, 2), width: 18, height: 14);
    canvas.drawRRect(
        RRect.fromRectAndRadius(iconRect, const Radius.circular(4)), paint);
    // Handle
    final handlePath = Path()
      ..moveTo(center.dx - 7, center.dy - 7)
      ..arcTo(
        Rect.fromCenter(center: center.translate(0, -9), width: 14, height: 8),
        3.14,
        3.14,
        false,
      );
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.1;
    canvas.drawPath(handlePath, paint);
    paint.style = PaintingStyle.fill;

    // Label bubble
    final textPainter = TextPainter(
      text: TextSpan(
        text: label.length > 12 ? '${label.substring(0, 12)}…' : label,
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
    final mapHeight = MediaQuery.sizeOf(context).height * 0.32;

    return Container(
      height: mapHeight.clamp(220.0, 300.0),
      width: double.infinity,
      color: const Color(0xFFFFE6D8),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.currentLocation ?? const LatLng(-34.5787, -58.4245),
          zoom: 13,
        ),
        markers: _markers,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: false,
        mapToolbarEnabled: false,
        style: _mapStyle,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section title
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Featured horizontal carousel
// ---------------------------------------------------------------------------

class _FeaturedCarousel extends StatelessWidget {
  final List<ShopModel> shops;

  const _FeaturedCarousel({required this.shops});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: shops.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => context.push('/shops/${shops[i].id}', extra: shops[i]),
          child: _FeaturedCard(shop: shops[i]),
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final ShopModel shop;

  const _FeaturedCard({required this.shop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD6B0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Photo or placeholder
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: SizedBox(
              height: 80,
              width: double.infinity,
              child: shop.fotoUrl != null
                  ? Image.network(
                      shop.fotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder(),
                    )
                  : _photoPlaceholder(),
            ),
          ),

          // Destacado star
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),

          // Info bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.nombre,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _TipoBadge(tipo: shop.tipo),
                      const SizedBox(width: 6),
                      if (shop.distanceLabel.isNotEmpty)
                        Text(
                          shop.distanceLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: const Color(0xFFFFF3E0),
      child: const Center(
        child:
            Icon(Icons.storefront_rounded, color: AppColors.primary, size: 32),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shop card (list)
// ---------------------------------------------------------------------------

class _ShopCard extends StatelessWidget {
  final ShopModel shop;

  const _ShopCard({required this.shop});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        AppSnackBar.error(context, message: 'No se pudo abrir el enlace.');
      }
    }
  }

  void _openDirections(BuildContext context) {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${shop.lat},${shop.lng}';
    _launchUrl(context, url);
  }

  void _openWhatsApp(BuildContext context) {
    final url = shop.whatsappUrl;
    if (url == null) return;
    _launchUrl(context, url);
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
            // Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 76,
                height: 76,
                child: shop.fotoUrl != null
                    ? Image.network(
                        shop.fotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _photoPlaceholder(),
                      )
                    : _photoPlaceholder(),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre + aliado badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shop.nombre,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (shop.esAliado) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'ALIADO',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Tipo + distancia
                  Row(
                    children: [
                      _TipoBadge(tipo: shop.tipo),
                      const SizedBox(width: 8),
                      if (shop.distanceLabel.isNotEmpty) ...[
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Text(
                          shop.distanceLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Dirección
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          shop.direccion,
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

                  // Rating
                  if (shop.rating != null) _RatingRow(rating: shop.rating!),

                  // Promo
                  if (shop.promo != null) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        shop.promo!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.directions_outlined,
                          label: 'Cómo llegar',
                          onTap: () => _openDirections(context),
                          outlined: true,
                        ),
                      ),
                      if (shop.telefonoWhatsapp != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.chat_outlined,
                            label: 'WhatsApp',
                            onTap: () => _openWhatsApp(context),
                            outlined: false,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: const Color(0xFFFFF3E0),
      child: const Center(
        child:
            Icon(Icons.storefront_rounded, color: AppColors.primary, size: 32),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _TipoBadge extends StatelessWidget {
  final String tipo;

  const _TipoBadge({required this.tipo});

  Color get _badgeColor {
    switch (tipo) {
      case 'petshop':
        return AppColors.primary;
      case 'veterinaria':
        return AppColors.success;
      case 'peluqueria':
        return const Color(0xFFAB47BC);
      case 'paseador':
        return AppColors.info;
      case 'guarderia':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  String get _label {
    switch (tipo) {
      case 'petshop':
        return 'Pet Shop';
      case 'veterinaria':
        return 'Veterinaria';
      case 'peluqueria':
        return 'Peluquería';
      case 'paseador':
        return 'Paseador';
      case 'guarderia':
        return 'Guardería';
      default:
        return tipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;

  const _RatingRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.5;

    return Row(
      children: [
        ...List.generate(5, (i) {
          if (i < fullStars) {
            return const Icon(Icons.star_rounded,
                color: AppColors.gold, size: 14);
          } else if (i == fullStars && hasHalf) {
            return const Icon(Icons.star_half_rounded,
                color: AppColors.gold, size: 14);
          }
          return const Icon(Icons.star_outline_rounded,
              color: AppColors.gold, size: 14);
        }),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.outlined,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size(0, 34),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        minimumSize: const Size(0, 34),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / Error states
// ---------------------------------------------------------------------------

class _EmptyShops extends StatelessWidget {
  const _EmptyShops();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined,
                size: 52, color: AppColors.textHint),
            SizedBox(height: 14),
            Text(
              'No encontramos comercios cerca tuyo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Probá cambiando el filtro o la búsqueda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopsError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ShopsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No se pudieron cargar los comercios.',
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
