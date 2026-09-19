import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../models/document_file.dart';
import '../../providers/files_provider.dart';
import '../../services/pdf_tools_service.dart';
import '../../theme/app_theme.dart';
import '../viewer/pdf_viewer_screen.dart';
import 'split_pdf_screen.dart';

class _PageEntry {
  final Uint8List sourceBytes;
  final int pageIndex;
  int rotation = 0;
  Uint8List? thumbnail;

  _PageEntry({required this.sourceBytes, required this.pageIndex});
}

/// Page-level editing for a single PDF: drag to reorder, rotate, delete,
/// extract a selection to a new file, insert another PDF's pages, or jump
/// into Split/Merge. Every action here goes through
/// [PdfToolsService.buildFromPages], so "Save" always produces a real,
/// valid rebuilt PDF.
class OrganizePagesScreen extends ConsumerStatefulWidget {
  final DocumentFile document;

  const OrganizePagesScreen({super.key, required this.document});

  @override
  ConsumerState<OrganizePagesScreen> createState() => _OrganizePagesScreenState();
}

class _OrganizePagesScreenState extends ConsumerState<OrganizePagesScreen> {
  List<_PageEntry> _pages = [];
  final Set<int> _selected = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await widget.document.file.readAsBytes();
    final count = await PdfToolsService.instance.getPageCount(bytes);
    final entries = List.generate(count, (i) => _PageEntry(sourceBytes: bytes, pageIndex: i));
    setState(() {
      _pages = entries;
      _loading = false;
    });
    for (var i = 0; i < entries.length; i++) {
      final thumb = await PdfToolsService.instance.renderPageImage(bytes, i, dpi: 70);
      if (!mounted) return;
      setState(() => entries[i].thumbnail = thumb);
    }
  }

  void _toggleSelect(int uid) {
    setState(() {
      if (_selected.contains(uid)) {
        _selected.remove(uid);
      } else {
        _selected.add(uid);
      }
    });
  }

  List<int> get _targetIndices =>
      _selected.isEmpty ? List.generate(_pages.length, (i) => i) : _selected.toList()..sort();

  void _rotateSelected() {
    setState(() {
      for (final i in _targetIndices) {
        _pages[i].rotation = (_pages[i].rotation + 90) % 360;
      }
    });
  }

  void _deleteSelected() {
    if (_selected.isEmpty) return;
    setState(() {
      final indices = _selected.toList()..sort((a, b) => b.compareTo(a));
      for (final i in indices) {
        _pages.removeAt(i);
      }
      _selected.clear();
    });
  }

  Future<void> _insertPdf() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final path = picked?.path;
    if (path == null) return;
    final bytes = await File(path).readAsBytes();
    final count = await PdfToolsService.instance.getPageCount(bytes);
    setState(() {
      _pages.addAll(List.generate(count, (i) => _PageEntry(sourceBytes: bytes, pageIndex: i)));
    });
    for (var i = _pages.length - count; i < _pages.length; i++) {
      final thumb = await PdfToolsService.instance.renderPageImage(bytes, _pages[i].pageIndex, dpi: 70);
      if (!mounted) return;
      setState(() => _pages[i].thumbnail = thumb);
    }
  }

  Future<void> _extractSelected() async {
    final t = AppLocalizations.of(context)!;
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('organizeExtractSelectFirst'))),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final refs = _selected.toList()
        ..sort();
      final built = await PdfToolsService.instance.buildFromPages([
        for (final i in refs)
          PdfPageRef(
            sourceBytes: _pages[i].sourceBytes,
            pageIndex: _pages[i].pageIndex,
            extraRotationDegrees: _pages[i].rotation,
          ),
      ]);
      final file = await PdfToolsService.instance.saveBytesAsNewFile(
        built,
        baseName: '${_baseName(widget.document.name)}-extrait',
      );
      await ref.read(filesProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.tp('organizeExtractedCount', {
          'count': '${refs.length}',
          'fileName': file.uri.pathSegments.last,
        }))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openSplit() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SplitPdfScreen(document: widget.document)),
    );
  }

  Future<void> _save() async {
    if (_pages.isEmpty) return;
    final t = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      final built = await PdfToolsService.instance.buildFromPages([
        for (final p in _pages)
          PdfPageRef(sourceBytes: p.sourceBytes, pageIndex: p.pageIndex, extraRotationDegrees: p.rotation),
      ]);
      await widget.document.file.writeAsBytes(built, flush: true);
      await ref.read(filesProvider.notifier).refresh();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PdfViewerScreen(document: widget.document)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.tp('commonErrorPrefix', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _baseName(String name) => name.replaceAll(RegExp(r'\.[^.]+$'), '');

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('organizeTitle')),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_rounded),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_selected.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: AppColors.primaryLight,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(t.tp('organizeSelectedCount', {'count': '${_selected.length}'}),
                        style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                  ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pages.length,
                    onReorderItem: (oldIndex, newIndex) {
                      setState(() {
                        final item = _pages.removeAt(oldIndex);
                        _pages.insert(newIndex, item);
                        // Index-based selection would silently point at the
                        // wrong pages after a reorder, so clear it instead.
                        _selected.clear();
                      });
                    },
                    itemBuilder: (context, index) {
                      final entry = _pages[index];
                      final selected = _selected.contains(index);
                      return Card(
                        key: ObjectKey(entry),
                        margin: const EdgeInsets.only(bottom: 10),
                        color: selected ? AppColors.primaryLight : null,
                        child: ListTile(
                          onLongPress: () => _toggleSelect(index),
                          onTap: _selected.isNotEmpty ? () => _toggleSelect(index) : null,
                          leading: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 48,
                                  height: 62,
                                  child: entry.thumbnail == null
                                      ? const ColoredBox(color: AppColors.divider)
                                      : Transform.rotate(
                                          angle: entry.rotation * 3.1415926535 / 180,
                                          child: Image.memory(entry.thumbnail!, fit: BoxFit.cover),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(t.tp('organizePage', {'number': '${index + 1}'})),
                          subtitle: entry.rotation != 0
                              ? Text(t.tp('organizeRotatedBy', {'degrees': '${entry.rotation}'}))
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                              const SizedBox(width: 6),
                              const Icon(Icons.drag_handle_rounded, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _BottomAction(icon: Icons.rotate_right_rounded, label: t('organizeRotate'), onTap: _rotateSelected),
                        _BottomAction(icon: Icons.delete_outline_rounded, label: t('organizeDelete'), onTap: _deleteSelected),
                        _BottomAction(icon: Icons.crop_free_rounded, label: t('organizeExtract'), onTap: _extractSelected),
                        _BottomAction(icon: Icons.playlist_add_rounded, label: t('organizeInsert'), onTap: _insertPdf),
                        _BottomAction(icon: Icons.call_split_rounded, label: t('organizeSplit'), onTap: _openSplit),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10.5)),
          ],
        ),
      ),
    );
  }
}
