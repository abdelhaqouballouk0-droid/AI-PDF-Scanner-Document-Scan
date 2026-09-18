import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/document_file.dart';
import '../../models/document_type.dart';
import '../../providers/files_provider.dart';
import '../../services/pdf_tools_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../files/files_screen.dart';
import '../viewer/pdf_viewer_screen.dart';

class MergePdfScreen extends ConsumerStatefulWidget {
  const MergePdfScreen({super.key});

  @override
  ConsumerState<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends ConsumerState<MergePdfScreen> {
  final List<DocumentFile> _selected = [];
  bool _merging = false;

  Future<void> _addFile() async {
    final picked = await Navigator.of(context).push<DocumentFile>(
      MaterialPageRoute(builder: (_) => const FilesScreen(pickMode: true, initialType: DocumentType.pdf)),
    );
    if (picked != null && !_selected.any((f) => f.path == picked.path)) {
      setState(() => _selected.add(picked));
    }
  }

  Future<void> _merge() async {
    if (_selected.length < 2) return;
    setState(() => _merging = true);
    try {
      final bytesList = await Future.wait(_selected.map((f) => f.file.readAsBytes()));
      final merged = await PdfToolsService.instance.mergeDocuments(bytesList);
      final file = await PdfToolsService.instance.saveBytesAsNewFile(
        merged,
        baseName: 'Fusion',
        subFolder: 'Merged',
      );
      await ref.read(filesProvider.notifier).refresh();
      if (!mounted) return;
      final doc = DocumentFile.fromFile(file, createdByApp: true);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PdfViewerScreen(document: doc)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _merging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fusionner des PDF')),
      body: Column(
        children: [
          Expanded(
            child: _selected.isEmpty
                ? const EmptyState(
                    icon: Icons.call_merge_rounded,
                    title: 'Aucun fichier ajouté',
                    message: 'Ajoute au moins deux PDF, dans l\'ordre où tu veux les fusionner.',
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _selected.length,
                    onReorderItem: (oldIndex, newIndex) {
                      setState(() {
                        final item = _selected.removeAt(oldIndex);
                        _selected.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final f = _selected[index];
                      return Card(
                        key: ValueKey(f.path),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.pdfColor.withValues(alpha: 0.1),
                            child: Text('${index + 1}', style: const TextStyle(color: AppColors.pdfColor)),
                          ),
                          title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(f.formattedSize),
                          trailing: IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(() => _selected.removeAt(index)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addFile,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Ajouter'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LoadingButton(
                      label: 'Fusionner',
                      loading: _merging,
                      onPressed: _selected.length >= 2 ? _merge : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
