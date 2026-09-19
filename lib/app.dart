import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'l10n/supported_languages.dart';
import 'providers/locale_provider.dart';
import 'screens/onboarding/splash_screen.dart';
import 'theme/app_theme.dart';

class AiPdfScannerApp extends ConsumerWidget {
  const AiPdfScannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: 'AI PDF Scanner-Document Scan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: kSupportedLanguages.map((l) => Locale(l.code)).toList(),
      home: const SplashScreen(),
    );
  }
}
