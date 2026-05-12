import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/openrouter_insights_service.dart';
import '../../controllers/nutrition_controller.dart';
import '../../controllers/profile_controller.dart';

class WeeklySummaryCard extends StatefulWidget {
  const WeeklySummaryCard({super.key});

  @override
  State<WeeklySummaryCard> createState() => _WeeklySummaryCardState();
}

class _WeeklySummaryCardState extends State<WeeklySummaryCard>
    with SingleTickerProviderStateMixin {
  String? _summary;
  bool _loading = false;
  bool _errored = false;
  late final AnimationController _pulseController;
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFetch());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  int _activeDays() {
    final n = Get.find<NutritionController>();
    return n.weekCalories.where((c) => c > 0).length;
  }

  Future<void> _maybeFetch() async {
    if (_requested) return;
    if (_activeDays() < 3) return;
    _requested = true;

    setState(() {
      _loading = true;
      _errored = false;
    });

    try {
      final n = Get.find<NutritionController>();
      final p = Get.find<ProfileController>();
      final week = n.weekCalories.toList();
      final activeDays = week.where((c) => c > 0).length;

      // Prompt is forgiving — pass today's macro values as a reasonable
      // proxy for the weekly averages since per-day macro history isn't
      // tracked separately.
      final avgP = n.totalProteins.value;
      final avgC = n.totalCarbs.value;
      final avgF = n.totalFats.value;

      final wh = p.monthlyWeight;
      final weightChange = (wh.length >= 7)
          ? wh.last - wh[wh.length - 7]
          : 0.0;

      final text = await OpenRouterInsightsService.instance.weeklySummary(
        weekCalories: week,
        avgProtein: avgP,
        avgCarbs: avgC,
        avgFat: avgF,
        activeDays: activeDays,
        weightChangeKg: weightChange,
      );

      if (!mounted) return;
      setState(() {
        _loading = false;
        if (text == null || text.isEmpty) {
          _errored = true;
        } else {
          _summary = text;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errored = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      final n = Get.find<NutritionController>();
      // touch reactive so Obx rebuilds when weekCalories changes
      n.weekCalories.length;
      final active = n.weekCalories.where((c) => c > 0).length;

      // Kick off fetch when threshold becomes reached on later rebuild.
      if (active >= 3 && !_requested) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFetch());
      }

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const SizedBox(height: 14),
            _body(context, active, scheme, textTheme),
          ],
        ),
      );
    });
  }

  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'This week',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 12,
                color: scheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'AI',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    int active,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    if (active < 3) {
      return _placeholder(
        context,
        'Track at least 3 days to unlock weekly insights',
      );
    }

    if (_loading && _summary == null) {
      return _skeleton(scheme);
    }

    if (_errored && _summary == null) {
      return _placeholder(
        context,
        'Insights will appear after a week of tracking',
      );
    }

    final lines = _formatBullets(_summary ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _bulletLine(lines[i], scheme, textTheme),
        ],
      ],
    );
  }

  List<String> _formatBullets(String raw) {
    final result = <String>[];
    for (final lineRaw in raw.split('\n')) {
      final line = lineRaw.trim();
      if (line.isEmpty) continue;
      var clean = line;
      // strip common prefixes Gemini might emit
      for (final prefix in const ['•', '-', '*', '·']) {
        if (clean.startsWith(prefix)) {
          clean = clean.substring(prefix.length).trim();
          break;
        }
      }
      if (clean.isEmpty) continue;
      result.add(clean);
    }
    return result.isEmpty ? [raw.trim()] : result;
  }

  Widget _bulletLine(String text, ColorScheme scheme, TextTheme textTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7, right: 10),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _skeleton(ColorScheme scheme) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final t = _pulseController.value;
        final alpha = 0.08 + (0.10 * t);
        Widget bar(double width) => Container(
          height: 12,
          width: width,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(6),
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bar(double.infinity),
            bar(220),
            bar(180),
          ],
        );
      },
    );
  }

  Widget _placeholder(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 16,
          color: scheme.onSurface.withValues(alpha: 0.55),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
