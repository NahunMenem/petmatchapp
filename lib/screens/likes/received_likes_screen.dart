import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/received_like_model.dart';
import '../../providers/patitas_provider.dart';
import '../../providers/pets_provider.dart';

class ReceivedLikesScreen extends ConsumerWidget {
  const ReceivedLikesScreen({super.key});

  static const int unlockCost = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likesAsync = ref.watch(receivedLikesProvider);
    final wallet = ref.watch(patitasWalletProvider).valueOrNull;

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
          availablePatitas: wallet?.patitas ?? 0,
          onUnlock: () async {
            if ((wallet?.patitas ?? 0) < unlockCost) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No tenes Patitas suficientes'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            await ref.read(receivedLikesProvider.notifier).unlock();
            await ref.read(patitasWalletProvider.notifier).refresh();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Likes desbloqueados por 30 dias'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class _LikesBody extends StatelessWidget {
  final ReceivedLikesModel data;
  final int availablePatitas;
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
      children: likes.map((like) => _UnlockedLikeTile(like: like)).toList(),
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

  const _UnlockedLikeTile({required this.like});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      child: const Icon(Icons.pets, color: AppColors.textHint),
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
          const Icon(Icons.favorite_rounded, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _UnlockCard extends StatelessWidget {
  final int total;
  final int availablePatitas;
  final Future<void> Function() onUnlock;

  const _UnlockCard({
    required this.total,
    required this.availablePatitas,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final disabled =
        total == 0 || availablePatitas < ReceivedLikesScreen.unlockCost;
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
              availablePatitas < ReceivedLikesScreen.unlockCost
                  ? 'Saldo insuficiente'
                  : 'Activo por 30 dias - Sin cargo adicional',
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
