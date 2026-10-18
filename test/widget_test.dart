import 'package:cs_im_app/app.dart';
import 'package:cs_im_app/data/mock_translation_service.dart';
import 'package:cs_im_app/widgets/channel_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('默认启动展示登录页并可进入工作区', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CsImApp(enablePersistence: false, requireLogin: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('进入客服值守'), findsOneWidget);
    expect(find.text('服务地址'), findsNothing);
    expect(find.byKey(const ValueKey('login-account')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-password')), findsOneWidget);
    expect(find.text('请输入账号'), findsNothing);

    await tester.ensureVisible(find.text('进入工作区'));
    await tester.tap(find.text('进入工作区'));
    await tester.pumpAndSettle();
    expect(find.text('请输入账号'), findsOneWidget);
    expect(find.text('请输入密码'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('login-account')),
      'demo-account',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'demo-password',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('login-policy-checkbox')),
    );
    await tester.tap(find.byKey(const ValueKey('login-policy-checkbox')));
    await tester.ensureVisible(find.text('进入工作区'));
    await tester.tap(find.text('进入工作区'));
    await tester.pumpAndSettle();

    expect(find.text('橙子科技'), findsOneWidget);
    expect(find.text('移动值守'), findsOneWidget);
  });

  testWidgets('登录页可以查看接入说明并从工作区退出', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CsImApp(enablePersistence: false, requireLogin: true),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('查看接入说明'));
    await tester.tap(find.text('查看接入说明'));
    await tester.pumpAndSettle();
    expect(find.text('如何接入工作区'), findsOneWidget);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('login-account')),
      'demo-account',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'demo-password',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('login-policy-checkbox')),
    );
    await tester.tap(find.byKey(const ValueKey('login-policy-checkbox')));
    await tester.tap(find.text('进入工作区'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('me-page-list')),
      const Offset(0, -480),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('退出登录'));
    await tester.pumpAndSettle();

    expect(find.text('进入客服值守'), findsOneWidget);
  });

  testWidgets('值守页展示会话列表与筛选', (WidgetTester tester) async {
    await tester.pumpWidget(const CsImApp(enablePersistence: false));
    await tester.pumpAndSettle();

    expect(find.text('橙子科技'), findsOneWidget);
    expect(find.text('移动值守'), findsOneWidget);
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('待人工'), findsOneWidget);
    expect(find.text('李然'), findsOneWidget);
    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('老王'), findsOneWidget);
    expect(find.byType(ChannelAvatar), findsWidgets);
  });

  testWidgets('底部导航使用独立悬浮毛玻璃', (WidgetTester tester) async {
    await tester.pumpWidget(const CsImApp(enablePersistence: false));
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('值守'), findsOneWidget);
    expect(find.text('状态'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    final Text navLabel = tester.widget<Text>(find.text('状态'));
    expect(navLabel.style?.fontFamily, 'Inter');
    expect(navLabel.style?.fontFamilyFallback, contains('NotoSansSC'));
    expect(navLabel.style?.fontWeight, FontWeight.w500);
  });
  testWidgets('全局字体使用 Inter 并以 Noto Sans SC 回退', (WidgetTester tester) async {
    await tester.pumpWidget(const CsImApp(enablePersistence: false));
    await tester.pumpAndSettle();

    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(app.theme?.textTheme.bodyMedium?.fontFamily, 'Inter');
    expect(
      app.theme?.textTheme.bodyMedium?.fontFamilyFallback,
      contains('NotoSansSC'),
    );
    expect(app.darkTheme?.textTheme.bodyMedium?.fontFamily, 'Inter');
    expect(
      app.darkTheme?.textTheme.bodyMedium?.fontFamilyFallback,
      contains('NotoSansSC'),
    );
  });
  testWidgets('待人工筛选仅保留待人工会话', (WidgetTester tester) async {
    await tester.pumpWidget(const CsImApp(enablePersistence: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('待人工'));
    await tester.pumpAndSettle();

    expect(find.text('李然'), findsOneWidget);
    expect(find.text('Yuki'), findsOneWidget);
    expect(find.text('Maya'), findsNothing);
    expect(find.text('老王'), findsNothing);
  });

  testWidgets('聊天页点击客户区域打开客户信息抽屉', (WidgetTester tester) async {
    await tester.pumpWidget(const CsImApp(enablePersistence: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('李然'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('chat-contact-info')));
    await tester.pumpAndSettle();

    expect(find.text('客户信息'), findsOneWidget);
    expect(find.text('业务渠道'), findsOneWidget);
    expect(find.text('当前状态'), findsOneWidget);
    expect(find.text('负责人'), findsOneWidget);
    expect(find.text('转发去向'), findsOneWidget);
    expect(find.text('WhatsApp'), findsNWidgets(2));
    expect(find.text('待人工'), findsWidgets);
    expect(find.text('未认领'), findsOneWidget);
    expect(find.text('Telegram'), findsOneWidget);
    expect(find.text('飞书'), findsOneWidget);
    expect(find.text('业务系统'), findsOneWidget);
  });

  testWidgets('无预置译文的 Mock 消息也调用机器翻译', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CsImApp(
        enablePersistence: false,
        translationService: MockTranslationService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('duty-conversation-list')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('小林'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('翻译设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('【auto】商品什么时候补货？'), findsOneWidget);
  });
  testWidgets('翻译设置抽屉包含翻译源与目标语言', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CsImApp(
        enablePersistence: false,
        translationService: MockTranslationService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Maya'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('翻译设置'));
    await tester.pumpAndSettle();

    expect(find.text('翻译设置'), findsOneWidget);
    expect(find.text('翻译源'), findsOneWidget);
    expect(find.text('源语言'), findsOneWidget);
    expect(find.text('目标语言'), findsOneWidget);
    expect(find.text('自动（推荐）'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('translation-provider-dropdown')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Google 翻译'), findsWidgets);
    expect(find.text('腾讯翻译君'), findsOneWidget);
    expect(find.text('百度翻译'), findsOneWidget);
    expect(find.text('有道翻译'), findsOneWidget);
    await tester.tap(find.text('Google 翻译').last);
    await tester.pumpAndSettle();
    expect(find.text('Google 翻译'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('translation-target-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('【en】Can you resend the invoice?'), findsOneWidget);

    await tester.tap(find.byTooltip('翻译设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('translation-target-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('简体中文').last);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('【zh-CN】Can you resend the invoice?'), findsOneWidget);
  });
}
