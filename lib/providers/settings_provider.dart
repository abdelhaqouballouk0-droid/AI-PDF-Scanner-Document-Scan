import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

class SettingsState {
  final String aiBaseUrl;
  final String aiModel;
  final String? aiApiKey;
  final String? officeConversionUrl;
  final bool gridView;
  final bool loaded;
  final bool? aiConsent;

  const SettingsState({
    this.aiBaseUrl = StorageService.defaultAiBaseUrl,
    this.aiModel = StorageService.defaultAiModel,
    this.aiApiKey,
    this.officeConversionUrl,
    this.gridView = false,
    this.loaded = false,
    this.aiConsent,
  });

  SettingsState copyWith({
    String? aiBaseUrl,
    String? aiModel,
    String? aiApiKey,
    String? officeConversionUrl,
    bool? gridView,
    bool? loaded,
    bool? aiConsent,
  }) {
    return SettingsState(
      aiBaseUrl: aiBaseUrl ?? this.aiBaseUrl,
      aiModel: aiModel ?? this.aiModel,
      aiApiKey: aiApiKey ?? this.aiApiKey,
      officeConversionUrl: officeConversionUrl ?? this.officeConversionUrl,
      gridView: gridView ?? this.gridView,
      loaded: loaded ?? this.loaded,
      aiConsent: aiConsent ?? this.aiConsent,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  final _storage = StorageService.instance;

  Future<void> _load() async {
    final baseUrl = await _storage.getAiBaseUrl();
    final model = await _storage.getAiModel();
    final apiKey = await _storage.getAiApiKey();
    final officeUrl = await _storage.getOfficeConversionUrl();
    final gridView = await _storage.getGridView();
    final aiConsent = await _storage.getAiConsent();
    state = state.copyWith(
      aiBaseUrl: baseUrl,
      aiModel: model,
      aiApiKey: apiKey,
      officeConversionUrl: officeUrl,
      gridView: gridView,
      aiConsent: aiConsent,
      loaded: true,
    );
  }

  Future<void> setAiBaseUrl(String value) async {
    await _storage.setAiBaseUrl(value);
    state = state.copyWith(aiBaseUrl: value);
  }

  Future<void> setAiModel(String value) async {
    await _storage.setAiModel(value);
    state = state.copyWith(aiModel: value);
  }

  Future<void> setAiApiKey(String value) async {
    await _storage.setAiApiKey(value);
    state = state.copyWith(aiApiKey: value);
  }

  Future<void> setOfficeConversionUrl(String value) async {
    await _storage.setOfficeConversionUrl(value);
    state = state.copyWith(officeConversionUrl: value);
  }

  Future<void> setGridView(bool value) async {
    await _storage.setGridView(value);
    state = state.copyWith(gridView: value);
  }

  Future<void> setAiConsent(bool value) async {
    await _storage.setAiConsent(value);
    state = state.copyWith(aiConsent: value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
