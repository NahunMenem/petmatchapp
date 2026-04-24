class ShopModel {
  final String id;
  final String nombre;
  final String tipo; // petshop, veterinaria, peluqueria, paseador, guarderia
  final String? descripcion;
  final String direccion;
  final double lat;
  final double lng;
  final String? telefonoWhatsapp;
  final double? rating;
  final String? promo;
  final bool esDestacado;
  final bool esAliado;
  final String? fotoUrl;
  final double? distanceKm;

  const ShopModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.descripcion,
    required this.direccion,
    required this.lat,
    required this.lng,
    this.telefonoWhatsapp,
    this.rating,
    this.promo,
    required this.esDestacado,
    required this.esAliado,
    this.fotoUrl,
    this.distanceKm,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      tipo: json['tipo'] as String? ?? 'petshop',
      descripcion: json['descripcion'] as String?,
      direccion: json['direccion'] as String? ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      telefonoWhatsapp: json['telefono_whatsapp'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      promo: json['promo'] as String?,
      esDestacado: json['es_destacado'] as bool? ?? false,
      esAliado: json['es_aliado'] as bool? ?? false,
      fotoUrl: json['foto_url'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }

  String get tipoLabel {
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

  String get distanceLabel {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) return '${(distanceKm! * 1000).round()} m';
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  String? get whatsappUrl {
    if (telefonoWhatsapp == null) return null;
    final msg = Uri.encodeComponent('Hola, te encontré desde PawMatch 🐾');
    return 'https://wa.me/$telefonoWhatsapp?text=$msg';
  }
}
