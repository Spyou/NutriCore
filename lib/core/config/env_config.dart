import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get geminiApiKey {
    final fromDotenv = dotenv.maybeGet('GEMINI_API_KEY') ?? '';
    if (fromDotenv.isNotEmpty) return fromDotenv;
    return const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  }

  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
