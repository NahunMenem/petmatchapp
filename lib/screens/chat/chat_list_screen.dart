import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_colors.dart';
import '../../models/message_model.dart';
import '../../providers/chat_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mensajes')),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (conversations) {
          if (conversations.isEmpty) {
            return const _EmptyConversations();
          }

          // Separate new matches from conversations
          final newMatches = conversations
              .where((c) => c.lastMessage == null)
              .toList();
          final withMessages = conversations
              .where((c) => c.lastMessage != null)
              .toList();

          return ListView(
            children: [
              // New Matches section
              if (newMatches.isNotEmpty) ...[
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Nuevos matches',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: newMatches.length,
                    itemBuilder: (_, i) =>
                        _MatchAvatar(
                          conversation: newMatches[i],
                          onTap: () => context.push(
                            '/chat/${newMatches[i].id}',
                            extra: newMatches[i],
                          ),
                        ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(),
                ),
              ],

              // Conversations
              if (withMessages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Conversaciones',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ...withMessages.map(
                (c) => _ConversationTile(
                  conversation: c,
                  onTap: () => context.push('/chat/${c.id}', extra: c),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MatchAvatar extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const _MatchAvatar({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2.5,
                    ),
                  ),
                  child: ClipOval(
                    child: conversation.petPhoto.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: conversation.petPhoto,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.pets,
                                color: AppColors.textHint),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: AppColors.matchGradient,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              conversation.petName,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.surfaceVariant,
            backgroundImage: conversation.petPhoto.isNotEmpty
                ? CachedNetworkImageProvider(conversation.petPhoto)
                : null,
            child: conversation.petPhoto.isEmpty
                ? const Icon(Icons.pets, color: AppColors.textHint)
                : null,
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${conversation.petName} · ${conversation.otherUserName}',
              style: TextStyle(
                fontWeight:
                    hasUnread ? FontWeight.w700 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          if (conversation.lastMessageAt != null)
            Text(
              timeago.format(conversation.lastMessageAt!, locale: 'es'),
              style: TextStyle(
                fontSize: 11,
                color: hasUnread
                    ? AppColors.primary
                    : AppColors.textHint,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation.lastMessage ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasUnread
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight:
                    hasUnread ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
          if (hasUnread)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyConversations extends StatelessWidget {
  const _EmptyConversations();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline,
              size: 70, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'Todavía no tenés matches',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Explorá mascotas y conseguí tu primer match',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
