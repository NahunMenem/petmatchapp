enum NotificationType {
  newMatch,
  newMessage,
  adoptionInterest,
  lostPetNearby,
  lostAlertReach,
  profileTip,
  like,
  patitas,
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? imageUrl;
  final String? actionId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.actionId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationType parseType(String t) {
      switch (t) {
        case 'new_match':
          return NotificationType.newMatch;
        case 'new_message':
          return NotificationType.newMessage;
        case 'adoption_interest':
          return NotificationType.adoptionInterest;
        case 'lost_pet_nearby':
          return NotificationType.lostPetNearby;
        case 'lost_alert_reach':
          return NotificationType.lostAlertReach;
        case 'profile_tip':
          return NotificationType.profileTip;
        case 'patitas':
          return NotificationType.patitas;
        default:
          return NotificationType.like;
      }
    }

    return NotificationModel(
      id: json['id'] as String,
      type: parseType(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: json['image_url'] as String?,
      actionId: json['action_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  NotificationModel copyWith({
    NotificationType? type,
    String? title,
    String? body,
    String? imageUrl,
    String? actionId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      actionId: actionId ?? this.actionId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
