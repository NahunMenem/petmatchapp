import '../core/constants/api_constants.dart';
import '../models/message_model.dart';
import 'api_service.dart';

class ChatService {
  final _api = ApiService();

  Future<List<ConversationModel>> getConversations() async {
    final response = await _api.get(ApiConstants.conversations);
    final list = response.data as List;
    return list
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int page = 1,
  }) async {
    final response = await _api.get(
      '${ApiConstants.messages}/$conversationId',
      queryParams: {'page': page},
    );
    final list = response.data as List;
    return list
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final response = await _api.post(
      ApiConstants.messages,
      data: {'conversation_id': conversationId, 'content': content},
    );
    return MessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> markAsRead(String conversationId) async {
    await _api.patch('${ApiConstants.conversations}/$conversationId/read');
  }
}
