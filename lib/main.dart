import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/ads_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AdsService.initialize();
  runApp(const ProviderScope(child: AiPdfScannerApp()));
}
