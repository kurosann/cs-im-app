import 'package:flutter/material.dart';

import '../models/conversation.dart';
import '../state/app_scope.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/conversation_tile.dart';
import 'chat_page.dart';

class DutyPage extends StatelessWidget {
  const DutyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStore store = AppScope.of(context);
    final List<Conversation> items = store.filteredConversations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '橙子科技',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '移动值守',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const _CircleIcon(icon: Icons.search_rounded),
            ],
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            itemCount: AppStore.filters.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(width: 8),
            itemBuilder: (BuildContext context, int index) {
              final bool active = store.filterIndex == index;
              return GestureDetector(
                onTap: () => store.setFilter(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: active ? AppColors.accent : AppColors.lavender,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    AppStore.filters[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: active ? AppColors.onAccent : AppColors.inkSoft,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  key: const ValueKey('duty-conversation-list'),
                  padding: const EdgeInsets.only(bottom: 96),
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
                            builder: (BuildContext context) =>
                                ChatPage(conversationId: conversation.id),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.lavender,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: AppColors.inkSoft),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: AppColors.muted),
          SizedBox(height: 10),
          Text(
            '当前筛选下暂无会话',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
