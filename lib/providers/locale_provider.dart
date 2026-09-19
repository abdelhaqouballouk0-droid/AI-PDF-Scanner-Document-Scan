import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

/// The app's active UI language. Defaults to English until the user has
/// picked one (onboarding) or a saved choice is loaded from disk.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _load();
  }

  Future<void> _load() async {
    final saved = await StorageService.instance.getLocale();
    if (saved != null) state = Locale(saved);
  }

  Future<void> setLocale(String languageCode) async {
    await StorageService.instance.setLocale(languageCode);
    state = Locale(languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);
