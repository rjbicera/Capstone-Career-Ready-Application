// Basic Flutter widget test for the Career Ready app.
//
// This just verifies the app boots and shows the splash screen without
// throwing. Update/expand this once more screens have testable widgets.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('App builds and shows CareerReadyApp', (WidgetTester tester) async {
    await tester.pumpWidget(const CareerReadyApp());
    await tester.pump();

    expect(find.byType(CareerReadyApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
