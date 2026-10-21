import 'package:http/http.dart' as http;

import '../../models/channel_status.dart';
import '../../models/chat_message.dart';
import '../../models/conversation.dart';
import '../../models/forward_channel_status.dart';
import '../../models/operator_profile.dart';
import '../../models/platform_channel.dart';
import '../../models/translation_language.dart';
import '../chat_repository.dart';
import 'im_api_client.dart';

/// cs-im-server admin API used by the duty app.
///
/// Business token on `/admin/v1`. There is no password login and no media
/// upload; the password field is the bearer token, and media must already
/// be an absolute http(s) URL.
class RemoteChatRepository implements ChatRepository {
  RemoteChatRepository({
    required String baseUrl,
    http.Client? client,
    String accessToken = '',
    this._operatorId = '',
  }) : _client = ImApiClient(
         baseUrl: baseUrl,
         token: accessToken,
         client: client,
       );

  final ImApiClient _client;
  String _operatorId;
  String? _tenantId;
  final Map<String, List<_TrackedMessage>> _messages =
      <String, List<_TrackedMessage>>{};

  Future<void> connect({required String account, required String token}) async {
    final String previousToken = _client.token;
    final String previousOperator = _operatorId;
    final String trimmedToken = token.trim();
    final String trimmedAccount = account.trim();
    if (trimmedToken.isEmpty) {
      throw ImApiException('请输入访问 Token');
    }
    if (trimmedAccount.isEmpty) {
      throw ImApiException('请输入值守账号');
    }
    _client.token = trimmedToken;
    _operatorId = trimmedAccount;
    try {
      await _client.get('/admin/v1/conversations');
    } catch (error) {
      _client.token = previousToken;
      _operatorId = previousOperator;
      rethrow;
    }
  }

  @override
  Future<List<Conversation>> fetchConversations() async {
    final List<Map<String, dynamic>> rows = asJsonMaps(
      await _client.get('/admin/v1/conversations'),
    );
    _messages.clear();
    final List<Conversation> conversations = await Future.wait(
      rows.map(_loadConversation),
    );
    conversations.sort((Conversation a, Conversation b) {
      return _sortKey(b).compareTo(_sortKey(a));
    });
    return conversations;
  }

  Future<Conversation> _loadConversation(Map<String, dynamic> row) async {
    final String id = row['conversationId']?.toString() ?? '';
    final String customerId = row['customerId']?.toString() ?? '';
    Map<String, dynamic>? customer;
    if (customerId.isNotEmpty) {
      try {
        customer = asJsonMap(
          await _client.get(
            '/admin/v1/customers/${Uri.encodeComponent(customerId)}',
          ),
        );
      } on ImApiException {
        customer = null;
      }
    }
    List<_TrackedMessage> messages = const <_TrackedMessage>[];
    if (id.isNotEmpty) {
      try {
        messages = await _loadMessages(id);
      } on ImApiException {
        messages = const <_TrackedMessage>[];
      }
    }
    return _conversationFrom(row, customer, messages);
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    final List<_TrackedMessage>? cached = _messages[conversationId];
    if (cached != null) {
      return cached
          .map((_TrackedMessage item) => item.message)
          .toList(growable: false);
    }
    final List<_TrackedMessage> loaded = await _loadMessages(conversationId);
    return loaded
        .map((_TrackedMessage item) => item.message)
        .toList(growable: false);
  }

  Future<List<_TrackedMessage>> _loadMessages(String conversationId) async {
    final List<Map<String, dynamic>> rows = asJsonMaps(
      await _client.get('/admin/v1/conversations/$conversationId/messages'),
    );
    final List<_TrackedMessage> messages = rows.map(_messageFrom).toList();
    _messages[conversationId] = messages;
    return messages;
  }

  @override
  Future<List<ChannelStatus>> fetchChannels() async {
    final List<Map<String, dynamic>> rows = asJsonMaps(
      await _client.get('/admin/v1/apps'),
    );
    if (rows.isNotEmpty) {
      final String? tenantId = rows.first['tenantId']?.toString();
      if (tenantId != null && tenantId.isNotEmpty) {
        _tenantId = tenantId;
      }
    }
    return rows
        .map((Map<String, dynamic> row) {
          final String kind = row['kind']?.toString() ?? '';
          final String displayName = row['displayName']?.toString() ?? '';
          final String serviceKey = row['serviceKey']?.toString() ?? '';
          return ChannelStatus(
            platform: platformFromLabel(kind.isEmpty ? displayName : kind),
            account: serviceKey.isEmpty ? displayName : serviceKey,
            online: _appOnline(row),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<ForwardChannelStatus>> fetchForwardChannels() async {
    final List<Map<String, dynamic>> rows = asJsonMaps(
      await _client.get('/admin/v1/channels'),
    );
    return rows
        .map((Map<String, dynamic> row) {
          final String type = row['type']?.toString() ?? '';
          final PlatformChannel platform = platformFromLabel(type);
          final String endpoint = row['endpoint']?.toString() ?? '';
          final String name = row['name']?.toString() ?? '';
          return ForwardChannelStatus(
            platform: platform,
            displayName: name.isEmpty ? type : name,
            channelLabel: platform == PlatformChannel.unknown
                ? (type.isEmpty ? '转发渠道' : type)
                : platform.label,
            target: endpoint.isEmpty ? name : endpoint,
            state: _forwardState(row),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<OperatorProfile> fetchProfile() async {
    if (_tenantId == null || _tenantId!.isEmpty) {
      try {
        final List<Map<String, dynamic>> apps = asJsonMaps(
          await _client.get('/admin/v1/apps'),
        );
        if (apps.isNotEmpty) {
          _tenantId = apps.first['tenantId']?.toString();
        }
      } on ImApiException {
        // Tenant is optional for the profile card.
      }
    }
    final String account = _operatorId.trim();
    final String tenant = _tenantId?.trim() ?? '';
    return OperatorProfile(
      name: account.isEmpty ? '值守' : account,
      accountId: account.isEmpty ? 'unknown' : account,
      role: '客服专员',
      tenantName: tenant.isEmpty ? '当前租户' : tenant,
    );
  }

  @override
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final Map<String, dynamic> created = asJsonMap(
      await _client.post(
        '/admin/v1/messages',
        body: <String, dynamic>{
          'conversationId': conversationId,
          'sender': <String, dynamic>{'role': 'agent', 'id': _senderId()},
          'type': 'text',
          'text': text,
        },
      ),
    );
    final _TrackedMessage message = _messageFrom(created);
    _messages
        .putIfAbsent(conversationId, () => <_TrackedMessage>[])
        .add(message);
    return message.message;
  }

  @override
  Future<ChatMessage> sendAttachment({
    required String conversationId,
    required ChatMessageType type,
    String? mediaAsset,
    int? durationSeconds,
    String text = '',
  }) async {
    final String serverType = switch (type) {
      ChatMessageType.image => 'image',
      ChatMessageType.video => 'video',
      ChatMessageType.file => 'file',
      ChatMessageType.audio => throw ImApiException('服务端不接收语音消息'),
      ChatMessageType.text => 'text',
    };
    final String url = mediaAsset?.trim() ?? '';
    final Uri? parsed = Uri.tryParse(url);
    if (parsed == null ||
        (parsed.scheme != 'http' && parsed.scheme != 'https') ||
        parsed.host.isEmpty) {
      throw ImApiException('服务端只接收 http 或 https 媒体地址，没有上传接口');
    }
    final Map<String, dynamic> content = <String, dynamic>{'url': url};
    if (durationSeconds != null) {
      content['duration'] = durationSeconds;
    }
    if (text.trim().isNotEmpty) {
      content['fileName'] = text.trim();
    }
    final Map<String, dynamic> created = asJsonMap(
      await _client.post(
        '/admin/v1/messages',
        body: <String, dynamic>{
          'conversationId': conversationId,
          'sender': <String, dynamic>{'role': 'agent', 'id': _senderId()},
          'type': serverType,
          'text': text,
          'content': content,
        },
      ),
    );
    final _TrackedMessage message = _messageFrom(created);
    _messages
        .putIfAbsent(conversationId, () => <_TrackedMessage>[])
        .add(message);
    return message.message;
  }

  @override
  Future<void> markRead(String conversationId) async {
    List<_TrackedMessage> messages =
        _messages[conversationId] ?? await _loadMessages(conversationId);
    for (final _TrackedMessage item in messages) {
      if (item.senderRole != 'customer' || item.status == 'read') {
        continue;
      }
      final Map<String, dynamic> updated = asJsonMap(
        await _client.post(
          '/admin/v1/messages/${item.message.id}/status',
          body: const <String, dynamic>{'status': 'read'},
        ),
      );
      item.status = updated['status']?.toString() ?? 'read';
    }
  }

  @override
  Future<String> translate({
    required String text,
    required TranslationLanguage source,
    required TranslationLanguage target,
  }) async {
    final Map<String, dynamic> response = asJsonMap(
      await _client.post(
        '/admin/v1/translate',
        body: <String, dynamic>{
          'text': text,
          'sourceLang': source.code,
          'targetLang': target.code,
        },
      ),
    );
    final String translated = response['text']?.toString().trim() ?? '';
    if (translated.isEmpty) {
      throw ImApiException('服务器返回了空译文');
    }
    return translated;
  }

  void close() {
    _client.close();
  }

  String _senderId() {
    final String id = _operatorId.trim();
    if (id.isEmpty) {
      throw ImApiException('缺少值守账号，无法发送消息');
    }
    return id;
  }
}

class _TrackedMessage {
  _TrackedMessage({
    required this.message,
    required this.status,
    required this.senderRole,
    required this.sortAt,
  });

  final ChatMessage message;
  String status;
  final String senderRole;
  final DateTime? sortAt;
}

Conversation _conversationFrom(
  Map<String, dynamic> row,
  Map<String, dynamic>? customer,
  List<_TrackedMessage> messages,
) {
  final String customerName = customer?['name']?.toString().trim() ?? '';
  final String subject = row['subject']?.toString().trim() ?? '';
  final String customerId = row['customerId']?.toString() ?? '';
  final String channelRaw = row['channel']?.toString().trim().isNotEmpty == true
      ? row['channel'].toString()
      : (customer?['channel']?.toString() ?? '');
  final String assignee = row['assignee']?.toString().trim() ?? '';
  final String status = row['status']?.toString() ?? '';
  final String forwardedTo = row['forwardedTo']?.toString().trim() ?? '';
  final _TrackedMessage? latest = messages.isEmpty ? null : messages.last;
  final int unread = messages
      .where(
        (_TrackedMessage item) =>
            item.senderRole == 'customer' && item.status != 'read',
      )
      .length;
  final DateTime? updatedAt = DateTime.tryParse(
    row['updatedAt']?.toString() ?? '',
  );
  return Conversation(
    id: row['conversationId']?.toString() ?? '',
    name: customerName.isNotEmpty
        ? customerName
        : (subject.isNotEmpty ? subject : customerId),
    channel: platformFromLabel(channelRaw),
    lastMessage: latest == null ? subject : _summary(latest.message),
    time: formatServerTime(
      latest?.sortAt?.toUtc().toIso8601String() ?? row['updatedAt']?.toString(),
    ),
    status: _conversationStatus(status: status, assignee: assignee),
    unreadCount: unread,
    needsReply:
        status != 'closed' &&
        latest != null &&
        latest.senderRole == 'customer' &&
        latest.status != 'read',
    assignee: assignee.isEmpty ? '未认领' : assignee,
    forwardTargets: forwardedTo.isEmpty
        ? const <String>[]
        : <String>[forwardedTo],
    updatedAt: updatedAt ?? latest?.sortAt,
  );
}

_TrackedMessage _messageFrom(Map<String, dynamic> row) {
  final Map<String, dynamic> sender = row['sender'] is Map
      ? Map<String, dynamic>.from(row['sender'] as Map)
      : const <String, dynamic>{};
  final Map<String, dynamic>? content = row['content'] is Map
      ? Map<String, dynamic>.from(row['content'] as Map)
      : null;
  final String role = sender['role']?.toString() ?? '';
  final String type = row['type']?.toString() ?? 'text';
  final String receivedAt =
      row['receivedAt']?.toString() ?? row['createdAt']?.toString() ?? '';
  final int? duration = _asInt(content?['duration']);
  return _TrackedMessage(
    message: ChatMessage(
      id: row['messageId']?.toString() ?? '',
      text: row['text']?.toString() ?? '',
      sender: _senderFrom(role),
      time: formatServerTime(receivedAt),
      type: _messageType(type),
      mediaAsset: content?['url']?.toString(),
      durationSeconds: duration,
    ),
    status: row['status']?.toString() ?? 'received',
    senderRole: role,
    sortAt: DateTime.tryParse(receivedAt),
  );
}

ConversationStatus _conversationStatus({
  required String status,
  required String assignee,
}) {
  if (status == 'open' && assignee.isEmpty) {
    return ConversationStatus.waiting;
  }
  return ConversationStatus.human;
}

ChatSender _senderFrom(String role) {
  return switch (role) {
    'customer' => ChatSender.customer,
    'ai' => ChatSender.ai,
    'system' => ChatSender.system,
    _ => ChatSender.agent,
  };
}

ChatMessageType _messageType(String type) {
  return switch (type) {
    'image' => ChatMessageType.image,
    'video' => ChatMessageType.video,
    'audio' => ChatMessageType.audio,
    'file' => ChatMessageType.file,
    _ => ChatMessageType.text,
  };
}

String _summary(ChatMessage message) {
  final String text = message.text.trim();
  if (text.isNotEmpty) {
    return text;
  }
  return switch (message.type) {
    ChatMessageType.image => '[图片]',
    ChatMessageType.video => '[视频]',
    ChatMessageType.audio => '[语音]',
    ChatMessageType.file => '[文件]',
    ChatMessageType.text => '',
  };
}

bool _appOnline(Map<String, dynamic> app) {
  if (app['status']?.toString() != 'active') {
    return false;
  }
  final String raw = app['leaseExpiresAt']?.toString() ?? '';
  if (raw.isEmpty) {
    return true;
  }
  final DateTime? expires = DateTime.tryParse(raw);
  if (expires == null) {
    return true;
  }
  return expires.isAfter(DateTime.now());
}

ForwardChannelState _forwardState(Map<String, dynamic> channel) {
  final String endpoint = channel['endpoint']?.toString().trim() ?? '';
  if (endpoint.isEmpty) {
    return ForwardChannelState.unconfigured;
  }
  if (channel['status']?.toString() == 'active') {
    return ForwardChannelState.connected;
  }
  return ForwardChannelState.disconnected;
}

String _sortKey(Conversation conversation) {
  return conversation.updatedAt?.toUtc().toIso8601String() ?? '';
}

int? _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

PlatformChannel platformFromLabel(String? raw) {
  final String value = (raw ?? '').trim().toLowerCase();
  if (value.isEmpty) {
    return PlatformChannel.unknown;
  }
  const Map<String, PlatformChannel> exact = <String, PlatformChannel>{
    'whatsapp': PlatformChannel.whatsapp,
    'wa': PlatformChannel.whatsapp,
    'telegram': PlatformChannel.telegram,
    'tg': PlatformChannel.telegram,
    'instagram': PlatformChannel.instagram,
    'ig': PlatformChannel.instagram,
    'twitter': PlatformChannel.x,
    'x': PlatformChannel.x,
    'facebook': PlatformChannel.facebook,
    'fb': PlatformChannel.facebook,
    'meta': PlatformChannel.meta,
    'messenger': PlatformChannel.messenger,
    'tiktok': PlatformChannel.tiktok,
    'discord': PlatformChannel.discord,
    'line': PlatformChannel.line,
    'teams': PlatformChannel.teams,
    'zalo': PlatformChannel.zalo,
  };
  final PlatformChannel? matched = exact[value];
  if (matched != null) {
    return matched;
  }
  for (final MapEntry<String, PlatformChannel> entry in exact.entries) {
    if (entry.key.length < 3) {
      continue;
    }
    if (value.contains(entry.key)) {
      return entry.value;
    }
  }
  return PlatformChannel.unknown;
}

String formatServerTime(String? raw) {
  if (raw == null || raw.isEmpty) {
    return '';
  }
  final DateTime? parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw;
  }
  final DateTime local = parsed.toLocal();
  final String clock =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  final DateTime now = DateTime.now();
  final bool sameDay =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  if (sameDay) {
    return clock;
  }
  return '${local.month}/${local.day} $clock';
}
