import 'package:auth_uae_pass/auth_uae_pass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders english sign in label by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UaePassLoginButton(
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Sign in with UAE PASS'), findsOneWidget);
  });

  testWidgets('renders arabic sign in label when language is arabic', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UaePassLoginButton(
            language: UaePassButtonLanguage.arabic,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('تسجيل الدخول بالهوية الرقمية'), findsOneWidget);
  });

  testWidgets('renders english sign up label', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UaePassLoginButton(
            labelType: UaePassButtonLabelType.signUp,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Sign up with UAE PASS'), findsOneWidget);
  });

  testWidgets('renders arabic sign up label', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UaePassLoginButton(
            language: UaePassButtonLanguage.arabic,
            labelType: UaePassButtonLabelType.signUp,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('إنشاء حساب بالهوية الرقمية'), findsOneWidget);
  });

  testWidgets('renders custom label when provided', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UaePassLoginButton(
            onPressed: () {},
            customLabel: 'Sign in with UAE PASS',
          ),
        ),
      ),
    );

    expect(find.text('Sign in with UAE PASS'), findsOneWidget);
  });

  test('provides black style factory', () {
    final style = UaePassButtonStyle.black();
    expect(style.backgroundColor, Colors.black);
    expect(style.foregroundColor, Colors.white);
  });
}
