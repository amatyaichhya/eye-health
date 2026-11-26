class HfApiConfig {
  static const String openRouterApiKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
  );

  /// OpenRouter base (`https://openrouter.ai/api/v1`) or the full
  /// `.../chat/completions` URL from the fetch sample.
  static const String openRouterBaseUrl = String.fromEnvironment(
    'OPENROUTER_BASE_URL',
  );

  static String get chatCompletionsEndpoint {
    final base = openRouterBaseUrl.endsWith('/')
        ? openRouterBaseUrl.substring(0, openRouterBaseUrl.length - 1)
        : openRouterBaseUrl;
    if (base.endsWith('/chat/completions')) return base;
    return '$base/chat/completions';
  }

  // Model configuration - can also be configured via dart-define
  static const String openRouterModel = String.fromEnvironment(
    'OPENROUTER_MODEL',
  );
  static const String hfContentType = 'application/json';

  /// OpenRouter attribution headers (HTTP-Referer and X-Title).
  static const String httpReferer = String.fromEnvironment(
    'OPENROUTER_HTTP_REFERER',
    defaultValue: 'http://localhost',
  );
  static const String appTitle = String.fromEnvironment(
    'OPENROUTER_APP_TITLE',
    defaultValue: 'Eye Health',
  );

  // Validation
  static bool get isApiKeyConfigured => openRouterApiKey.isNotEmpty;

  Map<String, dynamic> values() {
    return {
      'openRouterApiKey': openRouterApiKey,
      'openRouterBaseUrl': openRouterBaseUrl,
      'chatCompletionsEndpoint': chatCompletionsEndpoint,
      'openRouterModel': openRouterModel,
      'httpReferer': httpReferer,
      'appTitle': appTitle,
    };
  }
}
