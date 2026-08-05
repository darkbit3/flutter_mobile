import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:semeta/main.dart';

void main() {
  testWidgets('ShmetaApp smoke test — app renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ShmetaApp(),
      ),
    );
    // App should render at least one widget
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
