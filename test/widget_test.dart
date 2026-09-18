import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_pdf_scanner/app.dart';

void main() {
  testWidgets('App boots and shows the home shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AiPdfScannerApp()),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
