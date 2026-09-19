import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/document_file.dart';
import '../../providers/files_provider.dart';
import '../../services/pdf_tools_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../viewer/pdf_viewer_screen.dart';

class CompressPdfScreen extends ConsumerStatefulWidget {
  final DocumentFile document;

  const CompressPdfScreen({super.key, required this.document});

  @override
  ConsumerState<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _CompressPdfScreenState extends ConsumerState<CompressPdfScreen> {
  CompressionLevel _level = CompressionLevel.medium;
  bool _working = false;

  Future<void> _compress() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _working = true);
    try {
      final bytes = await widget.document.file.readAsBytes();
      final compressed = await PdfToolsService.instance.compress(bytes, _level);
      final baseName = '${_stripExtension(widget.document.name)}-compresse';
      final file = await PdfToolsService.instance.saveBytesAsNewFile(compressed, baseName: baseName);
      await ref.read(filesProvider.notifier).refresh();
      if (!mounted) return;

      final originalKb = (bytes.length / 1024).toStringAsFixed(0);
      final newKb = (compressed.length / 1024).toStringAsFixed(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.tp('compressResult', {'originalKb': originalKb, 'newKb': newKb}))),
      );

      final doc = DocumentFile.fromFile(file, createdByApp: true);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PdfViewerScreen(document: doc)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.tp('commonErrorPrefix', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  String _stripExtension(String name) => name.replaceAll(RegExp(r'\.[^.]+$'), '');

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t('compressTitle'))),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.document.name,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(widget.document.formattedSize, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Text(t('compressLevelLabel'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _LevelTile(
              title: t('compressLow'),
              subtitle: t('compressLowDesc'),
              selected: _level == CompressionLevel.low,
              onTap: () => setState(() => _level = CompressionLevel.low),
            ),
            _LevelTile(
              title: t('compressMedium'),
              subtitle: t('compressMediumDesc'),
              selected: _level == CompressionLevel.medium,
              onTap: () => setState(() => _level = CompressionLevel.medium),
            ),
            _LevelTile(
              title: t('compressHigh'),
              subtitle: t('compressHighDesc'),
              selected: _level == CompressionLevel.high,
              onTap: () => setState(() => _level = CompressionLevel.high),
            ),
            const Spacer(),
            LoadingButton(
              label: t('compressButton'),
              icon: Icons.compress_rounded,
              loading: _working,
              onPressed: _compress,
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LevelTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? AppColors.primaryLight : null,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12.5)),
        trailing: Icon(
          selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
          color: selected ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }
}
