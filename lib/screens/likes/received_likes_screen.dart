import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_snack_bar.dart';
import '../../models/received_like_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/patitas_provider.dart';
import '../../providers/pets_provider.dart';

class ReceivedLikesScreen extends ConsumerWidget {
  const ReceivedLikesScreen({super.key});

  static const int unlockCost = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likesAsync = ref.watch(receivedLikesProvider);
    final walletAsync = ref.watch(patitasWalletProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: likesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => _ErrorView(
          onRetry: () => ref.invalidate(receivedLikesProvider),
        ),
        data: (data) => _LikesBody(
          data: data,
          availablePatitas: walletAsync.valueOrNull?.patitas,
          onUnlock: () async {
            final wallet = ref.read(patitasWalletProvider).valueOrNull;
            final balance = wallet?.patitas ?? 0;
            if (balance < unlockCost) {
              AppSnackBar.error(
                context,
                title: 'Patitas insuficientes',
                message: 'No tenes Patitas suficientes.',
                actionLabel: 'Comprar',
                onAction: () => context.push('/paw-points/buy'),
              );
              return;
            }
            try {
              await ref.read(receivedLikesProvider.notifier).unlock();
              await ref.read(patitasWalletProvider.notifier).refresh();
              if (context.mounted) {
                AppSnackBar.success(
                  context,
                  title: 'Desbloqueado',
                  message: 'Likes desbloqueados por 30 dias.',
                );
              }
            } catch (_) {
              if (context.mounted) {
                AppSnackBar.error(
                  context,
                  message: 'No se pudieron desbloquear los likes.',
                );
              }
            }
          },
        ),
      ),
    );
  }
}

class _LikesBody extends StatelessWidget {
  final ReceivedLikesModel data;
  final int? availablePatitas;
  final Future<void> Function() onUnlock;

  const _LikesBody({
    required this.data,
    required this.availablePatitas,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final previewLikes = data.likes.isEmpty
        ? List<ReceivedLikeModel>.filled(4, const ReceivedLikeModel())
        : data.likes.take(data.unlocked ? data.likes.length : 4).toList();

    return Column(
      children: [
        _Header(total: data.total),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
            children: [
              const Center(
                child: Text(
                  'Podrian ser el match perfecto',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (data.unlocked)
                _UnlockedLikes(likes: previewLikes)
              else
                _LockedPreview(likes: previewLikes),
              const SizedBox(height: 16),
              if (data.unlocked)
                const _UnlockedCard()
              else
                _UnlockCard(
                  total: data.total,
                  availablePatitas: availablePatitas,
                  onUnlock: onUnlock,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final int total;

  const _Header({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6800), Color(0xFFFF8231)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_border_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$total likes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Te dieron likes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            total == 0
                ? 'Todavia no hay mascotas interesadas'
                : 'Hay mascotas interesadas en la tuya',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$total personas interesadas en tu mascota',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LockedPreview extends StatelessWidget {
  final List<ReceivedLikeModel> likes;

  const _LockedPreview({required this.likes});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (_, index) {
        final like = index < likes.length ? likes[index] : null;
        return _LockedLikeTile(photoUrl: like?.petPhoto);
      },
    );
  }
}

class _UnlockedLikes extends StatelessWidget {
  final List<ReceivedLikeModel> likes;

  const _UnlockedLikes({required this.likes});

  @override
  Widget build(BuildContext context) {
    if (likes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text(
          'Cuando alguien le de like a tu mascota va a aparecer aca.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Column(
      children: likes
          .map(
            (like) => _UnlockedLikeTile(
              like: like,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _ReceivedLikeDetailScreen(like: like),
                  ),
                );
              },
            ),
          )
          .toList(),
    );
  }
}

class _LockedLikeTile extends StatelessWidget {
  final String? photoUrl;

  const _LockedLikeTile({this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: photoUrl != null
                ? Image.network(photoUrl!, fit: BoxFit.cover)
                : Container(color: const Color(0xFF4D463B)),
          ),
          Container(color: Colors.black.withValues(alpha: 0.34)),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, color: Colors.white, size: 30),
                SizedBox(height: 10),
                Icon(
                  Icons.favorite_border_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockedLikeTile extends StatelessWidget {
  final ReceivedLikeModel like;
  final VoidCallback onTap;

  const _UnlockedLikeTile({
    required this.like,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: like.petPhoto != null
                      ? Image.network(like.petPhoto!, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.surfaceVariant,
                          child:
                              const Icon(Icons.pets, color: AppColors.textHint),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      like.petName ?? 'Mascota',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Le gusto ${like.likedMyPetName ?? 'tu mascota'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((like.ownerName ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        like.ownerName!,
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Column(
                children: [
                  Icon(Icons.favorite_rounded, color: AppColors.primary),
                  SizedBox(height: 8),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnlockCard extends StatelessWidget {
  final int total;
  final int? availablePatitas;
  final Future<void> Function() onUnlock;

  const _UnlockCard({
    required this.total,
    required this.availablePatitas,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = total == 0;
    final patitas = availablePatitas;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_open_rounded, color: AppColors.primary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Descubri quien dio like',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Activalo por 30 dias para desbloquear los perfiles que le dieron like a tus mascotas.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Se descuentan 30 Patitas una sola vez por 30 dias.',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: disabled ? null : onUnlock,
              icon: const Icon(Icons.pets, size: 18),
              label: const Text(
                'Activar 30 dias - 30 Patitas',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              patitas == null
                  ? 'Cargando saldo de Patitas...'
                  : patitas < ReceivedLikesScreen.unlockCost
                      ? 'Saldo insuficiente'
                      : 'Tenes $patitas Patitas disponibles',
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockedCard extends StatelessWidget {
  const _UnlockedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_open_rounded, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Likes desbloqueados',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivedLikeDetailScreen extends ConsumerStatefulWidget {
  final ReceivedLikeModel like;

  const _ReceivedLikeDetailScreen({required this.like});

  @override
  ConsumerState<_ReceivedLikeDetailScreen> createState() =>
      _ReceivedLikeDetailScreenState();
}

class _ReceivedLikeDetailScreenState
    extends ConsumerState<_ReceivedLikeDetailScreen> {
  late bool _responseSent;
  bool _sendingLike = false;

  @override
  void initState() {
    super.initState();
    _responseSent = widget.like.responseSent;
  }

  @override
  Widget build(BuildContext context) {
    final like = widget.like;
    final photos = like.photos.isNotEmpty
        ? like.photos
        : [
            if ((like.petPhoto ?? '').isNotEmpty) like.petPhoto!,
          ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(like.petName ?? 'Perfil'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          if (photos.isNotEmpty)
            SizedBox(
              height: 240,
              child: PageView.builder(
                itemCount: photos.length,
                itemBuilder: (_, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _FullscreenGalleryScreen(
                            photos: photos,
                            initialIndex: index,
                            title: like.petName ?? 'Fotos',
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            photos[index],
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.zoom_out_map_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Ver grande',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.pets,
                color: AppColors.textHint,
                size: 56,
              ),
            ),
          const SizedBox(height: 18),
          Text(
            like.petName ?? 'Mascota',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            like.ownerName?.isNotEmpty == true
                ? 'De ${like.ownerName}'
                : 'Perfil desbloqueado',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(label: _petTypeLabel(like.petType)),
              if ((like.breed ?? '').isNotEmpty) _InfoChip(label: like.breed!),
              if ((like.age ?? '').isNotEmpty) _InfoChip(label: like.age!),
              if ((like.sex ?? '').isNotEmpty)
                _InfoChip(label: _sexLabel(like.sex)),
              if ((like.size ?? '').isNotEmpty)
                _InfoChip(label: _sizeLabel(like.size)),
              if (like.vaccinesUpToDate == true)
                const _InfoChip(label: 'Vacunas al dia'),
              if (like.sterilized == true)
                const _InfoChip(label: 'Castrado/a'),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sobre este perrito',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  (like.description ?? '').trim().isEmpty
                      ? 'Todavia no agrego una descripcion.'
                      : like.description!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.matchGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              _responseSent
                  ? 'Ya respondiste este like. Si hubo match, el chat ya quedo habilitado.'
                  : 'Le dio like a ${like.likedMyPetName ?? 'tu mascota'}. Si le devolves el like y es mutuo, se habilita el chat.',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
          if (!_responseSent && (like.petId ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _sendingLike ? null : _returnLike,
                icon: _sendingLike
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.favorite_rounded),
                label: Text(
                  _sendingLike ? 'Enviando...' : 'Devolver like',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _returnLike() async {
    final petId = widget.like.petId;
    if (petId == null || petId.isEmpty || _sendingLike) return;

    setState(() => _sendingLike = true);
    try {
      final result = await ref.read(petServiceProvider).likePet(petId);
      ref.invalidate(receivedLikesProvider);
      ref.invalidate(conversationsProvider);
      if (!mounted) return;
      setState(() => _responseSent = true);
      AppSnackBar.success(
        context,
        title: result.isMatch ? 'Es un match' : 'Like enviado',
        message: result.isMatch
            ? 'Like devuelto. Hicieron match.'
            : 'Like devuelto correctamente.',
        actionLabel:
            result.isMatch && (result.conversationId ?? '').isNotEmpty
                ? 'Abrir chat'
                : null,
        onAction: result.isMatch && (result.conversationId ?? '').isNotEmpty
            ? () => context.push('/chat/${result.conversationId}')
            : null,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        message: 'No se pudo devolver el like.',
      );
    } finally {
      if (mounted) {
        setState(() => _sendingLike = false);
      }
    }
  }

  static String _petTypeLabel(String? value) {
    switch (value) {
      case 'dog':
        return 'Perro';
      case 'cat':
        return 'Gato';
      default:
        return 'Mascota';
    }
  }

  static String _sexLabel(String? value) {
    switch (value) {
      case 'male':
        return 'Macho';
      case 'female':
        return 'Hembra';
      default:
        return value ?? '';
    }
  }

  static String _sizeLabel(String? value) {
    switch (value) {
      case 'small':
        return 'Pequeno';
      case 'medium':
        return 'Mediano';
      case 'large':
        return 'Grande';
      default:
        return value ?? '';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FullscreenGalleryScreen extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  final String title;

  const _FullscreenGalleryScreen({
    required this.photos,
    required this.initialIndex,
    required this.title,
  });

  @override
  State<_FullscreenGalleryScreen> createState() =>
      _FullscreenGalleryScreenState();
}

class _FullscreenGalleryScreenState extends State<_FullscreenGalleryScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  int get _safeInitialIndex {
    if (widget.photos.isEmpty) return 0;
    return widget.initialIndex.clamp(0, widget.photos.length - 1);
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = _safeInitialIndex;
    _pageController = PageController(initialPage: _safeInitialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${widget.title} ${_currentIndex + 1}/${widget.photos.length}',
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (_, index) {
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Image.network(
                widget.photos[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onRetry,
        child: const Text('Reintentar'),
      ),
    );
  }
}
