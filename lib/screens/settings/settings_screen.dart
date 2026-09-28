import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../favorites/favorites_screen.dart';
import '../onboarding/language_selection_screen.dart';

const _kPlayStoreUrl = 'https://play.google.com/store/apps/details?id=com.ouballouk.aipdfscanner';
const _kPrivacyPolicyUrl = 'https://website-ivory-six-ny2q7yow1q.vercel.app/privacy-policy';
const _kTermsOfServiceUrl = 'https://website-ivory-six-ny2q7yow1q.vercel.app/terms-of-service';
const _kSupportEmail = 'Studentabdelhak@gmail.com';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t('settingsTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _SectionLabel(t('settingsActivitySectionTitle')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.star_outline_rounded, color: AppColors.primary),
              title: Text(t('settingsFavorites')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const FavoritesScreen())),
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel(t('settingsGeneralSectionTitle')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                  title: Text(t('settingsLanguageLabel')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LanguageSelectionScreen(fromSettings: true),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_none_rounded, color: AppColors.primary),
                  title: Text(t('settingsNotifications')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: openAppSettings,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel(t('settingsSupportSectionTitle')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.star_rate_rounded, color: AppColors.primary),
                  title: Text(t('settingsRateApp')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => launchUrl(Uri.parse(_kPlayStoreUrl), mode: LaunchMode.externalApplication),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.share_outlined, color: AppColors.primary),
                  title: Text(t('settingsShareApp')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => SharePlus.instance.share(
                    ShareParams(text: '${t('shareAppMessage')} $_kPlayStoreUrl'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.support_agent_rounded, color: AppColors.primary),
                  title: Text(t('settingsContactSupport')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => launchUrl(Uri(
                    scheme: 'mailto',
                    path: _kSupportEmail,
                    query: 'subject=${Uri.encodeComponent(t('appName'))}',
                  )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel(t('settingsAboutSectionTitle')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                  title: Text(t('settingsTermsOfService')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => launchUrl(Uri.parse(_kTermsOfServiceUrl), mode: LaunchMode.externalApplication),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                  title: Text(t('settingsPrivacyPolicy')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => launchUrl(Uri.parse(_kPrivacyPolicyUrl), mode: LaunchMode.externalApplication),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }
}
