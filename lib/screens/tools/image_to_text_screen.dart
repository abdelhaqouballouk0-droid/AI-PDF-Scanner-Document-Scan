import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/document_type.dart';
import '../../services/ocr_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// Real on-device OCR (ML Kit) for a picked image or scanned PDF.
class ImageToTextScreen extends StatefulWidget {
  const ImageToTextScreen({super.key});

  @override
  State<ImageToTextScreen> createState() => _ImageToTextScreenState();
}

class _ImageToTextScreenState extends State<ImageToTextScreen> {
  File? _source;
  String? _text;
  bool _working = false;

  Future<void> _pick() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    final path = picked?.path;
    if (path == null) return;
    setState(() {
      _source = File(path);
      _text = null;
    });
    await _run();
  }

  Future<void> _run() async {
    if (_source == null) return;
    setState(() => _working = true);
    try {
      final ext = DocumentTypeX.fromExtension(_source!.path.split('.').last);
      final text = ext == DocumentType.pdf
          ? await OcrService.instance.recognizePdf(_source!)
          : await OcrService.instance.recognizeImage(_source!);
      setState(() => _text = text.isEmpty ? 'Aucun texte détecté.' : text);
    } catch (e) {
      setState(() => _text = 'Erreur OCR : $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image en texte (OCR)'),
        actions: [
          if (_text != null) ...[
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _text!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Texte copié')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: () => SharePlus.instance.share(ShareParams(text: _text!)),
            ),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.image_search_rounded),
              label: Text(_source == null ? 'Choisir une image ou un PDF' : _source!.path.split('/').last),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _working
                  ? const Center(child: CircularProgressIndicator())
                  : _text == null
                      ? const EmptyState(
                          icon: Icons.text_snippet_outlined,
                          title: 'Aucun texte extrait',
                          message: 'Choisis une image ou un PDF scanné pour lancer la reconnaissance de texte.',
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(_text!),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
