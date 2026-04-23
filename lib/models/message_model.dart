class ConversationModel {
  final String id;
  final String matchId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserPhoto;
  final String petName;
  final String petPhoto;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ConversationModel({
    required this.id,
    required this.matchId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserPhoto,
    required this.petName,
    required this.petPhoto,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      otherUserId: json['other_user_id'] as String,
      otherUserName: json['other_user_name'] as String,
      otherUserPhoto: json['other_user_photo'] as String? ?? '',
      petName: json['pet_name'] as String,
      petPhoto: json['pet_photo'] as String? ?? '',
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime sentAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.isRead = false,
    required this.sentAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      isRead: json['is_read'] as bool? ?? false,
      sentAt: DateTime.parse(json['sent_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
        'is_read': isRead,
        'sent_at': sentAt.toIso8601String(),
      };
}
