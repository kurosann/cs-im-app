import 'package:flutter/material.dart';

import '../models/channel_status.dart';
import '../models/conversation.dart';
import '../state/app_scope.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/platform_logo.dart';
import 'chat_page.dart';

class ChannelConversationsPage extends StatelessWidget {
  const ChannelConversationsPage({super.key, required this.channel});

  final ChannelStatus channel;

  @override
  Widget build(BuildContext context) {
    final AppStore store = AppScope.of(context);
    final List<Conversation> items = store.conversations
        .where((Conversation c) => c.channel == channel.platform)
        .toList();
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.line)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 20,
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.ink,
                        ),
                      ),
                      PlatformLogo(channel: channel.platform, size: 38),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              channel.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              channel.account,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: channel.online
                              ? AppColors.emerald50
                              : AppColors.lavender,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          channel.online ? '在线' : '离线',
                          style: TextStyle(
                            fontSize: 12,
                            color: channel.online
                                ? AppColors.emerald600
                                : AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '共 ${items.length} 个会话',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            '该渠道暂无会话',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount: items.length,
                          separatorBuilder: (BuildContext context, int index) =>
                              Divider(height: 1, color: AppColors.line),
                          itemBuilder: (BuildContext context, int index) {
                            final Conversation conversation = items[index];
                            return ConversationTile(
                              conversation: conversation,
                              onTap: () {
                                store.markRead(conversation.id);
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (BuildContext context) => ChatPage(
                                      conversationId: conversation.id,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
