import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../shell/main_shell.dart';
import 'language_selection_screen.dart';

/// First screen shown on every launch (see [AiPdfScannerApp] in app.dart,
/// which sets this as `home`). Centered app icon, bold name, tagline, and an
/// animated progress bar — then moves on by itself, no button to press: to
/// the language picker on first launch, or straight to [MainShell] once
/// onboarding has already been completed.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    _controller.addStatusListener((status) async {
      if (status != AnimationStatus.completed || !mounted) return;
      final onboardingSeen = await StorageService.instance.getOnboardingSeen();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => onboardingSeen ? const MainShell() : const LanguageSelectionScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'AI PDF Scanner',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Documents, understood instantly',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.5, color: AppColors.textSecondary),
              ),
              const Spacer(flex: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => LinearProgressIndicator(
                    value: _controller.value,
                    minHeight: 6,
                    backgroundColor: AppColors.primaryLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
