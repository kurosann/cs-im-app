import '../models/channel_status.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/forward_channel_status.dart';
import '../models/platform_channel.dart';
import '../models/operator_profile.dart';
import '../models/translation_language.dart';
import 'chat_repository.dart';
import 'mock_data.dart';

/// 纯前端阶段的数据实现：使用原型演示数据，无网络请求。
class MockChatRepository implements ChatRepository {
  final List<Conversation> _conversations = List.of(mockConversations);
  final Map<String, List<ChatMessage>> _messages = {
    for (final MapEntry<String, List<ChatMessage>> entry
        in mockMessages.entries)
      entry.key: List.of(entry.value),
  };
  final List<ChannelStatus> _channels = const [
    ChannelStatus(
      platform: PlatformChannel.whatsapp,
      account: 'orange-support',
      online: true,
    ),
    ChannelStatus(
      platform: PlatformChannel.telegram,
      account: '@orange_support_bot',
      online: true,
    ),
    ChannelStatus(
      platform: PlatformChannel.messenger,
      account: 'orange-page',
      online: true,
    ),
  ];
  final OperatorProfile _profile = const OperatorProfile(
    name: '移动值守',
    accountId: 'mobile-duty-01',
    role: '客服专员',
    tenantName: '橙子科技',
  );
  final List<ForwardChannelStatus> _forwardChannels = const [
    ForwardChannelStatus(
      platform: PlatformChannel.telegram,
      displayName: '售后值班群',
      channelLabel: 'Telegram',
      target: '@orange_support_bot',
      state: ForwardChannelState.connected,
    ),
    ForwardChannelStatus(
      platform: PlatformChannel.whatsapp,
      displayName: '海外客服',
      channelLabel: 'WhatsApp',
      target: 'orange-support',
      state: ForwardChannelState.disconnected,
    ),
    ForwardChannelStatus(
      platform: PlatformChannel.unknown,
      displayName: '客服转发群',
      channelLabel: '飞书',
      target: '客服转发群',
      state: ForwardChannelState.connected,
    ),
  ];
  int _localMessageSeq = 1000;

  @override
  Future<List<Conversation>> fetchConversations() async =>
      List.unmodifiable(_conversations);

  @override
  Future<List<ChatMessage>> fetchMessages(String conversationId) async =>
      List.unmodifiable(_messages[conversationId] ?? const <ChatMessage>[]);

  @override
  Future<List<ChannelStatus>> fetchChannels() async =>
      List.unmodifiable(_channels);

  @override
  Future<List<ForwardChannelStatus>> fetchForwardChannels() async =>
      List.unmodifiable(_forwardChannels);

  @override
  Future<OperatorProfile> fetchProfile() async => _profile;

  @override
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final DateTime now = DateTime.now();
    final String clock =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
    final ChatMessage message = ChatMessage(
      id: 'local_${_localMessageSeq++}',
      text: text,
      sender: ChatSender.agent,
      time: clock,
    );
    _messages.putIfAbsent(conversationId, () => <ChatMessage>[]).add(message);
    return message;
  }

  @override
  Future<ChatMessage> sendAttachment({
    required String conversationId,
    required ChatMessageType type,
    String? mediaAsset,
    int? durationSeconds,
    String text = '',
  }) async {
    final DateTime now = DateTime.now();
    final String clock =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
    final ChatMessage message = ChatMessage(
      id: 'local_${_localMessageSeq++}',
      text: text,
      sender: ChatSender.agent,
      time: clock,
      type: type,
      mediaAsset: mediaAsset,
      durationSeconds: durationSeconds,
    );
    _messages.putIfAbsent(conversationId, () => <ChatMessage>[]).add(message);
    return message;
  }

  @override
  Future<void> markRead(String conversationId) async {
    final int index = _conversations.indexWhere(
      (Conversation c) => c.id == conversationId,
    );
    if (index >= 0) {
      _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
    }
  }

  @override
  Future<String> translate({
    required String text,
    required TranslationLanguage source,
    required TranslationLanguage target,
  }) => Future<String>.error(
    UnsupportedError('Mock repository has no server translation'),
  );
}
