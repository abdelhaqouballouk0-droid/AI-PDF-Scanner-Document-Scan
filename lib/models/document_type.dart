import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// The document families the app understands. Used for filtering, icons,
/// and choosing which conversion path applies to a given file.
enum DocumentType { pdf, word, excel, image, other }

extension DocumentTypeX on DocumentType {
  String labelFor(AppLocalizations t) {
    switch (this) {
      case DocumentType.pdf:
        return t('docTypePdf');
      case DocumentType.word:
        return t('docTypeWord');
      case DocumentType.excel:
        return t('docTypeExcel');
      case DocumentType.image:
        return t('docTypeImage');
      case DocumentType.other:
        return t('docTypeOther');
    }
  }

  Color get color {
    switch (this) {
      case DocumentType.pdf:
        return AppColors.pdfColor;
      case DocumentType.word:
        return AppColors.wordColor;
      case DocumentType.excel:
        return AppColors.excelColor;
      case DocumentType.image:
        return AppColors.imageColor;
      case DocumentType.other:
        return AppColors.otherColor;
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentType.pdf:
        return Icons.picture_as_pdf_rounded;
      case DocumentType.word:
        return Icons.description_rounded;
      case DocumentType.excel:
        return Icons.grid_on_rounded;
      case DocumentType.image:
        return Icons.image_rounded;
      case DocumentType.other:
        return Icons.insert_drive_file_rounded;
    }
  }

  /// Maps a file extension (without the dot, any case) to a [DocumentType].
  static DocumentType fromExtension(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    switch (ext) {
      case 'pdf':
        return DocumentType.pdf;
      case 'doc':
      case 'docx':
        return DocumentType.word;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return DocumentType.excel;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'heic':
      case 'webp':
        return DocumentType.image;
      default:
        return DocumentType.other;
    }
  }
}
