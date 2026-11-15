class HfApiConfig {
  static const String hfApiKey = String.fromEnvironment('HF_API_KEY');

  // OpenAI API endpoints
  static const String hfBaseUrl = String.fromEnvironment('HF_BASE_URL');
  static const String chatCompletionsEndpoint = '$hfBaseUrl/chat/completions';

  // Model configuration - can also be configured via dart-define
  static const String hfModel = String.fromEnvironment('HF_MODEL');
  static const String hfContentType = 'application/json';

  // Validation
  static bool get isApiKeyConfigured => hfApiKey.isNotEmpty;

  Map<String, dynamic> values() {
    return {
      'hfApiKey': hfApiKey,
      'hfBaseUrl': hfBaseUrl,
      'chatCompletionsEndpoint': chatCompletionsEndpoint,
      'hfModel': hfModel,
    };
  }
}
