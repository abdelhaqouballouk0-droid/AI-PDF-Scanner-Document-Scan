import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../signature/signature_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _SectionLabel('Assistant IA'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('URL du service (OpenAI-compatible)'),
                  subtitle: Text(settings.aiBaseUrl),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editField(
                    context,
                    title: 'URL du service IA',
                    initial: settings.aiBaseUrl,
                    hint: 'https://api.openai.com/v1',
                    onSave: (v) => ref.read(settingsProvider.notifier).setAiBaseUrl(v),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Modèle'),
                  subtitle: Text(settings.aiModel),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editField(
                    context,
                    title: 'Modèle',
                    initial: settings.aiModel,
                    hint: 'gpt-4o-mini, llama3.1, ...',
                    onSave: (v) => ref.read(settingsProvider.notifier).setAiModel(v),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Clé API'),
                  subtitle: Text(
                    (settings.aiApiKey == null || settings.aiApiKey!.isEmpty)
                        ? 'Non renseignée'
                        : '•' * 12,
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editField(
                    context,
                    title: 'Clé API',
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
          const _SectionLabel('Conversion Word / Excel'),
          Card(
            child: ListTile(
              title: const Text('URL du serveur de conversion'),
              subtitle: Text(
                (settings.officeConversionUrl == null || settings.officeConversionUrl!.isEmpty)
                    ? 'Non configuré'
                    : settings.officeConversionUrl!,
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editField(
                context,
                title: 'URL du serveur de conversion',
                initial: settings.officeConversionUrl ?? '',
                hint: 'https://mon-serveur-gotenberg.exemple.com',
                onSave: (v) => ref.read(settingsProvider.notifier).setOfficeConversionUrl(v),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Bibliothèque'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.draw_outlined, color: AppColors.primary),
              title: const Text('Mes signatures'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const SignatureScreen())),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('À propos'),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Enregistrer'),
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
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '1.0.0';
        return ListTile(
          leading: const Icon(Icons.info_outline_rounded),
          title: const Text('AI PDF Scanner-Document Scan'),
          subtitle: Text('Version $version'),
        );
      },
    );
  }
}
