import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../config/env_config.dart';

/// Wraps OpenRouter text generation for short, personalized nutrition
/// insights. Uses the free `openai/gpt-oss-20b` model. Results are cached
/// in [GetStorage] to keep the home dashboard cheap and instant on repeat
/// visits.
class OpenRouterInsightsService {
  static final OpenRouterInsightsService instance = OpenRouterInsightsService._();
  OpenRouterInsightsService._();

  static const _endpoint = 'https://openrouter.ai/api/v1/chat/completions';
  static const _model = 'openai/gpt-oss-20b:free';
  static const _cacheKey = 'insights.daily';
  static const _cacheTtl = Duration(hours: 4);

  final _box = GetStorage();

  bool get isConfigured => EnvConfig.hasOpenRouterKey;

  Future<String?> _chat(String prompt) async {
    if (!isConfigured) return null;
    try {
      final res = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer ${EnvConfig.openRouterApiKey}',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://nutricore.app',
              'X-Title': 'NutriCore',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              'max_tokens': 200,
              'temperature': 0.6,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        if (kDebugMode) {
          print('OpenRouter error ${res.statusCode}: ${res.body}');
        }
        return null;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final choices = body['choices'] as List?;
      if (choices == null || choices.isEmpty) return null;
      final msg = choices.first['message'] as Map<String, dynamic>?;
      final text = (msg?['content'] as String?)?.trim();
      if (text == null || text.isEmpty) return null;
      return text;
    } catch (e) {
      if (kDebugMode) print('OpenRouter chat error: $e');
      return null;
    }
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
    if (!isConfigured) return null;

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

    final text = await _chat(prompt);
    if (text == null) return null;
    _writeCache(text);
    return text;
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
    if (!isConfigured) return null;

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
    final text = await _chat(prompt);
    if (text == null) return null;
    try {
      _box.write(cacheKey, text);
    } catch (_) {}
    return text;
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
