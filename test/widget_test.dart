import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orbby_json_viewer/src/json_viewer_screen.dart';

void main() {
  testWidgets('JsonViewerScreen 可以正常构建', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: JsonViewerScreen()),
      ),
    );
    expect(find.byType(JsonViewerScreen), findsOneWidget);
  });
}
