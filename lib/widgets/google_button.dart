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
    final enabled = onPressed != null;
    final isLoading = label.toLowerCase().contains('conectando');

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: enabled ? 0.08 : 0.03),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: enabled ? Colors.white : const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: enabled
                    ? Colors.white.withValues(alpha: 0.96)
                    : AppColors.divider,
                width: 1.4,
              ),
              gradient: enabled
                  ? const LinearGradient(
                      colors: [
                        Color(0xFFFFFFFF),
                        Color(0xFFFFFBF8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isLoading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.primary,
                          ),
                        )
                      : const _GoogleIcon(key: ValueKey('icon'), size: 24),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  final double size;

  const _GoogleIcon({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.16;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(arcRect, -0.08, 1.42, false, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(arcRect, 1.34, 1.18, false, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(arcRect, 2.52, 1.04, false, paint);

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(arcRect, 3.56, 1.58, false, paint);

    final linePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square;

    final y = size.height * 0.50;
    canvas.drawLine(
      Offset(size.width * 0.52, y),
      Offset(size.width * 0.90, y),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
