import 'dart:io';
import 'package:path/path.dart' as p;
import 'document_type.dart';

/// Represents a single file tracked by the app, either scanned/created
/// in-app or imported by the user.
class DocumentFile {
  final String path;
  final String name;
  final DocumentType type;
  final int sizeBytes;
  final DateTime createdAt;
  final DateTime modifiedAt;

  /// True when this file was produced by the app itself (scan, convert,
  /// merge, etc.) as opposed to a plain import — drives the "Created Files"
  /// counter on the Home screen.
  final bool createdByApp;

  /// Cached page count for PDFs, when known. Null if not yet computed.
  final int? pageCount;

  const DocumentFile({
    required this.path,
    required this.name,
    required this.type,
    required this.sizeBytes,
    required this.createdAt,
    required this.modifiedAt,
    this.createdByApp = false,
    this.pageCount,
  });

  String get extension => p.extension(path).replaceAll('.', '').toUpperCase();

  double get sizeMb => sizeBytes / (1024 * 1024);

  String get formattedSize {
    if (sizeBytes <= 0) return '0 KB';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${sizeMb.toStringAsFixed(1)} MB';
  }

  File get file => File(path);

  factory DocumentFile.fromFile(
    File file, {
    bool createdByApp = false,
    int? pageCount,
  }) {
    final stat = file.statSync();
    final name = p.basename(file.path);
    return DocumentFile(
      path: file.path,
      name: name,
      type: DocumentTypeX.fromExtension(p.extension(name)),
      sizeBytes: stat.size,
      createdAt: stat.changed,
      modifiedAt: stat.modified,
      createdByApp: createdByApp,
      pageCount: pageCount,
    );
  }

  DocumentFile copyWith({
    String? path,
    String? name,
    DocumentType? type,
    int? sizeBytes,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? createdByApp,
    int? pageCount,
  }) {
    return DocumentFile(
      path: path ?? this.path,
      name: name ?? this.name,
      type: type ?? this.type,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      createdByApp: createdByApp ?? this.createdByApp,
      pageCount: pageCount ?? this.pageCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'type': type.name,
        'sizeBytes': sizeBytes,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
        'createdByApp': createdByApp,
        'pageCount': pageCount,
      };

  factory DocumentFile.fromJson(Map<String, dynamic> json) => DocumentFile(
        path: json['path'] as String,
        name: json['name'] as String,
        type: DocumentType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => DocumentType.other,
        ),
        sizeBytes: json['sizeBytes'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        modifiedAt: DateTime.parse(json['modifiedAt'] as String),
        createdByApp: json['createdByApp'] as bool? ?? false,
        pageCount: json['pageCount'] as int?,
      );

  @override
  bool operator ==(Object other) => other is DocumentFile && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
