import '../models/channel_status.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/forward_channel_status.dart';
import '../models/operator_profile.dart';

/// 数据访问边界。
///
/// UI 与状态层只依赖本接口：当前使用 [MockChatRepository]，
/// 接入 cs-im-route 后端后替换为 RemoteChatRepository 即可。
abstract interface class ChatRepository {
  Future<List<Conversation>> fetchConversations();

  Future<List<ChatMessage>> fetchMessages(String conversationId);

  Future<List<ChannelStatus>> fetchChannels();

  Future<List<ForwardChannelStatus>> fetchForwardChannels();

  Future<OperatorProfile> fetchProfile();

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String text,
  });

  Future<ChatMessage> sendAttachment({
    required String conversationId,
    required ChatMessageType type,
    String? mediaAsset,
    int? durationSeconds,
    String text = '',
  });

  Future<void> markRead(String conversationId);
}
