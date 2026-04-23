import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/adoption_provider.dart';
import '../../providers/pets_provider.dart';
import '../../services/google_places_service.dart';
import '../../widgets/primary_button.dart';

class PublishAdoptionScreen extends ConsumerStatefulWidget {
  const PublishAdoptionScreen({super.key});

  @override
  ConsumerState<PublishAdoptionScreen> createState() =>
      _PublishAdoptionScreenState();
}

class _PublishAdoptionScreenState extends ConsumerState<PublishAdoptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _placesService = GooglePlacesService();

  String _type = 'dog';
  String? _age;
  String _size = 'medium';
  String _healthStatus = 'Vacunado';
  _PhoneCountry _phoneCountry = _phoneCountries.first;
  List<File> _photos = [];
  bool _loading = false;
  bool _loadingLocation = false;
  bool _loadingSuggestions = false;
  Timer? _locationDebounce;
  List<PlaceSuggestion> _locationSuggestions = const [];
  double? _latitude;
  double? _longitude;

  final List<String> _ages = [
    '2 meses',
    '3 meses',
    '4 meses',
    '6 meses',
    '8 meses',
    '1 año',
    '2 años',
    '3 años',
    '4 años',
    '5 años',
    '6+ años',
  ];

  @override
  void dispose() {
    _locationDebounce?.cancel();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    if (_photos.length >= 6) return;
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(limit: 6 - _photos.length);
    if (picked.isNotEmpty) {
      setState(() => _photos.addAll(picked.map((x) => File(x.path))));
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Activa la ubicacion del dispositivo');
        await Geolocator.openLocationSettings();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack('Permiso de ubicacion denegado');
        if (permission == LocationPermission.deniedForever) {
          await Geolocator.openAppSettings();
        }
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
      _showSnack('No pudimos obtener tu ubicacion');
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_age == null) {
      _showSnack('Seleccioná la edad');
      return;
    }
    if (_photos.isEmpty) {
      _showSnack('Agregá al menos una foto');
      return;
    }

    final phoneNumber = _phoneCtrl.text.trim();
    if (phoneNumber.isEmpty) {
      _showSnack('Agrega un telefono de contacto');
      return;
    }

    setState(() => _loading = true);

    try {
      final locationText = _locationCtrl.text.trim();
      if ((_latitude == null || _longitude == null) &&
          locationText.isNotEmpty) {
        final details = await _placesService.forwardGeocode(locationText);
        if (details != null) {
          _latitude = details.latitude;
          _longitude = details.longitude;
        }
      }

      final service = ref.read(adoptionServiceProvider);

      // Subir fotos a Cloudinary y obtener URLs reales
      final petService = ref.read(petServiceProvider);
      final photoUrls = <String>[];
      for (final photo in _photos) {
        final url = await petService.uploadPhoto(photo.path);
        photoUrls.add(url);
      }

      await service.publishAdoption({
        'name': _nameCtrl.text.trim(),
        'type': _type,
        'age': _age,
        'size': _size,
        'health_status': _healthStatus,
        'description': _descCtrl.text.trim(),
        'photos': photoUrls,
        'location': locationText,
        'latitude': _latitude,
        'longitude': _longitude,
        'phone': '${_phoneCountry.dialCode}$phoneNumber',
      });

      if (mounted) {
        ref.invalidate(adoptionsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Publicación creada exitosamente!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) _showSnack(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      final detail = data is Map ? data['detail'] : null;
      if (detail is String && detail.isNotEmpty) return detail;
      if (detail is List && detail.isNotEmpty) {
        return 'Revisá los datos de la publicación';
      }
      if (error.response?.statusCode == 413) {
        return 'La imagen es demasiado grande';
      }
      if (error.response?.statusCode == 500) {
        return 'Error del servidor al guardar la publicación';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'La conexión tardó demasiado';
      }
    }
    return 'Error al publicar. Intentá de nuevo.';
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar en adopción')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Photos
            Text('Fotos (máximo 6)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _PhotoGridSimple(
              photos: _photos,
              onAdd: _pickPhotos,
              onRemove: (i) => setState(() => _photos.removeAt(i)),
            ),
            const SizedBox(height: 20),

            // Type
            Text('Tipo de mascota',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                _TypeButton(
                  label: '🐶 Perro',
                  selected: _type == 'dog',
                  onTap: () => setState(() => _type = 'dog'),
                ),
                const SizedBox(width: 12),
                _TypeButton(
                  label: '🐱 Gato',
                  selected: _type == 'cat',
                  onTap: () => setState(() => _type = 'cat'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration:
                  const InputDecoration(hintText: 'Nombre de la mascota'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'El nombre es requerido' : null,
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _age,
              hint: const Text('Edad'),
              decoration: const InputDecoration(),
              items: _ages
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => _age = v),
            ),
            const SizedBox(height: 14),

            // Size
            Text('Tamaño', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Row(
              children: [
                _SizeButton(
                  label: 'Pequeño',
                  selected: _size == 'small',
                  onTap: () => setState(() => _size = 'small'),
                ),
                const SizedBox(width: 8),
                _SizeButton(
                  label: 'Mediano',
                  selected: _size == 'medium',
                  onTap: () => setState(() => _size = 'medium'),
                ),
                const SizedBox(width: 8),
                _SizeButton(
                  label: 'Grande',
                  selected: _size == 'large',
                  onTap: () => setState(() => _size = 'large'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _healthStatus,
              decoration: const InputDecoration(labelText: 'Estado de salud'),
              items: [
                'Vacunado',
                'Castrado',
                'Vacunado y castrado',
                'Sin vacunas',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _healthStatus = v!),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Historia / Descripción\nContá sobre la mascota, dónde fue rescatada, su personalidad...',
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'La descripción es requerida' : null,
            ),
            const SizedBox(height: 14),

            Text(
              'Tu direccion no se muestra por seguridad. Solo veran la distancia aproximada.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationCtrl,
              onChanged: _onLocationChanged,
              decoration: const InputDecoration(
                hintText: 'Ubicación (ej: Palermo, CABA)',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'La ubicación es requerida' : null,
            ),
            if (_loadingSuggestions)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (_locationSuggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
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
            OutlinedButton.icon(
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
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                SizedBox(
                  width: 112,
                  child: DropdownButtonFormField<_PhoneCountry>(
                    initialValue: _phoneCountry,
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
                  child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefono de contacto',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Requerido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            PrimaryButton(
              label: 'Publicar en adopción',
              onPressed: _loading ? null : _submit,
              isLoading: _loading,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
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

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SizeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SizeButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PhotoGridSimple extends StatelessWidget {
  final List<File> photos;
  final VoidCallback onAdd;
  final Function(int) onRemove;

  const _PhotoGridSimple(
      {required this.photos, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ...photos.asMap().entries.map(
              (e) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(e.value,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemove(e.key),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        if (photos.length < 6)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      color: AppColors.primary, size: 26),
                  const SizedBox(height: 4),
                  Text('Agregar',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
