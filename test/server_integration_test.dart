import 'dart:convert';

import 'package:cs_im_app/data/remote/im_api_client.dart';
import 'package:cs_im_app/data/remote/remote_chat_repository.dart';
import 'package:cs_im_app/models/chat_message.dart';
import 'package:cs_im_app/models/conversation.dart';
import 'package:cs_im_app/models/translation_language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('账号密码换取客服会话，使用服务端用户 ID 发送消息并撤销会话', () async {
    final List<http.Request> requests = <http.Request>[];
    final RemoteChatRepository repository = RemoteChatRepository(
      baseUrl: 'https://server.example',
      client: MockClient((http.Request request) async {
        requests.add(request);
        switch (request.url.path) {
          case '/api/v1/auth/login':
            expect(request.headers.containsKey('Authorization'), isFalse);
            expect(jsonDecode(request.body), <String, dynamic>{
              'identifier': 'duty@example.com',
              'password': 'password with spaces ',
            });
            return _ok(_session());
          case '/api/v1/auth/me':
            expect(request.headers['Authorization'], 'Bearer staff-session');
            return _ok(<String, dynamic>{
              'userKey': 'user_42',
              'tenantId': 'tenant_1',
              'kind': 'human',
              'scopes': <String>['gateway:admin'],
            });
          case '/admin/v1/messages':
            final Map<String, dynamic> body = asJsonMap(
              jsonDecode(request.body),
            );
            expect(asJsonMap(body['sender'])['id'], 'user_42');
            expect(request.headers['Authorization'], 'Bearer staff-session');
            return _ok(<String, dynamic>{
              ...body,
              'messageId': 'msg_1',
              'receivedAt': '2026-10-22T01:00:00Z',
            });
          case '/api/v1/auth/logout':
            expect(request.headers['Authorization'], 'Bearer staff-session');
            return _ok(null);
          default:
            fail('Unexpected request: ${request.url.path}');
        }
      }),
    );
    addTearDown(repository.close);
    await repository.login(
      account: ' duty@example.com ',
      password: 'password with spaces ',
    );
    final profile = await repository.fetchProfile();
    expect(profile.name, '值守客服');
    expect(profile.accountId, 'duty');
    expect(profile.tenantName, 'tenant_1');
    expect(profile.role, '管理员');
    final ChatMessage message = await repository.sendMessage(
      conversationId: 'conv_1',
      text: '收到',
    );
    expect(message.sender, ChatSender.agent);
    await repository.logout();
    final int requestCount = requests.length;
    await expectLater(
      repository.fetchChannels(),
      throwsA(isA<ImApiException>()),
    );
    expect(requests.length, requestCount);
  });

  test('没有值守权限的登录会撤销新 Token 并拒绝进入工作区', () async {
    bool revoked = false;
    final RemoteChatRepository repository = RemoteChatRepository(
      baseUrl: 'https://server.example',
      client: MockClient((http.Request request) async {
        switch (request.url.path) {
          case '/api/v1/auth/login':
            return _ok(_session());
          case '/api/v1/auth/me':
            return _ok(<String, dynamic>{
              'kind': 'human',
              'scopes': <String>['conversation:read'],
            });
          case '/api/v1/auth/logout':
            revoked = true;
            return _ok(null);
          default:
            fail('Unexpected request: ${request.url.path}');
        }
      }),
    );
    addTearDown(repository.close);
    await expectLater(
      repository.login(account: 'duty', password: 'password'),
      throwsA(isA<ImApiException>()),
    );
    expect(revoked, isTrue);
    await expectLater(
      repository.fetchChannels(),
      throwsA(isA<ImApiException>()),
    );
  });

  test('分页会话读取所有页并展示服务端未读、回复状态及 AI 消息', () async {
    final List<String?> pages = <String?>[];
    final RemoteChatRepository repository = RemoteChatRepository(
      baseUrl: 'https://server.example',
      accessToken: 'staff-session',
      client: MockClient((http.Request request) async {
        if (request.url.path == '/admin/v1/conversations') {
          pages.add(request.url.queryParameters['page']);
          expect(request.url.queryParameters['pageSize'], '100');
          final bool first = request.url.queryParameters['page'] == '1';
          return _ok(<String, dynamic>{
            'total': 2,
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'conversationId': first ? 'conv_ai' : 'conv_customer',
                'customerName': first ? 'AI 客户' : '等回复客户',
                'status': 'open',
                'unreadCount': first ? 7 : 0,
                'replyStatus': first ? 'replied' : 'unreplied',
                'lastMessage': first ? 'AI 已答复' : '需要帮助',
                'updatedAt': first
                    ? '2026-10-22T02:00:00Z'
                    : '2026-10-22T01:00:00Z',
              },
            ],
          });
        }
        final bool ai = request.url.path.contains('conv_ai');
        return _ok(<Map<String, dynamic>>[
          <String, dynamic>{
            'messageId': ai ? 'msg_ai' : 'msg_customer',
            'sender': <String, dynamic>{'role': ai ? 'ai' : 'customer'},
            'text': ai ? 'AI 已答复' : '需要帮助',
            'type': 'text',
            'status': 'read',
          },
        ]);
      }),
    );
    addTearDown(repository.close);
    final List<Conversation> conversations = await repository
        .fetchConversations();
    expect(pages, <String>['1', '2']);
    expect(conversations, hasLength(2));
    expect(conversations.first.status, ConversationStatus.ai);
    expect(conversations.first.unreadCount, 7);
    expect(conversations.first.needsReply, isFalse);
    expect(conversations.last.needsReply, isTrue);
    expect(
      (await repository.fetchMessages('conv_ai')).single.sender,
      ChatSender.ai,
    );
  });

  test('翻译使用新批量接口并将自动目标语言转换为具体语言', () async {
    final RemoteChatRepository repository = RemoteChatRepository(
      baseUrl: 'https://server.example',
      accessToken: 'staff-session',
      client: MockClient((http.Request request) async {
        expect(request.url.path, '/api/v1/translations');
        final Map<String, dynamic> body = asJsonMap(jsonDecode(request.body));
        expect(body['items'], <Map<String, dynamic>>[
          <String, dynamic>{
            'text': '你好',
            'sourceLang': 'auto',
            'targetLang': 'en',
          },
        ]);
        return _ok(<Map<String, dynamic>>[
          <String, dynamic>{'translatedText': 'Hello', 'cached': true},
        ]);
      }),
    );
    addTearDown(repository.close);
    expect(
      await repository.translate(
        text: '你好',
        source: TranslationLanguage.auto,
        target: TranslationLanguage.auto,
      ),
      'Hello',
    );
  });

  test('新翻译服务不可用时回退到 vecor 翻译接口', () async {
    final List<String> paths = <String>[];
    final RemoteChatRepository repository = RemoteChatRepository(
      baseUrl: 'https://server.example',
      accessToken: 'staff-session',
      client: MockClient((http.Request request) async {
        paths.add(request.url.path);
        if (request.url.path == '/api/v1/translations') {
          return http.Response(
            '{"code":"TRANSLATION_ERROR","message":"unavailable"}',
            502,
          );
        }
        expect(jsonDecode(request.body)['targetLang'], 'zh-CN');
        return _ok(<String, dynamic>{'text': '你好'});
      }),
    );
    addTearDown(repository.close);
    expect(
      await repository.translate(
        text: 'Hello',
        source: TranslationLanguage.en,
        target: TranslationLanguage.auto,
      ),
      '你好',
    );
    expect(paths, <String>['/api/v1/translations', '/admin/v1/translate']);
  });
}

Map<String, dynamic> _session() => <String, dynamic>{
  'user': <String, dynamic>{
    'userKey': 'user_42',
    'account': 'duty',
    'displayName': '值守客服',
    'tenantId': 'tenant_1',
    'role': 'admin',
  },
  'token': <String, dynamic>{'token': 'staff-session'},
};

http.Response _ok(Object? data) => http.Response(
  jsonEncode(<String, dynamic>{'code': 'OK', 'data': data}),
  200,
  headers: <String, String>{'content-type': 'application/json; charset=utf-8'},
);
