import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import 'storage_service.dart';

/// Thrown when the configured AI endpoint rejects the request or is
/// unreachable, so the UI can show an actionable message instead of a
/// raw exception.
class AiRequestException implements Exception {
  final String message;
  AiRequestException(this.message);
  @override
  String toString() => message;
}

/// Talks to any OpenAI-compatible "/chat/completions" endpoint. This
/// covers OpenAI itself, Groq, OpenRouter, Together.ai, and a local
/// Ollama instance served with `OLLAMA_HOST` in OpenAI-compat mode — the
/// user picks the base URL, model and (if needed) API key from Settings,
/// nothing is hard-coded to a single vendor.
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  Future<Map<String, String>> _headers() async {
    final key = await StorageService.instance.getAiApiKey();
    return {
      'Content-Type': 'application/json',
      if (key != null && key.isNotEmpty) 'Authorization': 'Bearer $key',
    };
  }

  Future<String> _complete(List<Map<String, String>> messages, {double temperature = 0.4}) async {
    final baseUrl = await StorageService.instance.getAiBaseUrl();
    final model = await StorageService.instance.getAiModel();
    final uri = Uri.parse('$baseUrl/chat/completions');

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: await _headers(),
            body: jsonEncode({
              'model': model,
              'messages': messages,
              'temperature': temperature,
            }),
          )
          .timeout(const Duration(seconds: 60));
    } catch (e) {
      throw AiRequestException(
        'Impossible de joindre le service IA ($baseUrl). Vérifie la configuration dans Réglages.',
      );
    }

    if (response.statusCode != 200) {
      throw AiRequestException(
        'Le service IA a répondu ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw AiRequestException('Réponse IA vide ou inattendue.');
    }
    final message = choices.first['message'] as Map<String, dynamic>;
    return (message['content'] as String?)?.trim() ?? '';
  }

  /// Summarizes extracted document text into a short bullet-style digest.
  Future<String> summarizeDocument(String documentText, {String? fileName}) async {
    final trimmed = _truncateForContext(documentText);
    return _complete([
      {
        'role': 'system',
        'content':
            'Tu es un assistant qui résume des documents de façon concise et factuelle, en français, sous forme de puces courtes.',
      },
      {
        'role': 'user',
        'content':
            'Résume ce document${fileName != null ? " ($fileName)" : ""} en 4 à 6 puces clés :\n\n$trimmed',
      },
    ]);
  }

  /// Free-form Q&A grounded in the document's extracted text.
  Future<String> askAboutDocument({
    required String documentText,
    required List<ChatMessage> history,
    required String question,
  }) async {
    final trimmed = _truncateForContext(documentText);
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content':
            'Tu es un assistant qui répond aux questions sur le document fourni, en français, de façon précise. '
                'Si la réponse ne se trouve pas dans le document, dis-le clairement.\n\nDocument :\n$trimmed',
      },
      for (final m in history)
        {
          'role': m.role == ChatRole.user ? 'user' : 'assistant',
          'content': m.content,
        },
      {'role': 'user', 'content': question},
    ];
    return _complete(messages);
  }

  /// Suggests the best-fitting category for a document among [categories].
  Future<AiCategory> classifyDocument({
    required String documentText,
    required String fileName,
    required List<AiCategory> categories,
  }) async {
    final trimmed = _truncateForContext(documentText, maxChars: 4000);
    final options = categories.map((c) => '${c.id}: ${c.label}').join('\n');
    final raw = await _complete([
      {
        'role': 'system',
        'content':
            'Tu classes des documents dans une catégorie existante. Réponds uniquement avec l\'identifiant de catégorie (le mot avant les ":"), sans autre texte.',
      },
      {
        'role': 'user',
        'content':
            'Fichier : $fileName\n\nCatégories possibles :\n$options\n\nContenu du document :\n$trimmed\n\nRéponds avec un seul identifiant de catégorie.',
      },
    ], temperature: 0.1);

    final normalized = raw.toLowerCase().trim();
    return categories.firstWhere(
      (c) => normalized.contains(c.id),
      orElse: () => categories.last,
    );
  }

  String _truncateForContext(String text, {int maxChars = 12000}) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}\n[...document tronqué...]';
  }
}
