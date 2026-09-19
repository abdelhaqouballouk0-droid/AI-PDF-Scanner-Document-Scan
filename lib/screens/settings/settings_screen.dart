import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../onboarding/language_selection_screen.dart';
import '../signature/signature_screen.dart';

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
          _SectionLabel(t('settingsAiSectionTitle')),
          Card(
            child: Column(
              children: [
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
          _SectionLabel(t('settingsGeneralSectionTitle')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_rounded, color: AppColors.primary),
              title: Text(t('settingsLanguageLabel')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LanguageSelectionScreen(fromSettings: true),
                ),
              ),
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
          _SectionLabel(t('settingsAboutSectionTitle')),
          const Card(child: _AboutTile()),
        ],
      ),
    );
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
