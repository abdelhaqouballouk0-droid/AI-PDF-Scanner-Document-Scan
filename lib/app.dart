import 'package:flutter/material.dart';
import 'screens/shell/main_shell.dart';
import 'theme/app_theme.dart';

class AiPdfScannerApp extends StatelessWidget {
  const AiPdfScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI PDF Scanner-Document Scan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainShell(),
    );
  }
}
