import 'package:flutter/widgets.dart';
import 'strings/ar.dart';
import 'strings/de.dart';
import 'strings/en.dart';
import 'strings/es.dart';
import 'strings/fr.dart';
import 'strings/hi.dart';
import 'strings/it.dart';
import 'strings/pt.dart';
import 'strings/tr.dart';
import 'strings/zh.dart';

/// Hand-written localization lookup (no code generation): every UI string
/// in the app is looked up by key for the active [Locale]. Falls back to
/// English for any language that isn't in [_allStrings] or any key missing
/// from a translated map, so a partial translation never shows a blank
/// string or throws.
///
/// Usage: `AppLocalizations.of(context)!('someKey')` (or store `final t =
/// AppLocalizations.of(context)!;` and call `t('someKey')`). For strings
/// with placeholders like `{count}`, use `t.tp('someKey', {'count': '3'})`.
class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations);

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// Looks up [key] in the active locale, falling back to English.
  String call(String key) {
    final localized = _allStrings[locale.languageCode]?[key];
    return localized ?? _allStrings['en']![key] ?? key;
  }

  /// Same as [call], but replaces every `{name}` placeholder in the
  /// resolved string with `params['name']`.
  String tp(String key, Map<String, String> params) {
    var result = call(key);
    for (final entry in params.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  // Every language in the picker is "supported": untranslated ones simply
  // resolve every key through the English fallback in AppLocalizations.call.
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const Map<String, Map<String, String>> _allStrings = {
  'en': enStrings,
  'fr': frStrings,
  'ar': arStrings,
  'es': esStrings,
  'de': deStrings,
  'pt': ptStrings,
  'it': itStrings,
  'tr': trStrings,
  'zh': zhStrings,
  'hi': hiStrings,
};
