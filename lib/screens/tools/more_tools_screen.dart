import 'package:flutter/material.dart';
import '../../models/document_file.dart';
import '../../models/document_type.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../files/files_screen.dart';
import '../viewer/pdf_viewer_screen.dart';
import 'compress_pdf_screen.dart';
import 'convert_screen.dart';
import 'image_to_text_screen.dart';
import 'merge_pdf_screen.dart';
import 'organize_pages_screen.dart';
import 'protect_unlock_screen.dart';
import 'split_pdf_screen.dart';
import '../../services/conversion_service.dart';

/// The full grid of tools (mirrors "More Tools" in the reference app):
/// Convert To PDF, Convert From PDF, and everything else. When [document]
/// is provided (opened from the viewer's "Tout" tab) it's used as the
/// default source wherever a PDF is required; otherwise the tool screen
/// asks the user to pick one from the library.
class MoreToolsScreen extends StatelessWidget {
  final DocumentFile? document;

  const MoreToolsScreen({super.key, this.document});

  Future<DocumentFile?> _resolvePdf(BuildContext context) async {
    if (document != null && document!.type == DocumentType.pdf) return document;
    return Navigator.of(context).push<DocumentFile>(
      MaterialPageRoute(builder: (_) => const FilesScreen(pickMode: true, initialType: DocumentType.pdf)),
    );
  }

  Future<void> _open(BuildContext context, Widget Function(DocumentFile doc) builder) async {
    final doc = await _resolvePdf(context);
    if (doc == null || !context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => builder(doc)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plus d\'outils')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('Convertir en PDF', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _ToolsRow(children: [
            ToolTile(
              icon: Icons.description_rounded,
              label: 'Word en PDF',
              color: AppColors.wordColor,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ConvertScreen(kind: ConversionKind.wordToPdf))),
            ),
            ToolTile(
              icon: Icons.grid_on_rounded,
              label: 'Excel en PDF',
              color: AppColors.excelColor,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ConvertScreen(kind: ConversionKind.excelToPdf))),
            ),
            ToolTile(
              icon: Icons.image_rounded,
              label: 'Image en PDF',
              color: AppColors.imageColor,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ConvertScreen(kind: ConversionKind.imageToPdf))),
            ),
          ]),
          const SizedBox(height: 24),
          const Text('Convertir depuis PDF', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _ToolsRow(children: [
            ToolTile(
              icon: Icons.description_rounded,
              label: 'PDF en Word',
              color: AppColors.wordColor,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ConvertScreen(kind: ConversionKind.pdfToWord, initialDocument: document))),
            ),
            ToolTile(
              icon: Icons.grid_on_rounded,
              label: 'PDF en Excel',
              color: AppColors.excelColor,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ConvertScreen(kind: ConversionKind.pdfToExcel, initialDocument: document))),
            ),
            ToolTile(
              icon: Icons.image_rounded,
              label: 'PDF en JPG',
              color: AppColors.imageColor,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ConvertScreen(kind: ConversionKind.pdfToImage, initialDocument: document))),
            ),
          ]),
          const SizedBox(height: 24),
          const Text('Autres outils', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _ToolsRow(children: [
            ToolTile(
              icon: Icons.text_fields_rounded,
              label: 'Image en texte',
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ImageToTextScreen())),
            ),
            ToolTile(
              icon: Icons.call_merge_rounded,
              label: 'Fusionner',
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const MergePdfScreen())),
            ),
            ToolTile(
              icon: Icons.call_split_rounded,
              label: 'Diviser',
              onTap: () => _open(context, (doc) => SplitPdfScreen(document: doc)),
            ),
          ]),
          const SizedBox(height: 14),
          _ToolsRow(children: [
            ToolTile(
              icon: Icons.compress_rounded,
              label: 'Compresser',
              onTap: () => _open(context, (doc) => CompressPdfScreen(document: doc)),
            ),
            ToolTile(
              icon: Icons.lock_outline_rounded,
              label: 'Protéger',
              onTap: () => _open(
                  context, (doc) => ProtectUnlockScreen(document: doc, mode: ProtectMode.protect)),
            ),
            ToolTile(
              icon: Icons.lock_open_rounded,
              label: 'Déverrouiller',
              onTap: () => _open(
                  context, (doc) => ProtectUnlockScreen(document: doc, mode: ProtectMode.unlock)),
            ),
          ]),
          const SizedBox(height: 14),
          _ToolsRow(children: [
            ToolTile(
              icon: Icons.rotate_right_rounded,
              label: 'Pivoter',
              onTap: () => _open(context, (doc) => OrganizePagesScreen(document: doc)),
            ),
            ToolTile(
              icon: Icons.delete_outline_rounded,
              label: 'Suppr. pages',
              onTap: () => _open(context, (doc) => OrganizePagesScreen(document: doc)),
            ),
            ToolTile(
              icon: Icons.reorder_rounded,
              label: 'Réorganiser',
              onTap: () => _open(context, (doc) => OrganizePagesScreen(document: doc)),
            ),
          ]),
          if (document != null && document!.type == DocumentType.pdf) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PdfViewerScreen(document: document!)),
              ),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Revenir à la visionneuse'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolsRow extends StatelessWidget {
  final List<Widget> children;

  const _ToolsRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: children);
  }
}
