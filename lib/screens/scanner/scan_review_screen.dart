import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import '../../l10n/app_localizations.dart';
import '../../models/document_file.dart';
import '../../providers/files_provider.dart';
import '../../services/document_scanner_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../viewer/pdf_viewer_screen.dart';

/// Shown right after the native document scanner returns: lets the user
/// reorder pages, drop bad captures, name the file and choose a page
/// size before the pages are flattened into a single PDF.
class ScanReviewScreen extends ConsumerStatefulWidget {
  final List<String> imagePaths;

  const ScanReviewScreen({super.key, required this.imagePaths});

  @override
  ConsumerState<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends ConsumerState<ScanReviewScreen> {
  late List<String> _pages;
  late final TextEditingController _nameController;
  PdfPageFormat _pageFormat = PdfPageFormat.a4;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pages = List.of(widget.imagePaths);
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_pages.isEmpty) return;
    final t = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      final defaultName = t('scanDefaultName');
      final file = await DocumentScannerService.instance.buildPdfFromImages(
        _pages,
        outputBaseName: _nameController.text.trim().isEmpty ? defaultName : _nameController.text.trim(),
        pageSize: _pageFormat,
      );
      await ref.read(filesProvider.notifier).refresh();
      if (!mounted) return;
      final doc = DocumentFile.fromFile(file, createdByApp: true, pageCount: _pages.length);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PdfViewerScreen(document: doc)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.tp('commonErrorPrefix', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.tp('scanReviewTitle', {'count': '${_pages.length}'})),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: t('scanDocumentNameLabel'),
                hintText: t('scanDefaultName'),
                prefixIcon: const Icon(Icons.edit_outlined),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('${t('scanFormatLabel')} ', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('A4'),
                  selected: _pageFormat == PdfPageFormat.a4,
                  onSelected: (_) => setState(() => _pageFormat = PdfPageFormat.a4),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Letter'),
                  selected: _pageFormat == PdfPageFormat.letter,
                  onSelected: (_) => setState(() => _pageFormat = PdfPageFormat.letter),
                ),
              ],
            ),
          ),
          Expanded(
            child: _pages.isEmpty
                ? EmptyState(
                    icon: Icons.image_not_supported_outlined,
                    title: t('scanNoPagesTitle'),
                    message: t('scanNoPagesMessage'),
                  )
                : ReorderableGridView(
                    pages: _pages,
                    onReorder: (from, to) {
                      setState(() {
                        final item = _pages.removeAt(from);
                        _pages.insert(to, item);
                      });
                    },
                    onDelete: (index) => setState(() => _pages.removeAt(index)),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LoadingButton(
                label: t('scanSaveAsPdf'),
                icon: Icons.picture_as_pdf_rounded,
                loading: _saving,
                onPressed: _pages.isEmpty ? null : _save,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReorderableGridView extends StatelessWidget {
  final List<String> pages;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onDelete;

  const ReorderableGridView({
    super.key,
    required this.pages,
    required this.onReorder,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: pages.length,
      onReorderItem: onReorder,
      itemBuilder: (context, index) {
        final path = pages[index];
        return Card(
          key: ValueKey(path),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(path), width: 48, height: 62, fit: BoxFit.cover),
            ),
            title: Text(t.tp('organizePage', {'number': '${index + 1}'})),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.primary),
                  onPressed: () => onDelete(index),
                ),
                const Icon(Icons.drag_handle_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }
}
