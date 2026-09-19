/// One entry in the language picker.
///
/// [isFullyTranslated] is what drives the "fallback" notice on the picker
/// row (see [AppLocalizations]): languages without a full translation still
/// show up so the user can pick their language by name, but the app UI
/// falls back to English strings for any key that isn't translated yet.
class AppLanguage {
  final String code;
  final String englishName;
  final String nativeName;
  final String flag;
  final bool isFullyTranslated;
  final bool isRtl;

  const AppLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.flag,
    this.isFullyTranslated = false,
    this.isRtl = false,
  });
}

/// Every language the picker offers. Order matters: fully-translated
/// languages first (most useful choices up top), then the rest alphabetized
/// by English name.
const List<AppLanguage> kSupportedLanguages = [
  // -- Fully translated --------------------------------------------------
  AppLanguage(code: 'en', englishName: 'English', nativeName: 'English', flag: '🇬🇧', isFullyTranslated: true),
  AppLanguage(code: 'fr', englishName: 'French', nativeName: 'Français', flag: '🇫🇷', isFullyTranslated: true),
  AppLanguage(code: 'ar', englishName: 'Arabic', nativeName: 'العربية', flag: '🇸🇦', isFullyTranslated: true, isRtl: true),
  AppLanguage(code: 'es', englishName: 'Spanish', nativeName: 'Español', flag: '🇪🇸', isFullyTranslated: true),
  AppLanguage(code: 'de', englishName: 'German', nativeName: 'Deutsch', flag: '🇩🇪', isFullyTranslated: true),
  AppLanguage(code: 'pt', englishName: 'Portuguese', nativeName: 'Português', flag: '🇵🇹', isFullyTranslated: true),
  AppLanguage(code: 'it', englishName: 'Italian', nativeName: 'Italiano', flag: '🇮🇹', isFullyTranslated: true),
  AppLanguage(code: 'tr', englishName: 'Turkish', nativeName: 'Türkçe', flag: '🇹🇷', isFullyTranslated: true),
  AppLanguage(code: 'zh', englishName: 'Chinese (Simplified)', nativeName: '简体中文', flag: '🇨🇳', isFullyTranslated: true),
  AppLanguage(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳', isFullyTranslated: true),

  // -- Listed, English fallback for now -----------------------------------
  AppLanguage(code: 'bn', englishName: 'Bengali', nativeName: 'বাংলা', flag: '🇧🇩'),
  AppLanguage(code: 'cs', englishName: 'Czech', nativeName: 'Čeština', flag: '🇨🇿'),
  AppLanguage(code: 'da', englishName: 'Danish', nativeName: 'Dansk', flag: '🇩🇰'),
  AppLanguage(code: 'nl', englishName: 'Dutch', nativeName: 'Nederlands', flag: '🇳🇱'),
  AppLanguage(code: 'fi', englishName: 'Finnish', nativeName: 'Suomi', flag: '🇫🇮'),
  AppLanguage(code: 'el', englishName: 'Greek', nativeName: 'Ελληνικά', flag: '🇬🇷'),
  AppLanguage(code: 'he', englishName: 'Hebrew', nativeName: 'עברית', flag: '🇮🇱', isRtl: true),
  AppLanguage(code: 'hu', englishName: 'Hungarian', nativeName: 'Magyar', flag: '🇭🇺'),
  AppLanguage(code: 'id', englishName: 'Indonesian', nativeName: 'Bahasa Indonesia', flag: '🇮🇩'),
  AppLanguage(code: 'ja', englishName: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
  AppLanguage(code: 'ko', englishName: 'Korean', nativeName: '한국어', flag: '🇰🇷'),
  AppLanguage(code: 'ms', englishName: 'Malay', nativeName: 'Bahasa Melayu', flag: '🇲🇾'),
  AppLanguage(code: 'no', englishName: 'Norwegian', nativeName: 'Norsk', flag: '🇳🇴'),
  AppLanguage(code: 'fa', englishName: 'Persian', nativeName: 'فارسی', flag: '🇮🇷', isRtl: true),
  AppLanguage(code: 'pl', englishName: 'Polish', nativeName: 'Polski', flag: '🇵🇱'),
  AppLanguage(code: 'ro', englishName: 'Romanian', nativeName: 'Română', flag: '🇷🇴'),
  AppLanguage(code: 'ru', englishName: 'Russian', nativeName: 'Русский', flag: '🇷🇺'),
  AppLanguage(code: 'sv', englishName: 'Swedish', nativeName: 'Svenska', flag: '🇸🇪'),
  AppLanguage(code: 'sw', englishName: 'Swahili', nativeName: 'Kiswahili', flag: '🇰🇪'),
  AppLanguage(code: 'th', englishName: 'Thai', nativeName: 'ไทย', flag: '🇹🇭'),
  AppLanguage(code: 'uk', englishName: 'Ukrainian', nativeName: 'Українська', flag: '🇺🇦'),
  AppLanguage(code: 'ur', englishName: 'Urdu', nativeName: 'اردو', flag: '🇵🇰', isRtl: true),
  AppLanguage(code: 'vi', englishName: 'Vietnamese', nativeName: 'Tiếng Việt', flag: '🇻🇳'),
];
