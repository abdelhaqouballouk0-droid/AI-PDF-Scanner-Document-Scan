enum ChatRole { user, assistant, system }

class ChatMessage {
  final ChatRole role;
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessage.user(String content) => ChatMessage(
        role: ChatRole.user,
        content: content,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.assistant(String content) => ChatMessage(
        role: ChatRole.assistant,
        content: content,
        timestamp: DateTime.now(),
      );
}

/// A candidate category returned by / used for the AI "Classify" tool.
class AiCategory {
  final String id;
  final String label;

  const AiCategory(this.id, this.label);

  static const List<AiCategory> defaults = [
    AiCategory('personal', 'Écrits personnels'),
    AiCategory('technical', 'Documentation technique'),
    AiCategory('financial', 'Finance & factures'),
    AiCategory('legal', 'Juridique & contrats'),
    AiCategory('education', 'Éducation'),
    AiCategory('other', 'Autre'),
  ];
}
