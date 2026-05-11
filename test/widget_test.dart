import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqia/main.dart';

void main() {
  testWidgets('AQIA app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const AQIAApp());
    await tester.pumpAndSettle();
    expect(find.text('AQIA'), findsWidgets);
  });
}
