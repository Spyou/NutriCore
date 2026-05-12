import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  /// OpenRouter API key. Used for all AI generation (insights, weekly
  /// summary, meal photo analysis). Get one at https://openrouter.ai.
  static String get openRouterApiKey {
    final fromDotenv = dotenv.maybeGet('OPENROUTER_API_KEY') ?? '';
    if (fromDotenv.isNotEmpty) return fromDotenv;
    return const String.fromEnvironment(
      'OPENROUTER_API_KEY',
      defaultValue: '',
    );
  }

  static bool get hasOpenRouterKey => openRouterApiKey.isNotEmpty;

  /// Groq API key. Used for vision (meal photo analysis) since Groq's
  /// free tier exposes Llama 4 Scout with image support. Get one at
  /// https://console.groq.com/keys.
  static String get groqApiKey {
    final fromDotenv = dotenv.maybeGet('GROQ_API_KEY') ?? '';
    if (fromDotenv.isNotEmpty) return fromDotenv;
    return const String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  }

  static bool get hasGroqKey => groqApiKey.isNotEmpty;

  /// Cloudinary cloud name (from the Cloudinary dashboard, e.g. `dxyz123`).
  static String get cloudinaryCloudName =>
      dotenv.maybeGet('CLOUDINARY_CLOUD_NAME') ?? '';

  /// Name of an UNSIGNED upload preset configured in the Cloudinary
  /// console (Settings → Upload → Add upload preset → Signing: Unsigned).
  static String get cloudinaryUploadPreset =>
      dotenv.maybeGet('CLOUDINARY_UPLOAD_PRESET') ?? '';

  static bool get hasCloudinary =>
      cloudinaryCloudName.isNotEmpty && cloudinaryUploadPreset.isNotEmpty;
}
