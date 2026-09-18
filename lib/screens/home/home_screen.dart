import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/document_file.dart';
import '../../models/document_type.dart';
import '../../providers/files_provider.dart';
import '../../services/document_scanner_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/open_file_helper.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../files/files_screen.dart';
import '../scanner/scan_review_screen.dart';
import '../tools/more_tools_screen.dart';
import '../viewer/pdf_viewer_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _startScan(BuildContext context) async {
    try {
      final pages = await DocumentScannerService.instance.scanPages();
      if (pages.isEmpty || !context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ScanReviewScreen(imagePaths: pages)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan indisponible : $e')),
      );
    }
  }

  Future<void> _importFile(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
    );
    final path = picked?.path;
    if (path == null) return;
    await ref.read(filesProvider.notifier).importFile(path);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fichier importé')),
    );
  }

  Future<void> _openFile(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.pickFile(type: FileType.any);
    final path = picked?.path;
    if (path == null || !context.mounted) return;
    final imported = await ref.read(filesProvider.notifier).importFile(path);
    if (imported.type != DocumentType.pdf || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PdfViewerScreen(document: imported)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(libraryCountsProvider);
    final recentFiles = ref.watch(filesProvider).valueOrNull ?? const <DocumentFile>[];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(filesProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              _Header(),
              const SizedBox(height: 18),
              _ScanCard(
                allCount: counts.all,
                createdCount: counts.createdByApp,
                onScan: () => _startScan(context),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ToolTile(
                    icon: Icons.file_upload_outlined,
                    label: 'Importer',
                    onTap: () => _importFile(context, ref),
                  ),
                  ToolTile(
                    icon: Icons.folder_open_rounded,
                    label: 'Ouvrir fichier',
                    onTap: () => _openFile(context, ref),
                  ),
                  ToolTile(
                    icon: Icons.auto_awesome_rounded,
                    label: 'AI Chat',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                    ),
                  ),
                  ToolTile(
                    icon: Icons.apps_rounded,
                    label: 'Plus d\'outils',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MoreToolsScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Parcourir par type',
                actionLabel: 'Tout voir',
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FilesScreen()),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 92,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _TypeCard(
                      type: DocumentType.pdf,
                      count: counts.byType[DocumentType.pdf] ?? 0,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const FilesScreen(initialType: DocumentType.pdf))),
                    ),
                    _TypeCard(
                      type: DocumentType.word,
                      count: counts.byType[DocumentType.word] ?? 0,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const FilesScreen(initialType: DocumentType.word))),
                    ),
                    _TypeCard(
                      type: DocumentType.excel,
                      count: counts.byType[DocumentType.excel] ?? 0,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const FilesScreen(initialType: DocumentType.excel))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Fichiers récents',
                actionLabel: 'Tout voir',
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FilesScreen()),
                ),
              ),
              const SizedBox(height: 12),
              if (recentFiles.isEmpty)
                const EmptyState(
                  icon: Icons.description_outlined,
                  title: 'Aucun document pour le moment',
                  message: 'Scanne ou importe ton premier document pour commencer.',
                )
              else
                ...recentFiles.take(5).map(
                      (f) => _RecentFileTile(
                        file: f,
                        onTap: () {
                          if (f.type == DocumentType.pdf) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => PdfViewerScreen(document: f)),
                            );
                          } else {
                            OpenFileFallback.open(context, f);
                          }
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.document_scanner_rounded, color: Colors.white),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'AI PDF Scanner-Document Scan',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.search_rounded),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.proGradient),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.white),
              SizedBox(width: 4),
              Text('Pro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanCard extends StatelessWidget {
  final int allCount;
  final int createdCount;
  final VoidCallback onScan;

  const _ScanCard({required this.allCount, required this.createdCount, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onScan,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.crop_free_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scanner un document',
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15.5)),
                          SizedBox(height: 2),
                          Text('Détection de bords auto · PDF instantané',
                              style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: StatChip(value: '$allCount Fichiers', label: 'Tous les fichiers')),
              Container(width: 1, height: 34, color: Colors.white24),
              Expanded(child: StatChip(value: '$createdCount Fichiers', label: 'Fichiers créés')),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final DocumentType type;
  final int count;
  final VoidCallback onTap;

  const _TypeCard({required this.type, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: type.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 130,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(type.icon, color: type.color, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${type.label} Files',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                      Text('$count fichiers',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentFileTile extends StatelessWidget {
  final DocumentFile file;
  final VoidCallback onTap;

  const _RecentFileTile({required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: file.type.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(file.type.icon, color: file.type.color, size: 20),
        ),
        title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${file.formattedSize} · ${file.extension}'),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      ),
    );
  }
}
