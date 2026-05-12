import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/env_config.dart';

/// Wraps Gemini generation for short, personalized nutrition insights.
/// Results are cached in [GetStorage] to keep the home dashboard cheap and
/// instant on repeat visits.
class GeminiInsightsService {
  static final GeminiInsightsService instance = GeminiInsightsService._();
  GeminiInsightsService._();

  static const _model = 'gemini-2.0-flash';
  static const _cacheKey = 'insights.daily';
  static const _cacheTtl = Duration(hours: 4);

  final _box = GetStorage();
  GenerativeModel? _client;

  bool get isConfigured => EnvConfig.geminiApiKey.isNotEmpty;

  GenerativeModel? get _ensureClient {
    if (!isConfigured) return null;
    _client ??= GenerativeModel(model: _model, apiKey: EnvConfig.geminiApiKey);
    return _client;
  }

  /// One-line personalized insight for the home dashboard. Cached for
  /// [_cacheTtl] so repeat home visits don't spam the API.
  Future<String?> dailyInsight({
    required String userName,
    required int consumedKcal,
    required int goalKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required int mealsToday,
    required int streakDays,
    required List<double> weekCalories,
    bool forceRefresh = false,
  }) async {
    final client = _ensureClient;
    if (client == null) return null;

    if (!forceRefresh) {
      final cached = _readCache();
      if (cached != null) return cached;
    }

    final prompt =
        '''
You are a concise, warm nutrition coach. Generate ONE short, personalized
insight (max 18 words) for the user based on today's data. No greetings,
no fluff. Speak directly. If data is sparse, encourage tracking. If on
track, acknowledge briefly. Mention specific numbers when helpful.

USER: ${userName.isEmpty ? 'the user' : userName}
TODAY:
- Calories: $consumedKcal / $goalKcal kcal
- Protein: ${proteinG.toStringAsFixed(0)}g
- Carbs: ${carbsG.toStringAsFixed(0)}g
- Fat: ${fatG.toStringAsFixed(0)}g
- Meals logged today: $mealsToday
- Current streak: $streakDays days
- Last 7 days kcal: $weekCalories

Return ONLY the insight sentence. No quotes, no labels.
''';

    try {
      final response = await client.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) return null;
      _writeCache(text);
      return text;
    } catch (e) {
      if (kDebugMode) print('Gemini daily insight error: $e');
      return null;
    }
  }

  /// 3-bullet weekly summary for the Profile / dedicated Insights view.
  /// Cached per-day so revisits are instant.
  Future<String?> weeklySummary({
    required List<double> weekCalories,
    required double avgProtein,
    required double avgCarbs,
    required double avgFat,
    required int activeDays,
    required double weightChangeKg,
    bool forceRefresh = false,
  }) async {
    final client = _ensureClient;
    if (client == null) return null;

    final cacheKey = 'insights.weekly.${_todayKey()}';
    if (!forceRefresh) {
      final cached = _box.read(cacheKey);
      if (cached is String && cached.isNotEmpty) return cached;
    }

    final prompt =
        '''
You are a concise nutrition coach. Generate a weekly summary as exactly
3 short bullets (• prefix each). No greeting. Each bullet < 14 words.
Bullets cover: trend, macros, recommendation.

DATA:
- kcal last 7 days: $weekCalories
- Avg protein/day: ${avgProtein.toStringAsFixed(0)}g
- Avg carbs/day: ${avgCarbs.toStringAsFixed(0)}g
- Avg fat/day: ${avgFat.toStringAsFixed(0)}g
- Active days tracked: $activeDays / 7
- Weight change: ${weightChangeKg.toStringAsFixed(1)} kg

Return ONLY the 3 bullets.
''';
    try {
      final response = await client.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) return null;
      try {
        _box.write(cacheKey, text);
      } catch (_) {}
      return text;
    } catch (e) {
      if (kDebugMode) print('Gemini weekly summary error: $e');
      return null;
    }
  }

  String? _readCache() {
    try {
      final raw = _box.read(_cacheKey);
      if (raw is! Map) return null;
      final savedAt = raw['savedAt'] as int?;
      final text = raw['text'] as String?;
      if (savedAt == null || text == null) return null;
      final age = DateTime.now().millisecondsSinceEpoch - savedAt;
      if (age > _cacheTtl.inMilliseconds) return null;
      return text;
    } catch (_) {
      return null;
    }
  }

  void _writeCache(String text) {
    try {
      _box.write(_cacheKey, {
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'text': text,
      });
    } catch (_) {}
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
