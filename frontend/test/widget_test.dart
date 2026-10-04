import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('SplitSquad app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const RootApp());
    // Allow async _init in AuthViewModel to resolve
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that the login screen title and sign in card exist
    expect(find.text('SplitSquad'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ (Sign In)'), findsOneWidget);
  });
}
