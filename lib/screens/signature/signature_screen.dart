import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/signature_model.dart';
import '../../providers/signature_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/signature_pad_sheet.dart';

class SignatureScreen extends ConsumerWidget {
  const SignatureScreen({super.key});

  Future<void> _createNew(BuildContext context, WidgetRef ref) async {
    final bytes = await showSignaturePad(context);
    if (bytes == null || !context.mounted) return;

    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: t('signaturesDefaultName'));
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('signaturesNewTitle')),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('commonCancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(t('commonSave')),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(signatureProvider.notifier).add(name, bytes);
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, SignatureModel model) async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: model.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('signaturesRenameTitle')),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('commonCancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(t('commonRename')),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(signatureProvider.notifier).rename(model.id, name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final signatures = ref.watch(signatureProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t('signaturesTitle'))),
      body: signatures.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(t.tp('commonErrorPrefix', {'error': '$e'}))),
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.draw_outlined,
                title: t('signaturesEmptyTitle'),
                message: t('signaturesEmptyMessage'),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final s = list[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 90,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.divider),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Image.file(File(s.imagePath), fit: BoxFit.contain),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(
                                  '${s.createdAt.day.toString().padLeft(2, '0')}/${s.createdAt.month.toString().padLeft(2, '0')}/${s.createdAt.year}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                            onPressed: () => _rename(context, ref, s),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.primary),
                            onPressed: () => ref.read(signatureProvider.notifier).delete(s.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNew(context, ref),
        icon: const Icon(Icons.add),
        label: Text(t('signaturesDraw')),
      ),
    );
  }
}
