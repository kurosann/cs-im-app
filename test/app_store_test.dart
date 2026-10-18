import 'package:cs_im_app/data/mock_chat_repository.dart';
import 'package:cs_im_app/data/mock_translation_service.dart';
import 'package:cs_im_app/models/chat_message.dart';
import 'package:cs_im_app/models/platform_channel.dart';
import 'package:cs_im_app/models/translation_language.dart';
import 'package:cs_im_app/models/translation_provider.dart';
import 'package:cs_im_app/state/app_store.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Mock 仓库初始化与发送消息', () async {
    final AppStore store = AppStore(
      MockChatRepository(),
      const MockTranslationService(),
      persistenceEnabled: false,
    );
    await store.init();

    expect(store.loading, isFalse);
    expect(store.conversations.length, 30);
    expect(store.messagesOf('conv_li_ran').length, 3);
    expect(store.channels.length, 3);
    expect(store.forwardChannels.length, 3);
    expect(store.profile?.name, '移动值守');
    expect(store.profile?.accountId, 'mobile-duty-01');
    expect(
      store.conversations.map((c) => c.channel),
      containsAll(<PlatformChannel>[
        PlatformChannel.discord,
        PlatformChannel.teams,
        PlatformChannel.line,
        PlatformChannel.zalo,
      ]),
    );
    expect(store.waitingCount, 10);
    expect(store.handlingCount, 10);
    expect(store.aiHandledCount, 10);
    expect(
      store.messagesOf('conv_maya').map((m) => m.type).toSet(),
      containsAll(<ChatMessageType>[
        ChatMessageType.text,
        ChatMessageType.image,
        ChatMessageType.audio,
        ChatMessageType.video,
      ]),
    );

    await store.sendMessage('conv_li_ran', ' 你好 ');

    expect(store.messagesOf('conv_li_ran').last.text, '你好');
    expect(store.conversationById('conv_li_ran').lastMessage, '你好');
  });

  test('筛选待人工只返回待人工会话', () async {
    final AppStore store = AppStore(
      MockChatRepository(),
      const MockTranslationService(),
      persistenceEnabled: false,
    );
    await store.init();

    store.setFilter(1);

    expect(store.filteredConversations.map((c) => c.name).toList(), [
      '李然',
      'Yuki',
      '王敏',
      '赵磊',
      'Priya',
      'Fatima',
      'Diego',
      '黄婷',
      'Rahul',
      'Ali',
    ]);
  });

  test('用户设置持久化', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final AppStore first = AppStore(
      MockChatRepository(),
      const MockTranslationService(),
    );
    await first.init();

    await first.setThemeMode(ThemeMode.dark);
    await first.setNotificationsEnabled(false);
    await first.setTranslationEnabled(true);
    await first.setTranslationProvider(TranslationProvider.youdao);
    await first.setTranslationSource(TranslationLanguage.zhCN);
    await first.setTranslationTarget(TranslationLanguage.en);

    final AppStore restored = AppStore(
      MockChatRepository(),
      const MockTranslationService(),
    );
    await restored.init();

    expect(restored.themeMode, ThemeMode.dark);
    expect(restored.notificationsEnabled, isFalse);
    expect(restored.translationEnabled, isTrue);
    expect(restored.translationProvider, TranslationProvider.youdao);
    expect(restored.translationSource, TranslationLanguage.zhCN);
    expect(restored.translationTarget, TranslationLanguage.en);
  });
}
