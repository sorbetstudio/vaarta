class LLMMessage {
  final String role;
  final String content;

  LLMMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}