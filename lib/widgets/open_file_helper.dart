import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../l10n/app_localizations.dart';
import '../models/document_file.dart';

/// Opens a non-PDF file (Word, Excel, image, ...) with the platform's
/// default handler for that file type, since this app only ships an
/// in-app viewer for PDFs.
class OpenFileFallback {
  static Future<void> open(BuildContext context, DocumentFile file) async {
    final result = await OpenFilex.open(file.path);
    if (!context.mounted) return;
    if (result.type != ResultType.done) {
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.tp('openFileFailed', {'fileName': file.name, 'message': result.message}))),
      );
    }
  }
}
