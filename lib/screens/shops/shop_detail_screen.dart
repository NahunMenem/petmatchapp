import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_snack_bar.dart';
import '../../models/shop_model.dart';

class ShopDetailScreen extends StatefulWidget {
  final ShopModel shop;

  const ShopDetailScreen({super.key, required this.shop});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  BitmapDescriptor? _shopMarker;
  bool _markerLoaded = false;

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

  static Color _colorForTipo(String tipo) {
    switch (tipo) {
      case 'petshop':
        return const Color(0xFFFF6B00);
      case 'veterinaria':
        return const Color(0xFF3B82F6);
      case 'peluqueria':
        return const Color(0xFF8B5CF6);
      case 'paseador':
        return const Color(0xFF10B981);
      case 'guarderia':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFFF6B00);
    }
  }

  @override
  void initState() {
    super.initState();
    _buildMarker();
  }

  Future<void> _buildMarker() async {
    final color = _colorForTipo(widget.shop.tipo);
    final icon = await _buildShopMarker(widget.shop.nombre, color);
    if (mounted) {
      setState(() {
        _shopMarker = icon;
        _markerLoaded = true;
      });
    }
  }

  Future<BitmapDescriptor> _buildShopMarker(String label, Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(132, 108);
    final center = Offset(size.width / 2, 32);
    final paint = Paint()..isAntiAlias = true;

    paint.color = color.withValues(alpha: 0.28);
    canvas.drawCircle(center.translate(0, 6), 28, paint);

    paint.color = color;
    canvas.drawCircle(center, 24, paint);

    paint.color = Colors.white;
    final iconRect =
        Rect.fromCenter(center: center.translate(0, 2), width: 18, height: 14);
    canvas.drawRRect(
        RRect.fromRectAndRadius(iconRect, const Radius.circular(4)), paint);
    final handlePath = Path()
      ..moveTo(center.dx - 7, center.dy - 7)
      ..arcTo(
        Rect.fromCenter(
            center: center.translate(0, -9), width: 14, height: 8),
        3.14,
        3.14,
        false,
      );
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.1;
    canvas.drawPath(handlePath, paint);
    paint.style = PaintingStyle.fill;

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
    paint.color = Colors.black.withValues(alpha: 0.12);
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        AppSnackBar.error(context, message: 'No se pudo abrir el enlace.');
      }
    }
  }

  void _openDirections() {
    _launchUrl(
        'https://maps.google.com/?q=${widget.shop.lat},${widget.shop.lng}');
  }

  void _openWhatsApp() {
    final url = widget.shop.whatsappUrl;
    if (url == null) return;
    _launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final tipoColor = _colorForTipo(shop.tipo);

    final markers = _markerLoaded && _shopMarker != null
        ? <Marker>{
            Marker(
              markerId: MarkerId('shop-detail-${shop.id}'),
              position: LatLng(shop.lat, shop.lng),
              icon: _shopMarker!,
              anchor: const Offset(0.5, 0.95),
            ),
          }
        : <Marker>{};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Main scrollable content
          Expanded(
            child: CustomScrollView(
              slivers: [
                // AppBar
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  title: Text(
                    shop.nombre,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () {
                        AppSnackBar.info(context, message: 'Compartiendo...');
                      },
                    ),
                  ],
                ),

                // Map
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(shop.lat, shop.lng),
                        zoom: 15,
                      ),
                      markers: markers,
                      scrollGesturesEnabled: false,
                      zoomControlsEnabled: false,
                      zoomGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                      style: _mapStyle,
                    ),
                  ),
                ),

                // Shop info card
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tipo chip + aliado badge
                        Row(
                          children: [
                            _TipoChip(tipo: shop.tipo, color: tipoColor),
                            if (shop.esAliado) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      color: Color(0xFF22C55E),
                                      size: 13,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Aliado PetMatch',
                                      style: TextStyle(
                                        color: Color(0xFF22C55E),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Name
                        Text(
                          shop.nombre,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Address + distance
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                shop.direccion,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (shop.distanceLabel.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                shop.distanceLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Rating
                        if (shop.rating != null) ...[
                          const SizedBox(height: 8),
                          _RatingRow(rating: shop.rating!),
                        ],
                      ],
                    ),
                  ),
                ),

                // Promo banner
                if (shop.promo != null)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_offer_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              shop.promo!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Description
                if (shop.descripcion != null)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sobre el local',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            shop.descripcion!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Info grid
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.place_rounded,
                            label: 'Ubicación',
                            value: shop.direccion,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.notifications_rounded,
                            label: 'Distancia',
                            value: shop.distanceLabel.isNotEmpty
                                ? shop.distanceLabel
                                : 'No disponible',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom spacing for the action bar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom sticky action bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Cómo llegar
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _openDirections,
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: const Text('Cómo llegar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),

                // WhatsApp (only if phone available)
                if (shop.telefonoWhatsapp != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _openWhatsApp,
                        icon: const Icon(Icons.chat_rounded, size: 18),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _TipoChip extends StatelessWidget {
  final String tipo;
  final Color color;

  const _TipoChip({required this.tipo, required this.color});

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: color,
          fontSize: 12,
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
                color: AppColors.gold, size: 16);
          } else if (i == fullStars && hasHalf) {
            return const Icon(Icons.star_half_rounded,
                color: AppColors.gold, size: 16);
          }
          return const Icon(Icons.star_outline_rounded,
              color: AppColors.gold, size: 16);
        }),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
