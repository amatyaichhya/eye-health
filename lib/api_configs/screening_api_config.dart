class ScreeningApiConfig {
  /// Local demo server, e.g. http://127.0.0.1:8000
  /// Physical device: use your Mac LAN IP, e.g. http://192.168.1.10:8000
  static const String baseUrl = String.fromEnvironment(
    'SCREENING_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String screenEndpoint = '$baseUrl/screen';
  static const String healthEndpoint = '$baseUrl/health';

  static bool get isConfigured => baseUrl.isNotEmpty;
}
