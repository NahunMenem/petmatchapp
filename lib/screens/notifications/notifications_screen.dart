import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_snack_bar.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          notificationsAsync.maybeWhen(
            data: (items) {
              final unreadCount = items.where((item) => !item.isRead).length;
              if (unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () async {
                  await ref.read(notificationsProvider.notifier).markAllRead();
                  if (!context.mounted) return;
                  AppSnackBar.success(
                    context,
                    title: 'Notificaciones',
                    message: 'Todas las notificaciones marcadas.',
                  );
                },
                child: const Text(
                  'Marcar leidas',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorState(
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (notifications) {
          if (notifications.isEmpty) return const _EmptyState();

          final today = notifications
              .where((n) => DateTime.now().difference(n.createdAt).inHours < 24)
              .toList();
          final older = notifications
              .where(
                  (n) => DateTime.now().difference(n.createdAt).inHours >= 24)
              .toList();

          return RefreshIndicator(
            onRefresh: () => ref.refresh(notificationsProvider.future),
            child: ListView(
              children: [
                if (today.isNotEmpty) ...[
                  const _SectionHeader('HOY'),
                  ...today.map((n) => _NotificationTile(notification: n)),
                ],
                if (older.isNotEmpty) ...[
                  const _SectionHeader('ANTERIORES'),
                  ...older.map((n) => _NotificationTile(notification: n)),
                ],
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;
  const _NotificationTile({required this.notification});

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.newMatch:
        return Icons.favorite_rounded;
      case NotificationType.newMessage:
        return Icons.chat_bubble_rounded;
      case NotificationType.adoptionInterest:
        return Icons.house_rounded;
      case NotificationType.lostPetNearby:
      case NotificationType.lostAlertReach:
        return Icons.location_on_rounded;
      case NotificationType.profileTip:
        return Icons.bolt_rounded;
      case NotificationType.like:
        return Icons.favorite_border_rounded;
      case NotificationType.patitas:
        return Icons.pets_rounded;
    }
  }

  Color get _color {
    switch (notification.type) {
      case NotificationType.newMatch:
      case NotificationType.like:
        return AppColors.primary;
      case NotificationType.newMessage:
        return AppColors.info;
      case NotificationType.adoptionInterest:
        return AppColors.success;
      case NotificationType.profileTip:
      case NotificationType.patitas:
        return AppColors.gold;
      case NotificationType.lostPetNearby:
      case NotificationType.lostAlertReach:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: notification.isRead
          ? Colors.transparent
          : AppColors.primary.withOpacity(0.04),
      child: InkWell(
        onTap: () async {
          if (!notification.isRead) {
            await ref
                .read(notificationsProvider.notifier)
                .markRead(notification.id);
          }
          if (!context.mounted) return;
          _openAction(context, notification);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationAvatar(
                icon: _icon,
                color: _color,
                imageUrl: notification.imageUrl,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.w600
                            : FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _timeAgo(notification.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAction(BuildContext context, NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.newMatch:
      case NotificationType.newMessage:
      case NotificationType.adoptionInterest:
        final conversationId = notification.actionId;
        if (conversationId != null && conversationId.isNotEmpty) {
          context.push('/chat/$conversationId');
        }
        break;
      case NotificationType.lostPetNearby:
      case NotificationType.lostAlertReach:
      case NotificationType.like:
      case NotificationType.profileTip:
      case NotificationType.patitas:
        context.go('/home');
        break;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} hs';
    if (diff.inDays == 1) {
      return 'Ayer, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }
}

class _NotificationAvatar extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? imageUrl;

  const _NotificationAvatar({
    required this.icon,
    required this.color,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final image = imageUrl;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: image == null || image.isEmpty
          ? Icon(icon, color: Colors.white, size: 22)
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.network(image, fit: BoxFit.cover),
                Container(color: color.withOpacity(0.22)),
                Icon(icon, color: Colors.white, size: 22),
              ],
            ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_off_outlined,
              size: 44,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            const Text(
              'No se pudieron cargar las notificaciones',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 48,
            color: AppColors.textHint,
          ),
          SizedBox(height: 16),
          Text(
            'Sin notificaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Cuando tengas actividad, aparecera aca',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
