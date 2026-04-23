import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_colors.dart';
import '../models/pet_model.dart';

class PetCard extends StatelessWidget {
  final PetModel pet;

  const PetCard({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    final distanceLabel = pet.distanceLabel;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo
          CachedNetworkImage(
            imageUrl: pet.mainPhoto,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              color: AppColors.surfaceVariant,
              child: const Icon(
                Icons.pets,
                size: 80,
                color: AppColors.textHint,
              ),
            ),
          ),

          // Gradient overlay
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.cardOverlay),
          ),

          // Info
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name + age + distance
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
                            horizontal: 10, vertical: 5),
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
                // Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Badge(pet.sexLabel),
                    _Badge(pet.sizeLabel),
                    if (pet.vaccinesUpToDate) _Badge('✓ Vacunada'),
                    if (pet.sterilized) _Badge('✓ Esterilizada'),
                  ],
                ),
              ],
            ),
          ),

          // Photo indicator dots (if multiple photos)
          if (pet.photos.length > 1)
            Positioned(
              top: 14,
              left: 20,
              right: 20,
              child: Row(
                children: pet.photos
                    .asMap()
                    .entries
                    .map(
                      (e) => Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: e.key == 0
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    )
                    .toList(),
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
