import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/document_file.dart';
import '../models/document_type.dart';
import '../services/ai_service.dart';
import '../services/ocr_service.dart';
import '../services/pdf_tools_service.dart';

enum AiStage { idle, extracting, ready, error }

class AiAssistantState {
  final DocumentFile? document;
  final AiStage stage;
  final String? extractedText;
  final String? summary;
  final bool isSummarizing;
  final List<ChatMessage> chat;
  final bool isSendingChat;
  final AiCategory? suggestedCategory;
  final bool isClassifying;
  final String? errorMessage;

  const AiAssistantState({
    this.document,
    this.stage = AiStage.idle,
    this.extractedText,
    this.summary,
    this.isSummarizing = false,
    this.chat = const [],
    this.isSendingChat = false,
    this.suggestedCategory,
    this.isClassifying = false,
    this.errorMessage,
  });

  AiAssistantState copyWith({
    DocumentFile? document,
    AiStage? stage,
    String? extractedText,
    String? summary,
    bool? isSummarizing,
    List<ChatMessage>? chat,
    bool? isSendingChat,
    AiCategory? suggestedCategory,
    bool? isClassifying,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AiAssistantState(
      document: document ?? this.document,
      stage: stage ?? this.stage,
      extractedText: extractedText ?? this.extractedText,
      summary: summary ?? this.summary,
      isSummarizing: isSummarizing ?? this.isSummarizing,
      chat: chat ?? this.chat,
      isSendingChat: isSendingChat ?? this.isSendingChat,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      isClassifying: isClassifying ?? this.isClassifying,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Drives the "AI Assistant" screen: pick a document, extract its text
/// (PDF text layer if present, OCR fallback otherwise), then summarize,
/// chat or classify it against the configured AI backend.
class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  AiAssistantNotifier() : super(const AiAssistantState());

  Future<void> selectDocument(DocumentFile document) async {
    state = AiAssistantState(document: document, stage: AiStage.extracting);
    try {
      final text = await _extractText(document);
      state = state.copyWith(
        extractedText: text,
        stage: AiStage.ready,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(stage: AiStage.error, errorMessage: e.toString());
    }
  }

  Future<String> _extractText(DocumentFile document) async {
    if (document.type == DocumentType.pdf) {
      final bytes = await document.file.readAsBytes();
      final text = await PdfToolsService.instance.extractText(bytes);
      if (text.trim().length > 20) return text;
      // Likely a scanned PDF with no text layer: fall back to OCR.
      return OcrService.instance.recognizePdf(document.file);
    }
    if (document.type == DocumentType.image) {
      return OcrService.instance.recognizeImage(document.file);
    }
    return '';
  }

  Future<void> summarize() async {
    if (state.extractedText == null) return;
    state = state.copyWith(isSummarizing: true, clearError: true);
    try {
      final summary = await AiService.instance.summarizeDocument(
        state.extractedText!,
        fileName: state.document?.name,
      );
      state = state.copyWith(summary: summary, isSummarizing: false);
    } catch (e) {
      state = state.copyWith(isSummarizing: false, errorMessage: e.toString());
    }
  }

  Future<void> sendMessage(String question) async {
    if (state.extractedText == null || question.trim().isEmpty) return;
    final userMessage = ChatMessage.user(question.trim());
    state = state.copyWith(chat: [...state.chat, userMessage], isSendingChat: true, clearError: true);
    try {
      final answer = await AiService.instance.askAboutDocument(
        documentText: state.extractedText!,
        history: state.chat,
        question: question.trim(),
      );
      state = state.copyWith(
        chat: [...state.chat, ChatMessage.assistant(answer)],
        isSendingChat: false,
      );
    } catch (e) {
      state = state.copyWith(isSendingChat: false, errorMessage: e.toString());
    }
  }

  Future<void> classify(List<AiCategory> categories) async {
    if (state.extractedText == null || state.document == null) return;
    state = state.copyWith(isClassifying: true, clearError: true);
    try {
      final category = await AiService.instance.classifyDocument(
        documentText: state.extractedText!,
        fileName: state.document!.name,
        categories: categories,
      );
      state = state.copyWith(suggestedCategory: category, isClassifying: false);
    } catch (e) {
      state = state.copyWith(isClassifying: false, errorMessage: e.toString());
    }
  }

  void reset() => state = const AiAssistantState();
}

final aiAssistantProvider =
    StateNotifierProvider<AiAssistantNotifier, AiAssistantState>(
  (ref) => AiAssistantNotifier(),
);
