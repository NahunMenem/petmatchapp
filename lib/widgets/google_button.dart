import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const GoogleButton({
    super.key,
    this.onPressed,
    this.label = 'Ingresar con Google',
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.divider, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Google G icon
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: const Text(
              'G',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF4285F4),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
