class EnvConfig {
  static String get geminiApiKey {
    return const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  }

  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
