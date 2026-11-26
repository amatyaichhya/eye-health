class ScreeningApiConfig {
  /// Local demo server, e.g. http://127.0.0.1:8000
  static const String baseUrl = String.fromEnvironment(
    'SCREENING_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String screenEndpoint = '$baseUrl/screen';
  static const String healthEndpoint = '$baseUrl/health';

  static bool get isConfigured => baseUrl.isNotEmpty;
}
