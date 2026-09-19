import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/supported_languages.dart';
import '../../providers/locale_provider.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../shell/main_shell.dart';

/// Language picker.
///
/// Used two ways:
/// - During onboarding (`fromSettings: false`, the default): shown once
///   right after the splash screen. Selecting a language and tapping
///   Continue persists the choice, marks onboarding as seen, and replaces
///   the whole navigation stack with [MainShell].
/// - From Settings (`fromSettings: true`): a normal pushed screen the user
///   can pop out of; picking a language applies it immediately.
class LanguageSelectionScreen extends ConsumerStatefulWidget {
  final bool fromSettings;

  const LanguageSelectionScreen({super.key, this.fromSettings = false});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCode;

  @override
  void initState() {
    super.initState();
    // Pre-select the device's current locale if it's in our list, so the
    // user isn't staring at an empty picker.
    final deviceCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    if (kSupportedLanguages.any((l) => l.code == deviceCode)) {
      _selectedCode = deviceCode;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppLanguage> get _filtered {
    if (_query.isEmpty) return kSupportedLanguages;
    final q = _query.toLowerCase();
    return kSupportedLanguages
        .where((l) =>
            l.englishName.toLowerCase().contains(q) ||
            l.nativeName.toLowerCase().contains(q) ||
            l.code.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _confirm() async {
    final code = _selectedCode;
    if (code == null) return;
    await ref.read(localeProvider.notifier).setLocale(code);

    if (!widget.fromSettings) {
      await StorageService.instance.setOnboardingSeen(true);
    }

    if (!mounted) return;

    if (widget.fromSettings) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Live preview: as soon as the user taps a language row, this screen's
    // own text switches to that language immediately (not just the check
    // mark), so picking a language visibly *does something* right away —
    // instead of waiting for the app-wide locale to change, which only
    // happens after "Continue" is pressed and this screen is gone.
    final previewCode =
        _selectedCode ?? AppLocalizations.of(context)!.locale.languageCode;
    final t = AppLocalizations(Locale(previewCode));
    final languages = _filtered;
    final previewIsRtl = kSupportedLanguages
        .firstWhere((l) => l.code == previewCode,
            orElse: () => kSupportedLanguages.first)
        .isRtl;

    return Directionality(
      textDirection: previewIsRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: widget.fromSettings
            ? AppBar(title: Text(t('settingsLanguageLabel')))
            : null,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.fromSettings) ...[
                      Text(
                        t('onboardingChooseLanguageTitle'),
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t('onboardingChooseLanguageSubtitle'),
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 18),
                    ],
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: t('onboardingSearchLanguageHint'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: languages.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 68),
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    final selected = lang.code == _selectedCode;
                    return ListTile(
                      onTap: () => setState(() => _selectedCode = lang.code),
                      leading:
                          Text(lang.flag, style: const TextStyle(fontSize: 26)),
                      title: Text(lang.nativeName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        lang.isFullyTranslated
                            ? lang.englishName
                            : '${lang.englishName} · ${t('onboardingFallbackNotice')}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                      trailing: selected
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary)
                          : null,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: ElevatedButton(
                  onPressed: _selectedCode == null ? null : _confirm,
                  child: Text(widget.fromSettings
                      ? t('commonSave')
                      : t('onboardingContinue')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
