import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_message.dart';
import '../../models/document_file.dart';
import '../../models/document_type.dart';
import '../../providers/ai_provider.dart';
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
  @override
  void initState() {
    super.initState();
    if (widget.initialDocument != null) {
      Future.microtask(
        () => ref.read(aiAssistantProvider.notifier).selectDocument(widget.initialDocument!),
      );
    }
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
    final state = ref.watch(aiAssistantProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Assistant IA'),
          bottom: state.document == null
              ? null
              : const TabBar(
                  tabs: [
                    Tab(text: 'Résumé'),
                    Tab(text: 'Chat'),
                    Tab(text: 'Classer'),
                  ],
                ),
        ),
        body: state.document == null
            ? _DocumentPicker(onPick: _pickDocument)
            : Column(
                children: [
                  _DocumentBanner(document: state.document!, onChange: _pickDocument),
                  if (state.stage == AiStage.extracting)
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Analyse du document...'),
                          ],
                        ),
                      ),
                    )
                  else if (state.stage == AiStage.error)
                    Expanded(
                      child: EmptyState(
                        icon: Icons.error_outline_rounded,
                        title: 'Analyse impossible',
                        message: state.errorMessage ?? 'Erreur inconnue',
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

class _DocumentPicker extends StatelessWidget {
  final VoidCallback onPick;

  const _DocumentPicker({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.smart_toy_outlined,
      title: 'Salut, je suis ton assistant IA',
      message: 'Choisis un document pour le résumer, discuter avec lui ou le classer automatiquement.',
      action: ElevatedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.folder_open_rounded),
        label: const Text('Choisir un document'),
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
          TextButton(onPressed: onChange, child: const Text('Changer')),
        ],
      ),
    );
  }
}

class _SummaryTab extends ConsumerWidget {
  const _SummaryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                ? const EmptyState(
                    icon: Icons.summarize_outlined,
                    title: 'Pas encore de résumé',
                    message: 'Génère un résumé concis des points clés de ce document.',
                  )
                : SingleChildScrollView(
                    child: Text(state.summary!, style: const TextStyle(height: 1.5)),
                  ),
          ),
          const SizedBox(height: 12),
          LoadingButton(
            label: state.summary == null ? 'Générer le résumé' : 'Régénérer',
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
    final state = ref.watch(aiAssistantProvider);
    return Column(
      children: [
        Expanded(
          child: state.chat.isEmpty
              ? const EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Pose ta première question',
                  message: 'Demande un résumé, un point précis ou une clarification sur ce document.',
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
                    decoration: const InputDecoration(hintText: 'Pose une question sur ce document...'),
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
    final state = ref.watch(aiAssistantProvider);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Catégories', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                for (final category in AiCategory.defaults)
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
            label: 'Classifier avec l\'IA',
            icon: Icons.category_outlined,
            loading: state.isClassifying,
            onPressed: () =>
                ref.read(aiAssistantProvider.notifier).classify(AiCategory.defaults),
          ),
        ],
      ),
    );
  }
}
