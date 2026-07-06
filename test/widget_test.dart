import 'package:flutter_test/flutter_test.dart';
import 'package:twicely/main.dart';
import 'package:twicely/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('App login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TwicelyApp());

    // Advance mock timer to settle splash screen transition
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify that the login screen is loaded and the main buttons are present.
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
  });
}
