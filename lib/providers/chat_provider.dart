import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

final conversationsProvider =
    FutureProvider<List<ConversationModel>>((ref) async {
  try {
    return await ref.read(chatServiceProvider).getConversations();
  } catch (_) {
    return const [];
  }
});

class MessagesNotifier extends FamilyAsyncNotifier<List<MessageModel>, String> {
  @override
  Future<List<MessageModel>> build(String conversationId) async {
    return ref.read(chatServiceProvider).getMessages(conversationId);
  }

  Future<void> sendMessage(String content) async {
    final service = ref.read(chatServiceProvider);
    final msg = await service.sendMessage(
      conversationId: arg,
      content: content,
    );
    state = AsyncValue.data([...state.value ?? [], msg]);
  }
}

final messagesProvider =
    AsyncNotifierProviderFamily<MessagesNotifier, List<MessageModel>, String>(
  MessagesNotifier.new,
);

final totalUnreadProvider = Provider<int>((ref) {
  final conversations = ref.watch(conversationsProvider);
  return conversations.maybeWhen(
    data: (list) => list.fold(0, (sum, c) => sum + c.unreadCount),
    orElse: () => 0,
  );
});
