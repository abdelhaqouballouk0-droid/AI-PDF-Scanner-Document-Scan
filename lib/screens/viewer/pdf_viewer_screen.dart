import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../models/document_file.dart';
import '../../providers/files_provider.dart';
import '../../theme/app_theme.dart';
import '../tools/convert_screen.dart';
import '../tools/fill_sign_screen.dart';
import '../tools/more_tools_screen.dart';
import '../tools/organize_pages_screen.dart';
import '../../services/conversion_service.dart';

enum _AnnotationTool { none, highlight, underline, strikethrough }

/// The in-app PDF reader/editor. Viewing, page navigation, zoom and text
/// search are all handled by Syncfusion's `SfPdfViewer`; the bottom bar
/// routes to the heavier tools (organize pages, fill & sign, convert,
/// the full tools grid) which each work on this same file.
class PdfViewerScreen extends ConsumerStatefulWidget {
  final DocumentFile document;

  const PdfViewerScreen({super.key, required this.document});

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  final _controller = PdfViewerController();
  final _pdfViewerKey = GlobalKey<SfPdfViewerState>();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  bool _searching = false;
  final _searchController = TextEditingController();

  _AnnotationTool _armedTool = _AnnotationTool.none;
  bool _hasSelection = false;
  bool _savingAnnotations = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchResult.clear();
        _searchController.clear();
      }
    });
  }

  void _runSearch(String query) {
    if (query.trim().isEmpty) return;
    final result = _controller.searchText(query.trim());
    setState(() => _searchResult = result);
  }

  void _armTool(_AnnotationTool tool) {
    setState(() => _armedTool = _armedTool == tool ? _AnnotationTool.none : tool);
  }

  void _onTextSelectionChanged(PdfTextSelectionChangedDetails details) {
    setState(() => _hasSelection = details.selectedText != null);
    if (details.selectedText == null || _armedTool == _AnnotationTool.none) return;

    final lines = _pdfViewerKey.currentState?.getSelectedTextLines();
    if (lines == null || lines.isEmpty) {
      return;
    }

    try {
      switch (_armedTool) {
        case _AnnotationTool.highlight:
          _controller.addAnnotation(HighlightAnnotation(textBoundsCollection: lines));
          break;
        case _AnnotationTool.underline:
          _controller.addAnnotation(UnderlineAnnotation(textBoundsCollection: lines));
          break;
        case _AnnotationTool.strikethrough:
          _controller.addAnnotation(StrikethroughAnnotation(textBoundsCollection: lines));
          break;
        case _AnnotationTool.none:
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Annotation impossible : $e')),
      );
    }
    _controller.clearSelection();
  }

  Future<void> _saveAnnotations() async {
    setState(() => _savingAnnotations = true);
    try {
      final bytes = await _controller.saveDocument();
      await widget.document.file.writeAsBytes(bytes, flush: true);
      await ref.read(filesProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modifications enregistrées')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _savingAnnotations = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.document.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => SharePlus.instance.share(
              ShareParams(files: [XFile(widget.document.path)], text: widget.document.name),
            ),
          ),
          if (_armedTool != _AnnotationTool.none)
            IconButton(
              icon: _savingAnnotations
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              onPressed: _savingAnnotations ? null : _saveAnnotations,
            ),
        ],
        bottom: _searching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: const InputDecoration(hintText: 'Rechercher dans le document'),
                          onSubmitted: _runSearch,
                        ),
                      ),
                      if (_searchResult.hasResult) ...[
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_up_rounded),
                          onPressed: () => _searchResult.previousInstance(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          onPressed: () => _searchResult.nextInstance(),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            : (_armedTool != _AnnotationTool.none
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(44),
                    child: Container(
                      color: AppColors.primaryLight,
                      alignment: Alignment.center,
                      child: Text(
                        _hasSelection
                            ? 'Relâche pour appliquer l\'annotation'
                            : 'Sélectionne du texte pour l\'annoter',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.primaryDark),
                      ),
                    ),
                  )
                : null),
      ),
      body: SfPdfViewer.file(
        widget.document.file,
        key: _pdfViewerKey,
        controller: _controller,
        onTextSelectionChanged: _onTextSelectionChanged,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _BarAction(
                icon: Icons.edit_note_rounded,
                label: 'Éditer',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => OrganizePagesScreen(document: widget.document)),
                ),
              ),
              _BarAction(
                icon: Icons.border_color_outlined,
                label: 'Annoter',
                active: _armedTool != _AnnotationTool.none,
                onTap: () => _showAnnotateMenu(context),
              ),
              _BarAction(
                icon: Icons.draw_outlined,
                label: 'Signer',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => FillSignScreen(document: widget.document)),
                ),
              ),
              _BarAction(
                icon: Icons.swap_horiz_rounded,
                label: 'Convertir',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ConvertScreen(
                      kind: ConversionKind.pdfToImage,
                      initialDocument: widget.document,
                    ),
                  ),
                ),
              ),
              _BarAction(
                icon: Icons.apps_rounded,
                label: 'Tout',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => MoreToolsScreen(document: widget.document)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnnotateMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.border_color_outlined, color: Color(0xFFFBC02D)),
              title: const Text('Surligner'),
              trailing: _armedTool == _AnnotationTool.highlight ? const Icon(Icons.check) : null,
              onTap: () {
                Navigator.pop(ctx);
                _armTool(_AnnotationTool.highlight);
              },
            ),
            ListTile(
              leading: const Icon(Icons.format_underline_rounded, color: AppColors.info),
              title: const Text('Souligner'),
              trailing: _armedTool == _AnnotationTool.underline ? const Icon(Icons.check) : null,
              onTap: () {
                Navigator.pop(ctx);
                _armTool(_AnnotationTool.underline);
              },
            ),
            ListTile(
              leading: const Icon(Icons.strikethrough_s_rounded, color: AppColors.primary),
              title: const Text('Barrer'),
              trailing: _armedTool == _AnnotationTool.strikethrough ? const Icon(Icons.check) : null,
              onTap: () {
                Navigator.pop(ctx);
                _armTool(_AnnotationTool.strikethrough);
              },
            ),
            if (_armedTool != _AnnotationTool.none)
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: const Text('Désactiver l\'annotation'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _armedTool = _AnnotationTool.none);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _BarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _BarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
