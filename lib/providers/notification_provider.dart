import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() {
    return ref.read(notificationServiceProvider).getNotifications();
  }

  Future<void> markRead(String notificationId) async {
    await ref.read(notificationServiceProvider).markRead(notificationId);
    final current = state.valueOrNull;
    if (current == null) {
      ref.invalidateSelf();
      return;
    }
    state = AsyncData(
      current
          .map(
            (item) =>
                item.id == notificationId ? item.copyWith(isRead: true) : item,
          )
          .toList(),
    );
  }

  Future<void> markAllRead() async {
    await ref.read(notificationServiceProvider).markAllRead();
    final current = state.valueOrNull;
    if (current == null) {
      ref.invalidateSelf();
      return;
    }
    state = AsyncData(
      current.map((item) => item.copyWith(isRead: true)).toList(),
    );
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  NotificationsNotifier.new,
);

final unreadNotificationsProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.maybeWhen(
    data: (items) => items.where((item) => !item.isRead).length,
    orElse: () => 0,
  );
});
