import '../core/constants/api_constants.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationService {
  final _api = ApiService();

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _api.get(ApiConstants.notifications);
    final list = response.data as List;
    return list
        .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(String notificationId) async {
    await _api.patch('${ApiConstants.notifications}/$notificationId/read');
  }

  Future<void> markAllRead() async {
    await _api.patch('${ApiConstants.notifications}/read-all');
  }
}
