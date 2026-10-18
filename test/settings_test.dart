import 'package:cs_im_app/app.dart';
import 'package:cs_im_app/data/mock_translation_service.dart';
import 'package:cs_im_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('我的页展示账号信息与基础设置', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CsImApp(
        enablePersistence: false,
        translationService: MockTranslationService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    expect(find.text('账号信息与基础设置。'), findsOneWidget);
    expect(find.text('移动值守'), findsOneWidget);
    expect(find.text('mobile-duty-01'), findsOneWidget);
    expect(find.text('基础设置'), findsOneWidget);
    expect(find.text('外观'), findsOneWidget);
    expect(find.text('隐私'), findsOneWidget);
    expect(find.text('存储空间'), findsOneWidget);
    expect(find.text('消息提醒'), findsOneWidget);
    expect(find.text('简体中文'), findsOneWidget);
    expect(find.text('0.1.0'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('退出登录'), findsOneWidget);
    final FilledButton logoutButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '退出登录'),
    );
    expect(
      logoutButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      AppColors.danger,
    );
  });

  testWidgets('存储空间可查看协议并清理缓存', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CsImApp(
        enablePersistence: false,
        translationService: MockTranslationService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('存储空间'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('存储空间'));
    await tester.pumpAndSettle();

    expect(find.text('本地缓存'), findsOneWidget);
    expect(find.text('清理本地缓存'), findsOneWidget);
    expect(find.text('存储协议'), findsOneWidget);

    await tester.tap(find.text('存储协议'));
    await tester.pumpAndSettle();
    expect(find.text('本地存储协议（草案）'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('清理本地缓存'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('清理'));
    await tester.pumpAndSettle();

    expect(find.text('本地缓存已清理'), findsOneWidget);
    expect(find.text('本地缓存已清空'), findsOneWidget);
    expect(find.text('0 B'), findsWidgets);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('隐私入口展示隐私协议', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CsImApp(
        enablePersistence: false,
        translationService: MockTranslationService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('隐私'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('隐私'));
    await tester.pumpAndSettle();

    expect(find.text('隐私协议'), findsOneWidget);
    expect(find.text('隐私速览'), findsOneWidget);
    expect(find.text('提示：本协议为 V1 原型草案，正式上线前需经法务审核。'), findsOneWidget);
  });

  testWidgets('切换浅色/深色主题', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CsImApp(
        enablePersistence: false,
        translationService: MockTranslationService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();
    MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);

    await tester.tap(find.text('浅色'));
    await tester.pumpAndSettle();
    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
  });

  testWidgets('状态页展示值守概况与渠道状态', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CsImApp(
        enablePersistence: false,
        translationService: MockTranslationService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('状态'));
    await tester.pumpAndSettle();

    expect(find.text('值守概况和渠道可用性。'), findsOneWidget);
    expect(find.text('处理中'), findsOneWidget);
    expect(find.text('AI 已处理'), findsOneWidget);
    expect(find.text('业务渠道'), findsOneWidget);
    expect(find.text('转发渠道'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Telegram'), findsOneWidget);
    expect(find.text('Messenger'), findsOneWidget);
    expect(find.text('在线'), findsNWidgets(3));
    expect(find.text('售后值班群'), findsOneWidget);
    expect(find.text('海外客服'), findsOneWidget);
    expect(find.text('客服转发群'), findsOneWidget);
    expect(find.text('已连接'), findsNWidgets(2));
    expect(find.text('未连接'), findsOneWidget);
  });
}
