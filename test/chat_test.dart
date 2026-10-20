import 'package:cs_im_app/app.dart';
import 'package:cs_im_app/data/mock_translation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('聊天页展示语音与视频气泡', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CsImApp(
        enablePersistence: false,
        translationService: MockTranslationService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Maya'));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('chat-message-list')),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('audio_m18')), findsOneWidget);
    expect(find.byKey(const ValueKey('video_m19')), findsOneWidget);
  });

  testWidgets('聊天头部展示客户信息与翻译入口', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CsImApp(
        enablePersistence: false,
        translationService: MockTranslationService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Maya'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('返回'), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-contact-info')), findsOneWidget);
    expect(find.byTooltip('翻译设置'), findsOneWidget);
    expect(find.byTooltip('客户信息'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

    await tester.tap(find.byTooltip('客户信息'));
    await tester.pumpAndSettle();
    expect(find.text('客户信息'), findsOneWidget);
  });
  testWidgets('输入框附件按钮可选择图片', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CsImApp(
        enablePersistence: false,
        translationService: MockTranslationService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Maya'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('添加附件'));
    await tester.pumpAndSettle();

    expect(find.text('添加附件'), findsOneWidget);
    expect(find.text('图片'), findsOneWidget);
    expect(find.text('视频'), findsOneWidget);
    expect(find.text('文件'), findsOneWidget);

    await tester.tap(find.text('图片'));
    await tester.pumpAndSettle();
    expect(find.text('已添加示例图片'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
