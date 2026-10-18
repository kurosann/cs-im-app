import 'package:cs_im_app/app.dart';
import 'package:cs_im_app/data/mock_translation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('输入框边写边译', (WidgetTester tester) async {
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
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hello, need help');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('草稿译文'), findsOneWidget);
    expect(find.text('【auto】Hello, need help'), findsOneWidget);

    // 手动收起
    await tester.tap(find.byTooltip('收起译文'));
    await tester.pumpAndSettle();
    expect(find.text('草稿译文'), findsNothing);

    // 继续输入后自动重新展开
    await tester.enterText(find.byType(TextField), 'Hello, need help!');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('草稿译文'), findsOneWidget);

    // 使用译文后收起
    await tester.tap(find.byIcon(Icons.swap_vert_rounded));
    await tester.pumpAndSettle();
    expect(find.text('草稿译文'), findsNothing);
    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, '【auto】Hello, need help!');

    // 发送后保持收起
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();
    expect(find.text('草稿译文'), findsNothing);
  });
}
