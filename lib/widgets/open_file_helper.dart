import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../models/document_file.dart';

/// Opens a non-PDF file (Word, Excel, image, ...) with the platform's
/// default handler for that file type, since this app only ships an
/// in-app viewer for PDFs.
class OpenFileFallback {
  static Future<void> open(BuildContext context, DocumentFile file) async {
    final result = await OpenFilex.open(file.path);
    if (!context.mounted) return;
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir ${file.name}: ${result.message}')),
      );
    }
  }
}
