import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localizations.dart';
import '../../models/document_file.dart';
import '../../models/document_type.dart';
import '../../providers/files_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/open_file_helper.dart';
import '../viewer/pdf_viewer_screen.dart';

class FilesScreen extends ConsumerStatefulWidget {
  final DocumentType? initialType;

  /// When true, tapping a file returns it via [Navigator.pop] instead of
  /// opening the viewer — used by tool screens that need the user to pick
  /// a document from the library (e.g. "Convert", "Compress", "Split").
  final bool pickMode;

  const FilesScreen({super.key, this.initialType, this.pickMode = false});

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen> {
  DocumentType? _selectedType;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  Future<void> _handleAction(String action, DocumentFile file) async {
    switch (action) {
      case 'open':
        _open(file);
        break;
      case 'share':
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: file.name));
        break;
      case 'rename':
        await _rename(file);
        break;
      case 'delete':
        await _delete(file);
        break;
    }
  }

  void _open(DocumentFile file) {
    if (widget.pickMode) {
      Navigator.of(context).pop(file);
      return;
    }
    if (file.type == DocumentType.pdf) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => PdfViewerScreen(document: file)));
    } else {
      OpenFileFallback.open(context, file);
    }
  }

  Future<void> _rename(DocumentFile file) async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: file.name.replaceAll(RegExp(r'\.[^.]+$'), ''),
    );
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('filesRenameTitle')),
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
    if (newName == null || newName.isEmpty) return;
    await ref.read(filesProvider.notifier).rename(file, newName);
  }

  Future<void> _delete(DocumentFile file) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('filesDeleteTitle')),
        content: Text(file.name),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('commonCancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('commonDelete'), style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(filesProvider.notifier).delete(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final files = ref.watch(filteredFilesProvider(_selectedType));
    final visible = _query.isEmpty
        ? files
        : files.where((f) => f.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.pickMode ? t('filesPickTitle') : t('filesTitle'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: t('filesSearchHint'),
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(label: t('filesFilterAll'), selected: _selectedType == null, onTap: () => setState(() => _selectedType = null)),
                for (final type in DocumentType.values)
                  _FilterChip(
                    label: type.labelFor(t),
                    selected: _selectedType == type,
                    onTap: () => setState(() => _selectedType = type),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: visible.isEmpty
                ? EmptyState(
                    icon: Icons.folder_off_outlined,
                    title: t('filesEmptyTitle'),
                    message: t('filesEmptyMessage'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final file = visible[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => _open(file),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: file.type.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(file.type.icon, color: file.type.color, size: 20),
                          ),
                          title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(t.tp('filesModifiedOn', {'date': _formatDate(t, file.modifiedAt)})),
                          trailing: widget.pickMode
                              ? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted)
                              : PopupMenuButton<String>(
                                  onSelected: (action) => _handleAction(action, file),
                                  itemBuilder: (_) => [
                                    PopupMenuItem(value: 'open', child: Text(t('filesMenuOpen'))),
                                    PopupMenuItem(value: 'share', child: Text(t('filesMenuShare'))),
                                    PopupMenuItem(value: 'rename', child: Text(t('filesMenuRename'))),
                                    PopupMenuItem(value: 'delete', child: Text(t('filesMenuDelete'))),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(AppLocalizations t, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return t('commonToday');
    if (diff.inDays == 1) return t('commonYesterday');
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
