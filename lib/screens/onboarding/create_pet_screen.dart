import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_snack_bar.dart';
import '../../core/utils/validators.dart';
import '../../models/pet_model.dart';
import '../../providers/pets_provider.dart';
import '../../widgets/primary_button.dart';

class CreatePetScreen extends ConsumerStatefulWidget {
  const CreatePetScreen({super.key});

  @override
  ConsumerState<CreatePetScreen> createState() => _CreatePetScreenState();
}

class _CreatePetScreenState extends ConsumerState<CreatePetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _customBreedCtrl = TextEditingController();

  PetType _selectedType = PetType.dog;
  String? _selectedBreed;
  String? _selectedAge;
  PetSex _selectedSex = PetSex.male;
  PetSize _selectedSize = PetSize.medium;
  bool _vaccinesUpToDate = false;
  List<File> _photos = [];
  bool _loading = false;
  static const _otherBreed = 'Otro';

  final List<String> _dogBreeds = [
    'Mestizo',
    'Golden Retriever',
    'Labrador',
    'Labrador Retriever',
    'Pastor Aleman',
    'Caniche / Poodle',
    'Bulldog',
    'Bulldog Frances',
    'Beagle',
    'Boxer',
    'Rottweiler',
    'Husky Siberiano',
    'Border Collie',
    'Dachshund / Salchicha',
    'Chihuahua',
    'Yorkshire Terrier',
    'Shih Tzu',
    'Schnauzer',
    'Cocker Spaniel',
    'Pitbull',
    'Doberman',
    'Akita',
    'Galgo',
    'Bichon Frise',
    'Pastor Alemán',
    'Dálmata',
    'Mestizo',
    'Otro',
  ];

  final List<String> _catBreeds = [
    'Mestizo',
    'Comun Europeo',
    'Persa',
    'Siamés',
    'Maine Coon',
    'Bengalí',
    'Ragdoll',
    'Britanico de pelo corto',
    'Azul Ruso',
    'Sphynx',
    'Angora',
    'Bosque de Noruega',
    'Scottish Fold',
    'Abisinio',
    'Birmano',
    'Común Europeo',
    'Mestizo',
    'Otro',
  ];

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
    '6 años',
    '7+ años',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _customBreedCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_photos.length >= 6) return;
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(limit: 6 - _photos.length);
    if (picked.isNotEmpty) {
      setState(() {
        _photos.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final breed = _selectedBreed == _otherBreed
        ? _customBreedCtrl.text.trim()
        : _selectedBreed;
    if (breed == null || breed.isEmpty) {
      _showError('Seleccioná la raza');
      return;
    }
    if (_selectedAge == null) {
      _showError('Seleccioná la edad');
      return;
    }
    if (_photos.isEmpty) {
      _showError('Agregá al menos una foto');
      return;
    }

    setState(() => _loading = true);

    try {
      final service = ref.read(petServiceProvider);

      // Upload photos
      final photoUrls = <String>[];
      for (final photo in _photos) {
        final url = await service.uploadPhoto(photo.path);
        photoUrls.add(url);
      }

      await service.createPet({
        'name': _nameCtrl.text.trim(),
        'type': _selectedType == PetType.dog ? 'dog' : 'cat',
        'breed': breed,
        'age': _selectedAge,
        'sex': _selectedSex == PetSex.male ? 'male' : 'female',
        'size': _selectedSize.name,
        'vaccines_up_to_date': _vaccinesUpToDate,
        'photos': photoUrls,
        'description': _descriptionCtrl.text.trim(),
      });

      if (mounted) {
        ref.invalidate(myPetsProvider);
        context.go('/home');
      }
    } catch (e) {
      if (mounted) _showError('Error al crear el perfil. Intentá de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    AppSnackBar.error(context, message: msg);
  }

  @override
  Widget build(BuildContext context) {
    final breeds = (_selectedType == PetType.dog ? _dogBreeds : _catBreeds)
        .where((breed) => !breed.contains('Ã'))
        .toSet()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear perfil de mascota'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.pop(),
              )
            : null,
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Pet type selector
            _SectionLabel('¿Qué tipo de mascota tenés?'),
            const SizedBox(height: 12),
            Row(
              children: [
                _TypeChip(
                  label: '🐶 Perro',
                  selected: _selectedType == PetType.dog,
                  onTap: () {
                    setState(() {
                      _selectedType = PetType.dog;
                      _selectedBreed = null;
                      _customBreedCtrl.clear();
                    });
                  },
                ),
                const SizedBox(width: 12),
                _TypeChip(
                  label: '🐱 Gato',
                  selected: _selectedType == PetType.cat,
                  onTap: () {
                    setState(() {
                      _selectedType = PetType.cat;
                      _selectedBreed = null;
                      _customBreedCtrl.clear();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Name
            _SectionLabel('Nombre'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration:
                  const InputDecoration(hintText: 'Nombre de tu mascota'),
              validator: (v) => Validators.required(v, 'El nombre'),
            ),
            const SizedBox(height: 20),

            // Breed
            _SectionLabel('Raza'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedBreed,
              hint: const Text('Seleccionar raza'),
              decoration: const InputDecoration(),
              items: breeds
                  .map(
                    (b) => DropdownMenuItem(
                      value: b,
                      child: Text(b, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedBreed = v;
                  if (v != _otherBreed) _customBreedCtrl.clear();
                });
              },
            ),
            if (_selectedBreed == _otherBreed) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customBreedCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Escribi la raza'),
                validator: (v) {
                  if (_selectedBreed != _otherBreed) return null;
                  return Validators.required(v, 'La raza');
                },
              ),
            ],
            const SizedBox(height: 20),

            // Age
            _SectionLabel('Edad'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedAge,
              hint: const Text('Seleccionar edad'),
              decoration: const InputDecoration(),
              items: _ages
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedAge = v),
            ),
            const SizedBox(height: 20),

            // Sex
            _SectionLabel('Sexo'),
            const SizedBox(height: 12),
            Row(
              children: [
                _SelectChip(
                  label: 'Macho',
                  icon: Icons.male,
                  selected: _selectedSex == PetSex.male,
                  onTap: () => setState(() => _selectedSex = PetSex.male),
                ),
                const SizedBox(width: 12),
                _SelectChip(
                  label: 'Hembra',
                  icon: Icons.female,
                  selected: _selectedSex == PetSex.female,
                  onTap: () => setState(() => _selectedSex = PetSex.female),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Size
            _SectionLabel('Tamaño'),
            const SizedBox(height: 12),
            Row(
              children: [
                _SelectChip(
                  label: 'Pequeño',
                  selected: _selectedSize == PetSize.small,
                  onTap: () => setState(() => _selectedSize = PetSize.small),
                ),
                const SizedBox(width: 8),
                _SelectChip(
                  label: 'Mediano',
                  selected: _selectedSize == PetSize.medium,
                  onTap: () => setState(() => _selectedSize = PetSize.medium),
                ),
                const SizedBox(width: 8),
                _SelectChip(
                  label: 'Grande',
                  selected: _selectedSize == PetSize.large,
                  onTap: () => setState(() => _selectedSize = PetSize.large),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Vaccines
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SwitchListTile(
                title: const Text('Vacunas al día'),
                subtitle: const Text('Mi mascota tiene todas las vacunas'),
                value: _vaccinesUpToDate,
                onChanged: (v) => setState(() => _vaccinesUpToDate = v),
                activeColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Description
            _SectionLabel('Descripción (opcional)'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'Contá algo sobre tu mascota, su personalidad, qué le gusta...',
              ),
            ),
            const SizedBox(height: 20),

            // Photos
            _SectionLabel('Fotos'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4EC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.18),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tip: si la foto principal es vertical, tu mascota se va a ver mejor en las cards y en Explorar.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Solo una mascota por cuenta puede estar buscando pareja a la vez. Si ya tienes una activa, esta nueva se creara pausada.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _PhotoGrid(
              photos: _photos,
              onAdd: _pickImage,
              onRemove: (i) => setState(() => _photos.removeAt(i)),
            ),
            const SizedBox(height: 32),

            PrimaryButton(
              label: 'Crear perfil',
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall,
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
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
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _SelectChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<File> photos;
  final VoidCallback onAdd;
  final Function(int) onRemove;

  const _PhotoGrid({
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });

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
              (entry) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      entry.value,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemove(entry.key),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
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
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Agregar\nfotos',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
