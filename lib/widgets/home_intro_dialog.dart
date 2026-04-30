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
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final slideHeight = (viewportHeight * 0.62).clamp(360.0, 590.0);

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
                    '¿Cómo funciona PawMatch?',
                    style: TextStyle(
                      fontSize: 20,
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
              height: slideHeight,
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (_, index) {
                  final item = _slides[index];
                  if (index == 0) return const _ExploreMatchesIntroSlide();
                  if (index == 1) return const _AdoptionIntroSlide();
                  if (index == 2) return const _LostPetsIntroSlide();
                  if (index == 3) return const _PatitasIntroSlide();
                  return _IntroSimpleSlide(item: item);
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
                    color:
                        _page == index ? slide.colors.last : AppColors.divider,
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

class _IntroSimpleSlide extends StatelessWidget {
  const _IntroSimpleSlide({required this.item});

  final IntroSlideData item;

  @override
  Widget build(BuildContext context) {
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
  }
}

class _ExploreMatchesIntroSlide extends StatelessWidget {
  const _ExploreMatchesIntroSlide();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        children: [
          _ExploreMatchesHero(),
          SizedBox(height: 22),
          Text(
            'Encontrá pareja para tu mascota',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Deslizá perfiles cerca tuyo. Si hay interés mutuo, se hace match y pueden chatear los dueños.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.42,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 22),
          _ExploreBenefitGrid(),
          SizedBox(height: 18),
          _ExplorePatitasCallout(),
        ],
      ),
    );
  }
}

class _ExploreMatchesHero extends StatelessWidget {
  const _ExploreMatchesHero();

  static const _imageUrl =
      'https://res.cloudinary.com/dqsacd9ez/image/upload/v1777511419/Captura_de_pantalla_2026-04-29_220929_qxcj1y.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            const Color(0xFFFFE8DE),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Image.network(
        _imageUrl,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(
            Icons.favorite_rounded,
            color: Color(0xFFFF4C76),
            size: 72,
          ),
        ),
      ),
    );
  }
}

class _ExploreBenefitGrid extends StatelessWidget {
  const _ExploreBenefitGrid();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ExploreBenefitItem(
            icon: Icons.style_rounded,
            title: 'Deslizá para dar like',
            subtitle: 'Explorá mascotas\ncerca tuyo',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _ExploreBenefitItem(
            icon: Icons.favorite_rounded,
            title: 'Match si es mutuo',
            subtitle: 'Si ambos dan like,\nse hace match',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _ExploreBenefitItem(
            icon: Icons.forum_rounded,
            title: 'Chat entre dueños',
            subtitle: 'Conocete y coordiná\ncon seguridad',
          ),
        ),
      ],
    );
  }
}

class _ExploreBenefitItem extends StatelessWidget {
  const _ExploreBenefitItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            color: const Color(0xFFFF4C76).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFF4C76),
            size: 30,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            height: 1.15,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            height: 1.22,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ExplorePatitasCallout extends StatelessWidget {
  const _ExplorePatitasCallout();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4C76).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.pets_rounded,
            color: Color(0xFFFF4C76),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  height: 1.25,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                      text: 'Destacá tu mascota o usá likes ilimitados con '),
                  TextSpan(
                    text: 'Patitas',
                    style: TextStyle(
                      color: Color(0xFFFF4C76),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFFF4C76),
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _AdoptionIntroSlide extends StatelessWidget {
  const _AdoptionIntroSlide();

  static const _imageUrl =
      'https://res.cloudinary.com/dqsacd9ez/image/upload/v1777511419/Captura_de_pantalla_2026-04-29_221002_dq5mzm.png';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Container(
            height: 230,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9DB),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Image.network(
              _imageUrl,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(
                  Icons.pets_rounded,
                  color: AppColors.primary,
                  size: 72,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Adopción simple',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Publicá mascotas en adopción o encontrá compañeros ideales usando filtros claros y rápidos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatitasIntroSlide extends StatelessWidget {
  const _PatitasIntroSlide();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        children: [
          _PatitasHero(),
          SizedBox(height: 22),
          Text(
            'Usá Patitas y potenciá tu experiencia',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Las Patitas te permiten impulsar alertas, destacar tu mascota y desbloquear herramientas premium para tener más alcance y mejores resultados.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 24),
          _PatitasBenefitGrid(),
          SizedBox(height: 18),
          _BuyPatitasCallout(),
        ],
      ),
    );
  }
}

class _PatitasHero extends StatelessWidget {
  const _PatitasHero();

  static const _imageUrl =
      'https://res.cloudinary.com/dqsacd9ez/image/upload/v1777511421/Captura_de_pantalla_2026-04-29_220946_bkrwcs.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD777), Color(0xFFFFA332)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Image.network(
        _imageUrl,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(
            Icons.pets_rounded,
            color: Color(0xFFFF8B00),
            size: 72,
          ),
        ),
      ),
    );
  }
}

class _PatitasBenefitGrid extends StatelessWidget {
  const _PatitasBenefitGrid();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _PatitasBenefitItem(
            icon: Icons.campaign_rounded,
            title: 'Más alcance',
            subtitle: 'Tu alerta llega\na más personas',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _PatitasBenefitItem(
            icon: Icons.star_rounded,
            title: 'Más visibilidad',
            subtitle: 'Destacá tu mascota\ny recibí atención',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _PatitasBenefitItem(
            icon: Icons.visibility_rounded,
            title: 'Más conexiones',
            subtitle: 'Descubrí quién\nte dio like',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _PatitasBenefitItem(
            icon: Icons.lock_rounded,
            title: 'Funciones exclusivas',
            subtitle: 'Herramientas premium\nsolo para vos',
          ),
        ),
      ],
    );
  }
}

class _PatitasBenefitItem extends StatelessWidget {
  const _PatitasBenefitItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFFF980F).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFF8B00),
            size: 28,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            height: 1.12,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            height: 1.18,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _BuyPatitasCallout extends StatelessWidget {
  const _BuyPatitasCallout();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF980F).withValues(alpha: 0.14),
            const Color(0xFFFFC36B).withValues(alpha: 0.18),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFF980F).withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: Color(0xFFFF8B00),
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  height: 1.25,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(
                    text: 'Comprá Patitas',
                    style: TextStyle(
                      color: Color(0xFFFF6B00),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' y aumentá tus chances de encontrar, conectar y ayudar.',
                  ),
                ],
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFFF8B00),
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _LostPetsIntroSlide extends StatelessWidget {
  const _LostPetsIntroSlide();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        children: [
          _LostPetsHeroIllustration(),
          SizedBox(height: 20),
          Text(
            'Ayudá a encontrar mascotas perdidas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Recibí alertas en tiempo real de mascotas perdidas cerca tuyo. Mirá su ubicación en el mapa y ayudá a que vuelvan a casa.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20),
          _LostPetFeatureRow(
            icon: Icons.notifications_rounded,
            title: 'Alertas en tiempo real',
            subtitle: 'Te avisamos cuando se pierde una mascota cerca tuyo.',
          ),
          _LostPetFeatureRow(
            icon: Icons.location_on_rounded,
            title: 'Ubicaciones en el mapa',
            subtitle: 'Vé exactamente dónde fue vista por última vez.',
          ),
          _LostPetFeatureRow(
            icon: Icons.near_me_rounded,
            title: 'Publicá reportes fácilmente',
            subtitle:
                'Reportá una mascota perdida en segundos y llegá a más personas.',
          ),
          SizedBox(height: 12),
          _PatitasReachCallout(),
        ],
      ),
    );
  }
}

class _LostPetsHeroIllustration extends StatelessWidget {
  const _LostPetsHeroIllustration();

  static const _imageUrl =
      'https://res.cloudinary.com/dqsacd9ez/image/upload/v1777511420/Captura_de_pantalla_2026-04-29_220908_guh4kk.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9DB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Image.network(
        _imageUrl,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(
            Icons.location_on_rounded,
            color: AppColors.primary,
            size: 72,
          ),
        ),
      ),
    );
  }
}

class _LostPetFeatureRow extends StatelessWidget {
  const _LostPetFeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.32,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatitasReachCallout extends StatelessWidget {
  const _PatitasReachCallout();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.pets_rounded,
            color: AppColors.primary,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text:
                        'Podés ampliar el alcance de tu alerta a más personas usando ',
                  ),
                  TextSpan(
                    text: 'Patitas.',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
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
