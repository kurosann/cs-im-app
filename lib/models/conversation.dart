import 'platform_channel.dart';

enum ConversationStatus { waiting, ai, human }

extension ConversationStatusLabel on ConversationStatus {
  String get label => switch (this) {
    ConversationStatus.waiting => '待人工',
    ConversationStatus.ai => 'AI 已处理',
    ConversationStatus.human => '人工处理中',
  };
}

class Conversation {
  const Conversation({
    required this.id,
    required this.name,
    required this.channel,
    required this.lastMessage,
    required this.time,
    required this.status,
    this.unreadCount = 0,
    this.needsReply = false,
    this.channelLogoUrl,
    this.assignee = '未认领',
    this.forwardTargets = const <String>[],
    this.updatedAt,
  });

  final String id;
  final String name;
  final PlatformChannel channel;

  /// 业务方上传的自定义渠道 logo；为空时使用系统内置图标。
  final String? channelLogoUrl;

  final String lastMessage;
  final String time;
  final ConversationStatus status;
  final int unreadCount;
  final bool needsReply;

  /// 当前负责人；未分配时为「未认领」。
  final String assignee;

  /// 该会话配置的转发去向（转发渠道名称）。
  final List<String> forwardTargets;

  final DateTime? updatedAt;

  String get initial => name.isEmpty ? '?' : name.substring(0, 1);

  Conversation copyWith({
    String? lastMessage,
    String? time,
    int? unreadCount,
    bool? needsReply,
  }) {
    return Conversation(
      id: id,
      name: name,
      channel: channel,
      channelLogoUrl: channelLogoUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      status: status,
      unreadCount: unreadCount ?? this.unreadCount,
      needsReply: needsReply ?? this.needsReply,
      assignee: assignee,
      forwardTargets: forwardTargets,
      updatedAt: updatedAt,
    );
  }
}
