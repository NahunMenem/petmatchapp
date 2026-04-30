import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';

Future<void> showPatitasInsufficientDialog(
  BuildContext context, {
  required int currentPatitas,
  required int requiredPatitas,
  required String featureName,
}) {
  final missingPatitas = (requiredPatitas - currentPatitas).clamp(0, 999999);

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.pets_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No tenes Patitas suficientes',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Para $featureName necesitas $requiredPatitas Patitas.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.18)),
            ),
            child: Column(
              children: [
                _PatitasRow(label: 'Tenes', value: currentPatitas),
                const SizedBox(height: 8),
                _PatitasRow(label: 'Necesitas', value: requiredPatitas),
                const Divider(height: 18),
                _PatitasRow(
                  label: 'Te faltan',
                  value: missingPatitas,
                  isHighlighted: true,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Ahora no'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            context.push('/paw-points/buy');
          },
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Cargar Patitas'),
        ),
      ],
    ),
  );
}

class _PatitasRow extends StatelessWidget {
  final String label;
  final int value;
  final bool isHighlighted;

  const _PatitasRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isHighlighted ? AppColors.primary : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          '$value Patitas',
          style: TextStyle(
            color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
