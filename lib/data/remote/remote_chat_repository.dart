import '../../models/channel_status.dart';
import '../../models/chat_message.dart';
import '../../models/conversation.dart';
import '../../models/forward_channel_status.dart';
import '../../models/operator_profile.dart';
import '../chat_repository.dart';

/// 后端对接占位实现。
///
/// V1 纯前端阶段不启用；接入 cs-im-route 时按下方注释逐项实现，
/// UI / AppStore 不需要改动。
class RemoteChatRepository implements ChatRepository {
  RemoteChatRepository({required this.baseUrl});

  final String baseUrl;

  @override
  Future<List<Conversation>> fetchConversations() async {
    // TODO(backend): GET ${baseUrl}/api/v1/conversations
    throw UnimplementedError('后端 API 尚未接入：GET /api/v1/conversations');
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    // TODO(backend): GET ${baseUrl}/api/v1/conversations/{conversationId}/messages
    throw UnimplementedError('后端 API 尚未接入：GET /messages');
  }

  @override
  Future<List<ChannelStatus>> fetchChannels() async {
    // TODO(backend): GET ${baseUrl}/api/v1/apps（业务渠道状态）
    throw UnimplementedError('后端 API 尚未接入：GET /api/v1/apps');
  }

  @override
  Future<List<ForwardChannelStatus>> fetchForwardChannels() async {
    // TODO(backend): GET ${baseUrl}/api/v1/channels（转发渠道账号与状态）
    throw UnimplementedError('后端 API 尚未接入：GET /api/v1/channels');
  }

  @override
  Future<OperatorProfile> fetchProfile() async {
    // TODO(backend): GET ${baseUrl}/api/v1/me（账号信息，接口方案待定稿）
    throw UnimplementedError('后端 API 尚未接入：GET /api/v1/me');
  }

  @override
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    // TODO(backend): POST ${baseUrl}/api/v1/messages
    throw UnimplementedError('后端 API 尚未接入：POST /api/v1/messages');
  }

  @override
  Future<ChatMessage> sendAttachment({
    required String conversationId,
    required ChatMessageType type,
    String? mediaAsset,
    int? durationSeconds,
    String text = '',
  }) async {
    // TODO(backend): 先上传媒体（POST /api/v1/files），再 POST /api/v1/messages
    throw UnimplementedError('后端 API 尚未接入：媒体上传');
  }

  @override
  Future<void> markRead(String conversationId) async {
    // TODO(backend): 会话已读回执（具体接口以接口方案定稿为准）
    throw UnimplementedError('后端 API 尚未接入：会话已读');
  }
}
