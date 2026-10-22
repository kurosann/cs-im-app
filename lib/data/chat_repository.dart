import '../models/channel_status.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/forward_channel_status.dart';
import '../models/operator_profile.dart';
import '../models/translation_language.dart';

/// 数据访问边界。
///
/// UI 通过状态层使用本接口，由 Mock 或 cs-im-server 实现。
abstract interface class ChatRepository {
  Future<void> login({required String account, required String password});

  Future<void> logout();

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

  Future<String> translate({
    required String text,
    required TranslationLanguage source,
    required TranslationLanguage target,
  });
}
