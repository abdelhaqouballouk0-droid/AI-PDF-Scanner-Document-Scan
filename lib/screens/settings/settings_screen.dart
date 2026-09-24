import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../favorites/favorites_screen.dart';
import '../onboarding/language_selection_screen.dart';
import '../signature/signature_screen.dart';

const _kPlayStoreUrl = 'https://play.google.com/store/apps/details?id=com.ouballouk.aipdfscanner';
const _kPrivacyPolicyUrl = 'https://website-ivory-six-ny2q7yow1q.vercel.app/privacy-policy';
const _kTermsOfServiceUrl = 'https://website-ivory-six-ny2q7yow1q.vercel.app/terms-of-service';
const _kSupportEmail = 'Studentabdelhak@gmail.com';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t('settingsTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _ProBanner(onTap: () => _showComingSoon(context)),
          const SizedBox(height: 20),
          _SectionLabel(t('settingsAiSectionTitle')),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(t('settingsAiConsentLabel')),
                  subtitle: Text(t('aiConsentBody')),
                  value: settings.aiConsent ?? false,
                  onChanged: (v) => ref.read(settingsProvider.notifier).setAiConsent(v),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(t('settingsAiUrlLabel')),
                  subtitle: Text(settings.aiBaseUrl),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editField(
                    context,
                    title: t('settingsAiUrlDialogTitle'),
                    initial: settings.aiBaseUrl,
                    hint: 'https://api.openai.com/v1',
                    onSave: (v) => ref.read(settingsProvider.notifier).setAiBaseUrl(v),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(t('settingsAiModelLabel')),
                  subtitle: Text(settings.aiModel),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editField(
                    context,
                    title: t('settingsAiModelLabel'),
                    initial: settings.aiModel,
                    hint: 'gpt-4o-mini, llama3.1, ...',
                    onSave: (v) => ref.read(settingsProvider.notifier).setAiModel(v),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(t('settingsApiKeyLabel')),
                  subtitle: Text(
                    (settings.aiApiKey == null || settings.aiApiKey!.isEmpty)
                        ? t('settingsApiKeyEmpty')
                        : '•' * 12,
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editField(
                    context,
                    title: t('settingsApiKeyLabel'),
                    initial: settings.aiApiKey ?? '',
                    hint: 'sk-...',
                    obscure: true,
                    onSave: (v) => ref.read(settingsProvider.notifier).setAiApiKey(v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel(t('settingsConversionSectionTitle')),
          Card(
            child: ListTile(
              title: Text(t('settingsConversionUrlLabel')),
              subtitle: Text(
                (settings.officeConversionUrl == null || settings.officeConversionUrl!.isEmpty)
                    ? t('settingsConversionUrlNotConfigured')
                    : settings.officeConversionUrl!,
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editField(
                context,
                title: t('settingsConversionUrlLabel'),
                initial: settings.officeConversionUrl ?? '',
                hint: 'https://mon-serveur-gotenberg.exemple.com',
                onSave: (v) => ref.read(settingsProvider.notifier).setOfficeConversionUrl(v),
              ),
            ),
          ),
          const SizedBox(height: 20),
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
          _SectionLabel(t('settingsLibrarySectionTitle')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.draw_outlined, color: AppColors.primary),
              title: Text(t('settingsMySignatures')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const SignatureScreen())),
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
                const Divider(height: 1),
                const _AboutTile(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('comingSoonMessage'))));
  }

  Future<void> _editField(
    BuildContext context, {
    required String title,
    required String initial,
    required String hint,
    required ValueChanged<String> onSave,
    bool obscure = false,
  }) async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: obscure,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('commonCancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(t('commonSave')),
          ),
        ],
      ),
    );
    if (result != null) onSave(result);
  }
}

class _ProBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _ProBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.proGradient),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.diamond_outlined, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('proBannerTitle'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t('proBannerSubtitle'),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
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

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '1.0.0';
        return ListTile(
          leading: const Icon(Icons.info_outline_rounded),
          title: Text(t('appName')),
          subtitle: Text(t.tp('settingsVersionLabel', {'version': version})),
        );
      },
    );
  }
}
