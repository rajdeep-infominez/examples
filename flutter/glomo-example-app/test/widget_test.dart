import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:glomopay_sdk_test_app/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app's AppBar title is rendered.
    expect(find.text('GlomoPay SDK Tester'), findsOneWidget);

    // Verify that the start checkout button is present.
    expect(find.text('Start Checkout'), findsOneWidget);
  });
}
