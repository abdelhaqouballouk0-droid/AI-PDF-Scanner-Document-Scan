import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/files_provider.dart';
import '../../services/document_scanner_service.dart';
import '../../theme/app_theme.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../files/files_screen.dart';
import '../home/home_screen.dart';
import '../scanner/scan_review_screen.dart';
import '../settings/settings_screen.dart';

/// Bottom-navigation shell: Home / Files / (scan) / AI Assistant / Settings,
/// matching the reference app's tab bar. The scan button in the middle is
/// a direct action (it launches the native scanner) rather than a fifth
/// screen.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    FilesScreen(),
    AiAssistantScreen(),
    SettingsScreen(),
  ];

  Future<void> _scan() async {
    try {
      final pages = await DocumentScannerService.instance.scanPages();
      if (pages.isEmpty || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ScanReviewScreen(imagePaths: pages)),
      );
      ref.read(filesProvider.notifier).refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan indisponible : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: SafeArea(
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Accueil',
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
              _NavItem(
                icon: Icons.folder_rounded,
                label: 'Fichiers',
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _scan,
                    child: Container(
                      width: 54,
                      height: 54,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0x33E53935), blurRadius: 14, offset: Offset(0, 6)),
                        ],
                      ),
                      child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.auto_awesome_rounded,
                label: 'Assistant',
                selected: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Réglages',
                selected: _index == 3,
                onTap: () => setState(() => _index = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
