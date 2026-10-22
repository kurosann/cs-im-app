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
    this.closed = false,
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

  /// 服务端状态为 closed 时为 true，值守列表不再展示。
  final bool closed;

  String get initial => name.isEmpty ? '?' : name.substring(0, 1);

  Conversation copyWith({
    String? lastMessage,
    String? time,
    ConversationStatus? status,
    int? unreadCount,
    bool? needsReply,
    String? assignee,
    List<String>? forwardTargets,
    bool? closed,
  }) {
    return Conversation(
      id: id,
      name: name,
      channel: channel,
      channelLogoUrl: channelLogoUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      status: status ?? this.status,
      unreadCount: unreadCount ?? this.unreadCount,
      needsReply: needsReply ?? this.needsReply,
      assignee: assignee ?? this.assignee,
      forwardTargets: forwardTargets ?? this.forwardTargets,
      updatedAt: updatedAt,
      closed: closed ?? this.closed,
    );
  }
}
