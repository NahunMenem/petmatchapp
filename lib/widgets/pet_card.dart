import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/pet_model.dart';

class PetCard extends StatefulWidget {
  final PetModel pet;

  const PetCard({super.key, required this.pet});

  @override
  State<PetCard> createState() => _PetCardState();
}

class _PetCardState extends State<PetCard> {
  int _currentPhoto = 0;

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final distanceLabel = pet.distanceLabel;
    final photos = pet.photos.isNotEmpty ? pet.photos : [''];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              if (photos.length <= 1) return;
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final localDx = box.globalToLocal(details.globalPosition).dx;
              final halfWidth = box.size.width / 2;
              setState(() {
                if (localDx < halfWidth) {
                  _currentPhoto =
                      (_currentPhoto - 1 + photos.length) % photos.length;
                } else {
                  _currentPhoto = (_currentPhoto + 1) % photos.length;
                }
              });
            },
            child: _PetPhoto(photoUrl: photos[_currentPhoto]),
          ),

          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.cardOverlay),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pet.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (distanceLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              distanceLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${pet.breed} · ${pet.age}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (distanceLabel != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$distanceLabel de vos',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Badge(pet.sexLabel),
                    _Badge(pet.sizeLabel),
                    if (pet.vaccinesUpToDate) const _Badge('✓ Vacunada'),
                    if (pet.sterilized) const _Badge('✓ Esterilizada'),
                  ],
                ),
              ],
            ),
          ),

          if (photos.length > 1)
            Positioned(
              top: 14,
              left: 20,
              right: 20,
              child: Row(
                children: photos.asMap().entries.map((entry) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: entry.key == _currentPhoto
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          if (photos.length > 1)
            Positioned(
              left: 20,
              right: 20,
              bottom: 154,
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _PhotoHint(
                      icon: Icons.chevron_left_rounded,
                      label: 'Toca izq.',
                    ),
                    _PhotoHint(
                      icon: Icons.chevron_right_rounded,
                      label: 'Toca der.',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PetPhoto extends StatelessWidget {
  final String photoUrl;

  const _PetPhoto({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isEmpty) {
      return Container(
        color: AppColors.surfaceVariant,
        child: const Icon(
          Icons.pets,
          size: 80,
          color: AppColors.textHint,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: photoUrl,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => Container(
        color: AppColors.surfaceVariant,
        child: const Icon(
          Icons.pets,
          size: 80,
          color: AppColors.textHint,
        ),
      ),
    );
  }
}

class _PhotoHint extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PhotoHint({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
