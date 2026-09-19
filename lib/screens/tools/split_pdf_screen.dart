import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/document_file.dart';
import '../../providers/files_provider.dart';
import '../../services/pdf_tools_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// Splits a PDF into several files. The user marks "cut points" after any
/// page; each contiguous group of pages between cut points becomes its
/// own output file.
class SplitPdfScreen extends ConsumerStatefulWidget {
  final DocumentFile document;

  const SplitPdfScreen({super.key, required this.document});

  @override
  ConsumerState<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends ConsumerState<SplitPdfScreen> {
  Uint8List? _bytes;
  int _pageCount = 0;
  final List<Uint8List?> _thumbnails = [];
  final Set<int> _cutAfter = {};
  bool _loading = true;
  bool _splitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await widget.document.file.readAsBytes();
    final count = await PdfToolsService.instance.getPageCount(bytes);
    setState(() {
      _bytes = bytes;
      _pageCount = count;
      _thumbnails.addAll(List.filled(count, null));
      _loading = false;
    });
    for (var i = 0; i < count; i++) {
      final thumb = await PdfToolsService.instance.renderPageImage(bytes, i, dpi: 70);
      if (!mounted) return;
      setState(() => _thumbnails[i] = thumb);
    }
  }

  List<({int start, int end})> get _ranges {
    final ranges = <({int start, int end})>[];
    var start = 0;
    for (var i = 0; i < _pageCount; i++) {
      if (_cutAfter.contains(i)) {
        ranges.add((start: start, end: i));
        start = i + 1;
      }
    }
    if (start <= _pageCount - 1) {
      ranges.add((start: start, end: _pageCount - 1));
    }
    return ranges;
  }

  Future<void> _split() async {
    if (_bytes == null) return;
    final t = AppLocalizations.of(context)!;
    setState(() => _splitting = true);
    try {
      final parts = await PdfToolsService.instance.splitDocument(_bytes!, _ranges);
      final baseName = widget.document.name.replaceAll(RegExp(r'\.[^.]+$'), '');
      for (var i = 0; i < parts.length; i++) {
        await PdfToolsService.instance.saveBytesAsNewFile(
          parts[i],
          baseName: '$baseName-partie${i + 1}',
        );
      }
      await ref.read(filesProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.tp('splitDone', {'count': '${parts.length}'}))),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.tp('commonErrorPrefix', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _splitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t('splitTitle'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    t.tp('splitInfo', {'count': '${_ranges.length}'}),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _pageCount,
                    itemBuilder: (context, index) {
                      final thumb = _thumbnails[index];
                      final isCut = _cutAfter.contains(index);
                      return Column(
                        children: [
                          Card(
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 46,
                                  height: 60,
                                  child: thumb == null
                                      ? const ColoredBox(color: AppColors.divider)
                                      : Image.memory(thumb, fit: BoxFit.cover),
                                ),
                              ),
                              title: Text(t.tp('organizePage', {'number': '${index + 1}'})),
                            ),
                          ),
                          if (index != _pageCount - 1)
                            InkWell(
                              onTap: () => setState(() {
                                if (isCut) {
                                  _cutAfter.remove(index);
                                } else {
                                  _cutAfter.add(index);
                                }
                              }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: isCut ? AppColors.primary : AppColors.divider,
                                        thickness: isCut ? 2 : 1,
                                      ),
                                    ),
                                    Icon(
                                      Icons.content_cut_rounded,
                                      size: 18,
                                      color: isCut ? AppColors.primary : AppColors.textMuted,
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: isCut ? AppColors.primary : AppColors.divider,
                                        thickness: isCut ? 2 : 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LoadingButton(
                      label: t.tp('splitButton', {'count': '${_ranges.length}'}),
                      loading: _splitting,
                      onPressed: _pageCount < 2 ? null : _split,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
