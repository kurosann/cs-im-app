import 'dart:convert';

import 'package:cs_im_app/data/remote/im_api_client.dart';
import 'package:cs_im_app/data/remote/remote_chat_repository.dart';
import 'package:cs_im_app/models/chat_message.dart';
import 'package:cs_im_app/models/conversation.dart';
import 'package:cs_im_app/models/forward_channel_status.dart';
import 'package:cs_im_app/models/platform_channel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('远程仓库按 admin 接口映射会话、消息、渠道和已读', () async {
    final List<http.Request> requests = <http.Request>[];
    final RemoteChatRepository repository = RemoteChatRepository(
      baseUrl: 'http://127.0.0.1:19091',
      client: MockClient((http.Request request) async {
        requests.add(request);
        expect(request.headers['Authorization'], 'Bearer dev-access-token');
        final String path = request.url.path;
        if (request.method == 'GET' && path == '/admin/v1/conversations') {
          return _ok(<Map<String, dynamic>>[
            _conversation(id: 'conv_old', at: '2026-10-20T01:00:00Z'),
            _conversation(id: 'conv_1', at: '2026-10-21T01:02:03Z'),
          ]);
        }
        if (request.method == 'GET' && path == '/admin/v1/customers/cus_1') {
          return _ok(<String, dynamic>{
            'customerId': 'cus_1',
            'name': '李然',
            'channel': 'whatsapp',
            'status': 'active',
          });
        }
        if (request.method == 'GET' &&
            path == '/admin/v1/conversations/conv_1/messages') {
          return _ok(<Map<String, dynamic>>[
            _message(id: 'msg_1', conversationId: 'conv_1'),
          ]);
        }
        if (request.method == 'GET' &&
            path == '/admin/v1/conversations/conv_old/messages') {
          return _ok(const <Map<String, dynamic>>[]);
        }
        if (request.method == 'GET' && path == '/admin/v1/apps') {
          return _ok(<Map<String, dynamic>>[
            <String, dynamic>{
              'appId': 'app_1',
              'tenantId': 'dev-tenant',
              'serviceKey': 'orange-support',
              'displayName': 'WhatsApp 客服',
              'kind': 'whatsapp',
              'status': 'active',
              'leaseExpiresAt': '2000-01-01T00:00:00Z',
            },
          ]);
        }
        if (request.method == 'GET' && path == '/admin/v1/channels') {
          return _ok(<Map<String, dynamic>>[
            <String, dynamic>{
              'channelId': 'ch_1',
              'name': '售后值班群',
              'type': 'telegram',
              'endpoint': '@orange_support_bot',
              'status': 'active',
            },
            <String, dynamic>{
              'channelId': 'ch_2',
              'name': '未配置渠道',
              'type': 'feishu',
              'endpoint': '',
              'status': 'disabled',
            },
          ]);
        }
        if (request.method == 'POST' && path == '/admin/v1/messages') {
          final Map<String, dynamic> body =
              jsonDecode(request.body) as Map<String, dynamic>;
          return _ok(<String, dynamic>{
            'messageId': 'msg_new',
            'conversationId': body['conversationId'],
            'sender': body['sender'],
            'type': body['type'],
            'text': body['text'],
            'content': body['content'],
            'status': 'received',
            'receivedAt': '2026-10-21T02:00:00Z',
          });
        }
        if (request.method == 'POST' &&
            path == '/admin/v1/messages/msg_1/status') {
          final Map<String, dynamic> body =
              jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['status'], 'read');
          return _ok(<String, dynamic>{'messageId': 'msg_1', 'status': 'read'});
        }
        return http.Response(
          jsonEncode(<String, dynamic>{'code': 'NOT_FOUND', 'message': path}),
          404,
        );
      }),
    );

    await repository.connect(account: 'duty-1', token: 'dev-access-token');
    final List<Conversation> conversations = await repository
        .fetchConversations();

    expect(conversations.map((Conversation item) => item.id), [
      'conv_1',
      'conv_old',
    ]);
    final Conversation current = conversations.first;
    expect(current.name, '李然');
    expect(current.channel, PlatformChannel.whatsapp);
    expect(current.status, ConversationStatus.waiting);
    expect(current.lastMessage, 'hello');
    expect(current.unreadCount, 1);
    expect(current.needsReply, isTrue);
    expect(current.assignee, '未认领');
    expect(current.time, formatServerTime('2026-10-21T01:02:03Z'));

    final List<ChatMessage> messages = await repository.fetchMessages('conv_1');
    expect(messages, hasLength(1));
    expect(messages.single.sender, ChatSender.customer);
    expect(
      requests
          .where(
            (http.Request request) =>
                request.url.path == '/admin/v1/conversations/conv_1/messages',
          )
          .length,
      1,
    );

    final ChatMessage sent = await repository.sendMessage(
      conversationId: 'conv_1',
      text: '收到',
    );
    expect(sent.sender, ChatSender.agent);
    expect(sent.text, '收到');
    final http.Request sendRequest = requests.lastWhere(
      (http.Request request) =>
          request.method == 'POST' && request.url.path == '/admin/v1/messages',
    );
    expect(jsonDecode(sendRequest.body), <String, dynamic>{
      'conversationId': 'conv_1',
      'sender': <String, dynamic>{'role': 'agent', 'id': 'duty-1'},
      'type': 'text',
      'text': '收到',
    });

    await expectLater(
      repository.sendAttachment(
        conversationId: 'conv_1',
        type: ChatMessageType.image,
        mediaAsset: 'assets/media/order-screenshot.png',
      ),
      throwsA(isA<ImApiException>()),
    );
    final ChatMessage image = await repository.sendAttachment(
      conversationId: 'conv_1',
      type: ChatMessageType.image,
      mediaAsset: 'https://cdn.example.com/a.png',
    );
    expect(image.type, ChatMessageType.image);
    expect(image.mediaAsset, 'https://cdn.example.com/a.png');

    await repository.markRead('conv_1');
    expect(
      requests.any(
        (http.Request request) =>
            request.method == 'POST' &&
            request.url.path == '/admin/v1/messages/msg_1/status',
      ),
      isTrue,
    );

    expect((await repository.fetchChannels()).single.online, isFalse);
    expect((await repository.fetchChannels()).single.account, 'orange-support');
    final forward = await repository.fetchForwardChannels();
    expect(forward.first.state, ForwardChannelState.connected);
    expect(forward.first.platform, PlatformChannel.telegram);
    expect(forward.last.state, ForwardChannelState.unconfigured);
    expect((await repository.fetchProfile()).tenantName, 'dev-tenant');
    expect((await repository.fetchProfile()).accountId, 'duty-1');
    repository.close();
  });

  test('错误 Token 不能进入工作区', () async {
    final RemoteChatRepository repository = RemoteChatRepository(
      baseUrl: 'http://127.0.0.1:19091/',
      client: MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'code': 'UNAUTHORIZED',
            'message': 'invalid account token',
          }),
          401,
        );
      }),
    );
    await expectLater(
      repository.connect(account: 'duty-1', token: 'bad'),
      throwsA(
        isA<ImApiException>().having(
          (ImApiException error) => error.message,
          'message',
          'invalid account token',
        ),
      ),
    );
    repository.close();
  });
}

http.Response _ok(Object data) {
  return http.Response(
    jsonEncode(<String, dynamic>{'code': 'OK', 'data': data}),
    200,
    headers: <String, String>{'content-type': 'application/json'},
  );
}

Map<String, dynamic> _conversation({required String id, required String at}) {
  return <String, dynamic>{
    'conversationId': id,
    'appId': 'app_1',
    'customerId': 'cus_1',
    'channel': 'whatsapp',
    'subject': '订单',
    'status': 'open',
    'updatedAt': at,
  };
}

Map<String, dynamic> _message({
  required String id,
  required String conversationId,
}) {
  return <String, dynamic>{
    'messageId': id,
    'seq': 1,
    'conversationId': conversationId,
    'customerId': 'cus_1',
    'sender': <String, dynamic>{'role': 'customer', 'id': 'cus_1'},
    'type': 'text',
    'text': 'hello',
    'status': 'received',
    'receivedAt': '2026-10-21T01:02:03Z',
  };
}
