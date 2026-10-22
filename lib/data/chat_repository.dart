import '../models/channel_status.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/delivery_record.dart';
import '../models/forward_channel_status.dart';
import '../models/operator_profile.dart';
import '../models/translation_language.dart';

/// 数据访问边界。
///
/// UI 通过状态层使用本接口，由 Mock 或 cs-im-server 实现。
abstract interface class ChatRepository {
  Future<void> login({required String account, required String password});

  Future<void> logout();

  Future<List<Conversation>> fetchConversations({String keyword = ''});

  Future<void> assignConversation({
    required String conversationId,
    required String assignee,
  });

  Future<void> closeConversation({
    required String conversationId,
    String reason = '',
  });

  Future<DeliveryRecord> forwardConversation({
    required String conversationId,
    required String channelId,
    String messageId = '',
  });

  Future<List<DeliveryRecord>> fetchDeliveries(String conversationId);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

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
