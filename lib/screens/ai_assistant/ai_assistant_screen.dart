import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chat_message.dart';
import '../../models/document_file.dart';
import '../../models/document_type.dart';
import '../../providers/ai_provider.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../files/files_screen.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  final DocumentFile? initialDocument;

  const AiAssistantScreen({super.key, this.initialDocument});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  bool _loadingConsent = true;
  bool? _consent;

  @override
  void initState() {
    super.initState();
    _loadConsent();
  }

  Future<void> _loadConsent() async {
    final consent = await StorageService.instance.getAiConsent();
    if (!mounted) return;
    setState(() {
      _consent = consent;
      _loadingConsent = false;
    });
    if (consent == true && widget.initialDocument != null) {
      Future.microtask(
        () => ref.read(aiAssistantProvider.notifier).selectDocument(widget.initialDocument!),
      );
    }
  }

  Future<void> _acceptConsent() async {
    await StorageService.instance.setAiConsent(true);
    if (!mounted) return;
    setState(() => _consent = true);
    if (widget.initialDocument != null) {
      ref.read(aiAssistantProvider.notifier).selectDocument(widget.initialDocument!);
    }
  }

  Future<void> _declineConsent() async {
    await StorageService.instance.setAiConsent(false);
    if (!mounted) return;
    setState(() => _consent = false);
  }

  Future<void> _pickDocument() async {
    final picked = await Navigator.of(context).push<DocumentFile>(
      MaterialPageRoute(builder: (_) => const FilesScreen(pickMode: true)),
    );
    if (picked == null || !mounted) return;
    await ref.read(aiAssistantProvider.notifier).selectDocument(picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (_loadingConsent) {
      return Scaffold(
        appBar: AppBar(title: Text(t('aiTitle'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_consent != true) {
      return Scaffold(
        appBar: AppBar(title: Text(t('aiTitle'))),
        body: _consent == false
            ? _AiConsentDeclined(onReconsider: _acceptConsent)
            : _AiConsentPrompt(onAccept: _acceptConsent, onDecline: _declineConsent),
      );
    }

    final state = ref.watch(aiAssistantProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t('aiTitle')),
          bottom: state.document == null
              ? null
              : TabBar(
                  tabs: [
                    Tab(text: t('aiTabSummary')),
                    Tab(text: t('aiTabChat')),
                    Tab(text: t('aiTabClassify')),
                  ],
                ),
        ),
        body: state.document == null
            ? _DocumentPicker(onPick: _pickDocument)
            : Column(
                children: [
                  _DocumentBanner(document: state.document!, onChange: _pickDocument),
                  if (state.stage == AiStage.extracting)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 12),
                            Text(t('aiAnalyzing')),
                          ],
                        ),
                      ),
                    )
                  else if (state.stage == AiStage.error)
                    Expanded(
                      child: EmptyState(
                        icon: Icons.error_outline_rounded,
                        title: t('aiAnalysisFailedTitle'),
                        message: state.errorMessage ?? t('aiUnknownError'),
                      ),
                    )
                  else
                    const Expanded(
                      child: TabBarView(
                        children: [_SummaryTab(), _ChatTab(), _ClassifyTab()],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _AiConsentPrompt extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _AiConsentPrompt({required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.smart_toy_outlined, size: 56, color: AppColors.primary),
            const SizedBox(height: 20),
            Text(
              t('aiConsentTitle'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              t('aiConsentBody'),
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: onAccept, child: Text(t('aiConsentAccept'))),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onDecline, child: Text(t('aiConsentDecline'))),
          ],
        ),
      ),
    );
  }
}

class _AiConsentDeclined extends StatelessWidget {
  final VoidCallback onReconsider;

  const _AiConsentDeclined({required this.onReconsider});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return EmptyState(
      icon: Icons.smart_toy_outlined,
      title: t('aiConsentDeclinedTitle'),
      message: t('aiConsentDeclinedMessage'),
      action: OutlinedButton(onPressed: onReconsider, child: Text(t('aiConsentReconsider'))),
    );
  }
}

class _DocumentPicker extends StatelessWidget {
  final VoidCallback onPick;

  const _DocumentPicker({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return EmptyState(
      icon: Icons.smart_toy_outlined,
      title: t('aiWelcomeTitle'),
      message: t('aiWelcomeMessage'),
      action: ElevatedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.folder_open_rounded),
        label: Text(t('aiChooseDocument')),
      ),
    );
  }
}

class _DocumentBanner extends StatelessWidget {
  final DocumentFile document;
  final VoidCallback onChange;

  const _DocumentBanner({required this.document, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Row(
        children: [
          Icon(document.type.icon, color: document.type.color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(document.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          TextButton(onPressed: onChange, child: Text(t('aiChange'))),
        ],
      ),
    );
  }
}

class _SummaryTab extends ConsumerWidget {
  const _SummaryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final state = ref.watch(aiAssistantProvider);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(state.errorMessage!, style: const TextStyle(color: AppColors.primary)),
            ),
          Expanded(
            child: state.summary == null
                ? EmptyState(
                    icon: Icons.summarize_outlined,
                    title: t('aiNoSummaryTitle'),
                    message: t('aiNoSummaryMessage'),
                  )
                : SingleChildScrollView(
                    child: Text(state.summary!, style: const TextStyle(height: 1.5)),
                  ),
          ),
          const SizedBox(height: 12),
          LoadingButton(
            label: state.summary == null ? t('aiGenerateSummary') : t('aiRegenerate'),
            icon: Icons.auto_awesome_rounded,
            loading: state.isSummarizing,
            onPressed: () => ref.read(aiAssistantProvider.notifier).summarize(),
          ),
        ],
      ),
    );
  }
}

class _ChatTab extends ConsumerStatefulWidget {
  const _ChatTab();

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(AiAssistantState state) {
    final text = _controller.text.trim();
    if (text.isEmpty || state.isSendingChat) return;
    _controller.clear();
    ref.read(aiAssistantProvider.notifier).sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final state = ref.watch(aiAssistantProvider);
    return Column(
      children: [
        Expanded(
          child: state.chat.isEmpty
              ? EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: t('aiNoQuestionTitle'),
                  message: t('aiNoQuestionMessage'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.chat.length,
                  itemBuilder: (context, index) {
                    final message = state.chat[index];
                    final isUser = message.role == ChatRole.user;
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.primary : AppColors.surface,
                          border: isUser ? null : Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message.content,
                          style: TextStyle(color: isUser ? Colors.white : AppColors.textPrimary),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (state.isSendingChat)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: t('aiAskHint')),
                    onSubmitted: (_) => _send(state),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _send(state),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ClassifyTab extends ConsumerWidget {
  const _ClassifyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final state = ref.watch(aiAssistantProvider);
    final categories = AiCategory.defaultsFor(t);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t('aiCategoriesLabel'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                for (final category in categories)
                  Card(
                    color: state.suggestedCategory?.id == category.id ? AppColors.primaryLight : null,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(category.label),
                      trailing: state.suggestedCategory?.id == category.id
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          LoadingButton(
            label: t('aiClassifyButton'),
            icon: Icons.category_outlined,
            loading: state.isClassifying,
            onPressed: () => ref.read(aiAssistantProvider.notifier).classify(categories),
          ),
        ],
      ),
    );
  }
}
