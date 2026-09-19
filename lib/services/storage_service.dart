import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/signature_model.dart';

/// Thin wrapper around [SharedPreferences] holding every small piece of
/// state that needs to survive an app restart: AI provider settings, the
/// signature index, and simple user preferences.
///
/// Everything here is local-only — no data ever leaves the device through
/// this service.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _kAiBaseUrl = 'ai_base_url';
  static const _kAiApiKey = 'ai_api_key';
  static const _kAiModel = 'ai_model';
  static const _kOfficeConversionUrl = 'office_conversion_url';
  static const _kSignatures = 'signatures_index';
  static const _kGridView = 'files_grid_view';
  static const _kOnboardingSeen = 'onboarding_seen';
  static const _kLocale = 'locale_code';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ---- AI Assistant configuration ----------------------------------

  /// Default points at a local Ollama instance (OpenAI-compatible route)
  /// so the app works out of the box on a dev machine. Override from
  /// Settings to point at OpenAI, Groq, OpenRouter, or any compatible host.
  static const String defaultAiBaseUrl = 'http://10.0.2.2:11434/v1';
  static const String defaultAiModel = 'llama3.1';

  Future<String> getAiBaseUrl() async =>
      (await _prefs).getString(_kAiBaseUrl) ?? defaultAiBaseUrl;

  Future<void> setAiBaseUrl(String value) async =>
      (await _prefs).setString(_kAiBaseUrl, value);

  Future<String?> getAiApiKey() async => (await _prefs).getString(_kAiApiKey);

  Future<void> setAiApiKey(String value) async =>
      (await _prefs).setString(_kAiApiKey, value);

  Future<String> getAiModel() async =>
      (await _prefs).getString(_kAiModel) ?? defaultAiModel;

  Future<void> setAiModel(String value) async =>
      (await _prefs).setString(_kAiModel, value);

  /// Optional REST endpoint for Word/Excel <-> PDF conversion (e.g. a
  /// self-hosted LibreOffice/Gotenberg service, or CloudConvert). Office
  /// format conversion cannot be done reliably on-device, so this is left
  /// pluggable — see ConversionService for the exact contract expected.
  Future<String?> getOfficeConversionUrl() async =>
      (await _prefs).getString(_kOfficeConversionUrl);

  Future<void> setOfficeConversionUrl(String value) async =>
      (await _prefs).setString(_kOfficeConversionUrl, value);

  // ---- Signatures -----------------------------------------------------

  Future<List<SignatureModel>> getSignatures() async {
    final raw = (await _prefs).getString(_kSignatures);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => SignatureModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSignatures(List<SignatureModel> signatures) async {
    final raw = jsonEncode(signatures.map((s) => s.toJson()).toList());
    await (await _prefs).setString(_kSignatures, raw);
  }

  // ---- Misc preferences -------------------------------------------------

  Future<bool> getGridView() async => (await _prefs).getBool(_kGridView) ?? false;

  Future<void> setGridView(bool value) async => (await _prefs).setBool(_kGridView, value);

  Future<bool> getOnboardingSeen() async =>
      (await _prefs).getBool(_kOnboardingSeen) ?? false;

  Future<void> setOnboardingSeen(bool value) async =>
      (await _prefs).setBool(_kOnboardingSeen, value);

  /// The user's chosen UI language (ISO 639-1 code, e.g. 'en', 'fr', 'ar').
  /// Null until they've picked one in the onboarding flow or Settings.
  Future<String?> getLocale() async => (await _prefs).getString(_kLocale);

  Future<void> setLocale(String languageCode) async =>
      (await _prefs).setString(_kLocale, languageCode);
}
