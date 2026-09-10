import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twicely/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('App login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
    expect(find.text('Sign up'), findsOneWidget);
  });
}
