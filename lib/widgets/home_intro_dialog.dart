import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../services/storage_service.dart';

class IntroSlideData {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;

  const IntroSlideData({
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
  });
}

Future<void> showHomeIntroDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const HomeIntroDialog(),
  );
}

class HomeIntroDialog extends StatefulWidget {
  const HomeIntroDialog({super.key});

  @override
  State<HomeIntroDialog> createState() => _HomeIntroDialogState();
}

class _HomeIntroDialogState extends State<HomeIntroDialog> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _slides = [
    IntroSlideData(
      title: 'Explorá matches',
      description:
          'Descubrí mascotas que buscan pareja, deslizá perfiles y encontrá conexiones cerca tuyo.',
      icon: Icons.favorite_rounded,
      colors: [Color(0xFFFF8A5B), Color(0xFFFF5E7A)],
    ),
    IntroSlideData(
      title: 'Adopción simple',
      description:
          'Publicá mascotas en adopción o encontrá compañeros ideales usando filtros claros y rápidos.',
      icon: Icons.pets_rounded,
      colors: [Color(0xFFFFB36B), Color(0xFFFF7A45)],
    ),
    IntroSlideData(
      title: 'Mascotas perdidas',
      description:
          'Mirá alertas cercanas, ubicaciones en mapa y publicá reportes para ayudar a encontrarlas.',
      icon: Icons.location_on_rounded,
      colors: [Color(0xFFFF9068), Color(0xFFFF5A3D)],
    ),
    IntroSlideData(
      title: 'Patitas',
      description:
          'Usá Patitas para funciones especiales, impulsar alertas y desbloquear herramientas premium.',
      icon: Icons.auto_awesome_rounded,
      colors: [Color(0xFFFFC15A), Color(0xFFFF8A2A)],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await StorageService.setHomeIntroSeen(true);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    final isLast = _page == _slides.length - 1;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 30,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Cómo funciona PawMatch',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _close,
                  child: const Text('Omitir'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 360,
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (_, index) {
                  final item = _slides[index];
                  return Column(
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: item.colors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Icon(
                          item.icon,
                          size: 76,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == index
                        ? slide.colors.last
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLast
                    ? _close
                    : () => _controller.nextPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                        ),
                style: FilledButton.styleFrom(
                  backgroundColor: slide.colors.last,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(isLast ? 'Entendido' : 'Siguiente'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
