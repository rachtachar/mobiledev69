import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('SplitSquad app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RootApp());

    // Verify that the login screen title exists.
    expect(find.text('SplitSquad'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ (Sign In)'), findsOneWidget);
  });
}
