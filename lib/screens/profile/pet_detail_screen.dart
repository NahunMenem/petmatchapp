import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_snack_bar.dart';
import '../../models/pet_model.dart';
import '../../providers/pets_provider.dart';

class PetDetailScreen extends ConsumerStatefulWidget {
  final PetModel pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _breedCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _descriptionCtrl;
  late PetSex _sex;
  late PetSize _size;
  late bool _isActive;
  late List<String> _photoUrls;
  final List<File> _newPhotos = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.pet.name);
    _breedCtrl = TextEditingController(text: widget.pet.breed);
    _ageCtrl = TextEditingController(text: widget.pet.age);
    _descriptionCtrl =
        TextEditingController(text: widget.pet.description ?? '');
    _sex = widget.pet.sex;
    _size = widget.pet.size;
    _isActive = widget.pet.isActive;
    _photoUrls = [...widget.pet.photos];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _ageCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final remaining = 6 - _photoUrls.length - _newPhotos.length;
    if (remaining <= 0) return;

    final picked = await ImagePicker().pickMultiImage(limit: remaining);
    if (picked.isEmpty) return;

    setState(() {
      _newPhotos.addAll(picked.map((x) => File(x.path)));
    });
  }

  Future<void> _save({bool silent = false}) async {
    if (_nameCtrl.text.trim().isEmpty ||
        _breedCtrl.text.trim().isEmpty ||
        _ageCtrl.text.trim().isEmpty) {
      _showSnack('Completa nombre, raza y edad', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final service = ref.read(petServiceProvider);
      final uploaded = <String>[];
      for (final photo in _newPhotos) {
        uploaded.add(await service.uploadPhoto(photo.path));
      }

      await service.updatePet(widget.pet.id, {
        'name': _nameCtrl.text.trim(),
        'breed': _breedCtrl.text.trim(),
        'age': _ageCtrl.text.trim(),
        'sex': _sex == PetSex.male ? 'male' : 'female',
        'size': _size.name,
        'photos': [..._photoUrls, ...uploaded],
        'description': _descriptionCtrl.text.trim(),
        'is_active': _isActive,
      });

      _photoUrls = [..._photoUrls, ...uploaded];
      _newPhotos.clear();
      ref.invalidate(myPetsProvider);
      ref.invalidate(exploreProvider);

      if (!silent && mounted) {
        _showSnack('Mascota actualizada');
      }
    } catch (_) {
      if (mounted) {
        _showSnack('No se pudo guardar la mascota', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (isError) {
      AppSnackBar.error(context, message: message);
      return;
    }
    AppSnackBar.success(context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final mainPhoto = _photoUrls.isNotEmpty ? _photoUrls.first : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Mi Mascota'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _saving ? null : () => _save(),
              icon: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Editar'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.09),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 248,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (mainPhoto != null)
                  CachedNetworkImage(
                    imageUrl: mainPhoto,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(
                      Icons.pets,
                      color: AppColors.textHint,
                      size: 56,
                    ),
                  ),
                Positioned(
                  left: 18,
                  bottom: 12,
                  child: FilledButton.icon(
                    onPressed: _pickPhotos,
                    icon: const Icon(Icons.photo_camera_outlined, size: 15),
                    label: const Text('Cambiar fotos'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.65),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _PhotoStrip(
            photoUrls: _photoUrls,
            newPhotos: _newPhotos,
            onAdd: _pickPhotos,
            onRemoveUrl: (index) => setState(() => _photoUrls.removeAt(index)),
            onRemoveFile: (index) => setState(() => _newPhotos.removeAt(index)),
          ),
          const SizedBox(height: 10),
          _AvailabilityCard(
            value: _isActive,
            onChanged: (value) {
              setState(() => _isActive = value);
              _save(silent: true);
            },
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Datos de la mascota',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _EditField(label: 'Nombre', controller: _nameCtrl),
                const SizedBox(height: 12),
                _EditField(label: 'Raza', controller: _breedCtrl),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _EditField(label: 'Edad', controller: _ageCtrl),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SelectField<PetSex>(
                        label: 'Sexo',
                        value: _sex,
                        items: const [
                          DropdownMenuItem(
                            value: PetSex.female,
                            child: Text('Hembra'),
                          ),
                          DropdownMenuItem(
                            value: PetSex.male,
                            child: Text('Macho'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _sex = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SelectField<PetSize>(
                  label: 'Tamano',
                  value: _size,
                  items: const [
                    DropdownMenuItem(
                      value: PetSize.small,
                      child: Text('Pequeno'),
                    ),
                    DropdownMenuItem(
                      value: PetSize.medium,
                      child: Text('Mediano'),
                    ),
                    DropdownMenuItem(
                      value: PetSize.large,
                      child: Text('Grande'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _size = value);
                  },
                ),
                const SizedBox(height: 12),
                _EditField(
                  label: 'Descripcion',
                  controller: _descriptionCtrl,
                  maxLines: 4,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => _save(),
                    child: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  final List<String> photoUrls;
  final List<File> newPhotos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveUrl;
  final ValueChanged<int> onRemoveFile;

  const _PhotoStrip({
    required this.photoUrls,
    required this.newPhotos,
    required this.onAdd,
    required this.onRemoveUrl,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        children: [
          ...photoUrls.asMap().entries.map(
                (entry) => _PhotoThumb(
                  imageUrl: entry.value,
                  selected: entry.key == 0,
                  onRemove: photoUrls.length > 1
                      ? () => onRemoveUrl(entry.key)
                      : null,
                ),
              ),
          ...newPhotos.asMap().entries.map(
                (entry) => _PhotoThumb(
                  file: entry.value,
                  onRemove: () => onRemoveFile(entry.key),
                ),
              ),
          if (photoUrls.length + newPhotos.length < 6)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 52,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider, width: 1.5),
                ),
                child: const Icon(Icons.add, color: AppColors.textHint),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final String? imageUrl;
  final File? file;
  final bool selected;
  final VoidCallback? onRemove;

  const _PhotoThumb({
    this.imageUrl,
    this.file,
    this.selected = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 52,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: file != null
              ? Image.file(file!, fit: BoxFit.cover)
              : CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover),
        ),
        if (onRemove != null)
          Positioned(
            top: 2,
            right: 10,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
      ],
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AvailabilityCard({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Disponible para buscar pareja',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Aparece en el feed de otros usuarios',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _EditField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: const InputDecoration(
            suffixIcon: Icon(Icons.edit_outlined, size: 18),
          ),
        ),
      ],
    );
  }
}

class _SelectField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _SelectField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}
