import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

class PremiumSplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const PremiumSplashScreen({
    super.key,
    required this.onFinished,
  });

  @override
  State<PremiumSplashScreen> createState() => _PremiumSplashScreenState();
}

class _PremiumSplashScreenState extends State<PremiumSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.58, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 72,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutSine)),
        weight: 28,
      ),
    ]).animate(_controller);

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.32, curve: Curves.easeOut),
    );

    _glowOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.72, curve: Curves.easeOutCubic),
    );

    _controller
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          widget.onFinished();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0E12),
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final breath =
                1 + math.sin(_controller.value * math.pi * 2.2) * 0.018;

            return Stack(
              children: [
                const _DarkGradient(),
                Positioned(
                  left: -90,
                  top: 88,
                  child: _SoftGlow(
                    size: 240,
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
                Positioned(
                  right: -92,
                  bottom: 72,
                  child: _SoftGlow(
                    size: 270,
                    color: AppColors.secondary.withValues(alpha: 0.13),
                  ),
                ),
                Center(
                  child: Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value * breath,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: _glowOpacity.value,
                            child: _SoftGlow(
                              size: 220,
                              color: AppColors.primary.withValues(alpha: 0.24),
                            ),
                          ),
                          Image.asset(
                            'assets/images/pawmatch_splash_logo.png',
                            width: 210,
                            height: 108,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DarkGradient extends StatelessWidget {
  const _DarkGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF09090C),
            Color(0xFF17171D),
            Color(0xFF232026),
            Color(0xFF100F13),
          ],
          stops: [0.0, 0.36, 0.72, 1.0],
        ),
      ),
    );
  }
}

class _SoftGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftGlow({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.36,
            spreadRadius: size * 0.16,
          ),
        ],
      ),
    );
  }
}
