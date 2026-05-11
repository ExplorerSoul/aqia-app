/// Global app configuration.
/// Pass --dart-define=MOCK_MODE=true to flutter run/build to enable mock mode.
class AppConfig {
  /// When true, all AI calls use MockAiService — zero LLM tokens consumed.
  /// The full interview flow still runs: questions, answers, report, question bank.
  static const bool mockMode = bool.fromEnvironment('MOCK_MODE', defaultValue: false);

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://aqia-backend.onrender.com',
  );
}
