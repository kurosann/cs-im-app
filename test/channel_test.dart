import 'package:cs_im_app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('渠道状态进入渠道会话列表', (WidgetTester tester) async {
    await tester.pumpWidget(const CsImApp(enablePersistence: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('状态'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();

    expect(find.text('orange-support'), findsOneWidget);
    expect(find.text('共 4 个会话'), findsOneWidget);
    expect(find.text('李然'), findsOneWidget);
    expect(find.text('Maya'), findsNothing);
  });
}
