import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/document_file.dart';
import '../../models/document_type.dart';
import '../../providers/files_provider.dart';
import '../../services/conversion_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../files/files_screen.dart';
import '../settings/settings_screen.dart';
import '../viewer/pdf_viewer_screen.dart';

/// One screen for every entry in "Convert to PDF" / "Convert from PDF":
/// [kind] decides which source file type it accepts and which
/// [ConversionService] method it calls.
class ConvertScreen extends ConsumerStatefulWidget {
  final ConversionKind kind;
  final DocumentFile? initialDocument;

  const ConvertScreen({super.key, required this.kind, this.initialDocument});

  @override
  ConsumerState<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends ConsumerState<ConvertScreen> {
  DocumentFile? _document;
  List<File> _images = [];
  bool _working = false;
  List<File> _resultFiles = [];

  @override
  void initState() {
    super.initState();
    _document = widget.initialDocument;
  }

  bool get _isImageToPdf => widget.kind == ConversionKind.imageToPdf;

  Future<void> _pickSource() async {
    if (_isImageToPdf) {
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isEmpty) return;
      setState(() => _images = files.map((f) => f.path).whereType<String>().map((p) => File(p)).toList());
      return;
    }

    // Pick an existing document from the in-app library so the source is
    // always something the Files/Home screens already know about.
    final picked = await Navigator.of(context).push<DocumentFile>(
      MaterialPageRoute(builder: (_) => const FilesScreen(pickMode: true)),
    );
    if (picked != null) setState(() => _document = picked);
  }

  Future<void> _convert() async {
    setState(() {
      _working = true;
      _resultFiles = [];
    });
    try {
      final service = ConversionService.instance;
      switch (widget.kind) {
        case ConversionKind.imageToPdf:
          if (_images.isEmpty) return;
          final file = await service.imagesToPdf(_images);
          _resultFiles = [file];
          break;
        case ConversionKind.pdfToImage:
          if (_document == null) return;
          _resultFiles = await service.pdfToImages(_document!.file);
          break;
        case ConversionKind.wordToPdf:
          if (_document == null) return;
          _resultFiles = [await service.wordToPdf(_document!.file)];
          break;
        case ConversionKind.excelToPdf:
          if (_document == null) return;
          _resultFiles = [await service.excelToPdf(_document!.file)];
          break;
        case ConversionKind.pdfToWord:
          if (_document == null) return;
          _resultFiles = [await service.pdfToWord(_document!.file)];
          break;
        case ConversionKind.pdfToExcel:
          if (_document == null) return;
          _resultFiles = [await service.pdfToExcel(_document!.file)];
          break;
      }
      await ref.read(filesProvider.notifier).refresh();
    } on ConversionBackendNotConfigured catch (e) {
      if (!mounted) return;
      _showBackendDialog(e.message);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _showBackendDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Serveur de conversion requis'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
            child: const Text('Ouvrir Réglages'),
          ),
        ],
      ),
    );
  }

  bool get _canConvert => _isImageToPdf ? _images.isNotEmpty : _document != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.kind.title)),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.kind.isOnDevice)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Cette conversion nécessite un serveur configuré dans Réglages > Conversion '
                  '(LibreOffice/Gotenberg auto-hébergé ou API type CloudConvert).',
                  style: TextStyle(fontSize: 12.5, color: AppColors.primaryDark),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _pickSource,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(_isImageToPdf
                  ? (_images.isEmpty ? 'Choisir des images' : '${_images.length} image(s) sélectionnée(s)')
                  : (_document?.name ?? 'Choisir un fichier')),
            ),
            const SizedBox(height: 20),
            LoadingButton(
              label: 'Convertir',
              icon: Icons.swap_horiz_rounded,
              loading: _working,
              onPressed: _canConvert ? _convert : null,
            ),
            const SizedBox(height: 20),
            if (_resultFiles.isNotEmpty) ...[
              const Text('Résultat', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _resultFiles.length,
                  itemBuilder: (context, index) {
                    final file = _resultFiles[index];
                    final doc = DocumentFile.fromFile(file, createdByApp: true);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(doc.type.icon, color: doc.type.color),
                        title: Text(doc.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(doc.formattedSize),
                        trailing: doc.type == DocumentType.pdf
                            ? const Icon(Icons.chevron_right_rounded)
                            : null,
                        onTap: doc.type == DocumentType.pdf
                            ? () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => PdfViewerScreen(document: doc)),
                                )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
