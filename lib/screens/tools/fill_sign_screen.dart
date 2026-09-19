import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import '../../l10n/app_localizations.dart';
import '../../models/document_file.dart';
import '../../providers/files_provider.dart';
import '../../providers/signature_provider.dart';
import '../../services/pdf_tools_service.dart';
import '../../services/signature_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/signature_pad_sheet.dart';
import '../viewer/pdf_viewer_screen.dart';

/// Lets the user place a saved (or freshly drawn) signature anywhere on a
/// page, then flattens it into the PDF for real via
/// [SignatureService.stampSignature].
class FillSignScreen extends ConsumerStatefulWidget {
  final DocumentFile document;

  const FillSignScreen({super.key, required this.document});

  @override
  ConsumerState<FillSignScreen> createState() => _FillSignScreenState();
}

class _FillSignScreenState extends ConsumerState<FillSignScreen> {
  Uint8List? _pdfBytes;
  Uint8List? _pageImage;
  int _pageCount = 0;
  int _pageIndex = 0;
  bool _loadingPage = true;

  Uint8List? _signatureBytes;
  double _x = 0.35;
  double _y = 0.75;
  double _widthFraction = 0.32;
  double _pageAspect = 0.72;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await widget.document.file.readAsBytes();
    final count = await PdfToolsService.instance.getPageCount(bytes);
    setState(() {
      _pdfBytes = bytes;
      _pageCount = count;
    });
    await _loadPageImage();
  }

  Future<void> _loadPageImage() async {
    if (_pdfBytes == null) return;
    setState(() => _loadingPage = true);
    final image = await PdfToolsService.instance.renderPageImage(_pdfBytes!, _pageIndex, dpi: 130);
    final decoded = img.decodePng(image);
    if (!mounted) return;
    setState(() {
      _pageImage = image;
      if (decoded != null && decoded.height > 0) {
        _pageAspect = decoded.width / decoded.height;
      }
      _loadingPage = false;
    });
  }

  Future<void> _pickSignature() async {
    final t = AppLocalizations.of(context)!;
    final signatures = ref.read(signatureProvider).valueOrNull ?? [];
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.draw_outlined, color: AppColors.primary),
              title: Text(t('fillSignDrawNew')),
              onTap: () => Navigator.pop(ctx, '__new__'),
            ),
            const Divider(height: 1),
            for (final s in signatures)
              ListTile(
                leading: const Icon(Icons.history_edu_rounded),
                title: Text(s.name),
                onTap: () => Navigator.pop(ctx, s.id),
              ),
          ],
        ),
      ),
    );

    if (choice == null) return;
    if (choice == '__new__') {
      if (!mounted) return;
      final bytes = await showSignaturePad(context);
      if (bytes != null) setState(() => _signatureBytes = bytes);
      return;
    }
    final signatures2 = ref.read(signatureProvider).valueOrNull ?? [];
    final model = signatures2.firstWhere((s) => s.id == choice);
    final bytes = await File(model.imagePath).readAsBytes();
    setState(() => _signatureBytes = bytes);
  }

  Future<void> _confirm() async {
    if (_pdfBytes == null || _signatureBytes == null) return;
    final t = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      final signed = await SignatureService.instance.stampSignature(
        pdfBytes: _pdfBytes!,
        signaturePngBytes: _signatureBytes!,
        pageIndex: _pageIndex,
        xFraction: _x,
        yFraction: _y,
        widthFraction: _widthFraction,
      );
      final baseName = '${_stripExtension(widget.document.name)}-signed';
      final file = await PdfToolsService.instance.saveBytesAsNewFile(signed, baseName: baseName);
      await ref.read(filesProvider.notifier).refresh();
      if (!mounted) return;
      final doc = DocumentFile.fromFile(file, createdByApp: true);
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

  String _stripExtension(String name) => name.replaceAll(RegExp(r'\.[^.]+$'), '');

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('fillSignTitle')),
        actions: [
          if (_pageCount > 1)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: DropdownButton<int>(
                  value: _pageIndex,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (var i = 0; i < _pageCount; i++)
                      DropdownMenuItem(value: i, child: Text(t.tp('fillSignPage', {'number': '${i + 1}'}))),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _pageIndex = value);
                    _loadPageImage();
                  },
                ),
              ),
            ),
        ],
      ),
      body: _loadingPage || _pageImage == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _pageAspectRatio(),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.memory(_pageImage!, fit: BoxFit.contain),
                          ),
                          if (_signatureBytes != null)
                            LayoutBuilder(
                              builder: (context, box) {
                                final width = box.maxWidth * _widthFraction;
                                return Positioned(
                                  left: box.maxWidth * _x,
                                  top: box.maxHeight * _y,
                                  width: width,
                                  child: GestureDetector(
                                    onPanUpdate: (details) {
                                      setState(() {
                                        _x = (_x + details.delta.dx / box.maxWidth)
                                            .clamp(0.0, 1.0 - _widthFraction);
                                        _y = (_y + details.delta.dy / box.maxHeight)
                                            .clamp(0.0, 0.95);
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.primary, width: 1.4),
                                      ),
                                      child: Image.memory(_signatureBytes!),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_size_select_small_rounded, size: 20),
                      Expanded(
                        child: Slider(
                          value: _widthFraction,
                          min: 0.12,
                          max: 0.7,
                          onChanged: _signatureBytes == null
                              ? null
                              : (v) => setState(() => _widthFraction = v),
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickSignature,
                            icon: const Icon(Icons.draw_outlined),
                            label: Text(_signatureBytes == null ? t('fillSignChooseSignature') : t('fillSignChange')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LoadingButton(
                            label: t('fillSignConfirm'),
                            loading: _saving,
                            onPressed: _signatureBytes == null ? null : _confirm,
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

  double _pageAspectRatio() => _pageAspect;
}
