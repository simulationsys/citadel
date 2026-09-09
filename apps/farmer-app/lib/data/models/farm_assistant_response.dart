class FarmAssistantResponse {
  final String answer;
  final String language;
  final String model;
  final List<String> sources;

  const FarmAssistantResponse({required this.answer, required this.language,
    required this.model, this.sources = const []});

  factory FarmAssistantResponse.fromJson(Map<String, dynamic> json) =>
      FarmAssistantResponse(
        answer: json['answer'] as String? ?? '',
        language: json['language'] as String? ?? 'English',
        model: json['model'] as String? ?? 'unknown',
        sources: ((json['sources'] as List?) ?? const [])
            .map((value) => value.toString()).toList(),
      );
}

class FarmAssistantException implements Exception {
  final String message;
  final int? statusCode;
  const FarmAssistantException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
