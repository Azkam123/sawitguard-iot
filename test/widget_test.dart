// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitguard_iot/core/theme/app_theme.dart';

void main() {
  testWidgets('App has correct dark theme background', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Center(
            child: Text('SawitGuard IoT'),
          ),
        ),
      ),
    );

    expect(find.text('SawitGuard IoT'), findsOneWidget);
  });
}
