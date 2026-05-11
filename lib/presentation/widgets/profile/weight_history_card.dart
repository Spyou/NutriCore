import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/utils/components/custom_flushbar.dart';
import '../../controllers/profile_controller.dart';

class WeightHistoryCard extends StatefulWidget {
  const WeightHistoryCard({super.key});

  @override
  State<WeightHistoryCard> createState() => _WeightHistoryCardState();
}

class _WeightHistoryCardState extends State<WeightHistoryCard> {
  late final ProfileController controller;
  late final TextEditingController _weightCtl;
  bool _logging = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ProfileController>();
    _weightCtl = TextEditingController();
  }

  @override
  void dispose() {
    _weightCtl.dispose();
    super.dispose();
  }

  Future<void> _logToday() async {
    final raw = _weightCtl.text.trim();
    final value = double.tryParse(raw);
    if (value == null || value <= 0) {
      CustomThemeFlushbar.show(
        title: 'Invalid weight',
        message: 'Enter a number greater than 0',
      );
      return;
    }
    setState(() => _logging = true);
    try {
      await controller.updateProfile(currentWeight: value);
      _weightCtl.clear();
      CustomThemeFlushbar.show(
        title: 'Logged',
        message: 'Today\'s weight saved',
      );
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Weight',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              Obx(() {
                final v = controller.currentWeight.value;
                return Text(
                  '${v.toStringAsFixed(1)} kg',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 4),
          Obx(() {
            final current = controller.currentWeight.value;
            final target = controller.targetWeight.value;
            final diff = (current - target).abs();
            return Text(
              'Target: ${target.toStringAsFixed(1)} kg · '
              '${diff.toStringAsFixed(1)} kg to go',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            );
          }),
          const SizedBox(height: 14),
          Obx(() {
            final history = controller.monthlyWeight.toList();
            final tail = history.length > 30
                ? history.sublist(history.length - 30)
                : history;
            if (tail.length < 2) {
              return SizedBox(
                height: 56,
                child: Center(
                  child: Text(
                    'Add a weight to start tracking',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }
            return SizedBox(
              height: 56,
              width: double.infinity,
              child: CustomPaint(
                painter: _WeightSparklinePainter(
                  values: tail,
                  lineColor: scheme.primary,
                  pointColor: scheme.primary,
                  todayColor: scheme.primary,
                  trackColor: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _weightCtl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Today\'s weight',
                    suffixText: 'kg',
                    prefixIcon: Icon(
                      Icons.monitor_weight_outlined,
                      color: scheme.primary,
                    ),
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: scheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: scheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: scheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _logging ? null : _logToday,
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: _logging
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: scheme.onPrimary,
                        ),
                      )
                    : Text(
                        'Log',
                        style: textTheme.titleSmall?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightSparklinePainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color pointColor;
  final Color todayColor;
  final Color trackColor;

  _WeightSparklinePainter({
    required this.values,
    required this.lineColor,
    required this.pointColor,
    required this.todayColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);

    final count = values.length;
    final stepX = count > 1 ? size.width / (count - 1) : size.width;
    const padY = 6.0;
    final usableH = size.height - padY * 2;

    Offset pointFor(int i) {
      final v = values[i];
      final t = (v - minV) / range;
      final y = padY + (1.0 - t) * usableH;
      return Offset(stepX * i, y);
    }

    // Baseline track.
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      trackPaint,
    );

    // Line path.
    final path = Path()..moveTo(pointFor(0).dx, pointFor(0).dy);
    for (int i = 1; i < count; i++) {
      final p = pointFor(i);
      path.lineTo(p.dx, p.dy);
    }
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // Points.
    for (int i = 0; i < count; i++) {
      final isToday = i == count - 1;
      final p = pointFor(i);
      final radius = isToday ? 4.2 : 2.6;
      canvas.drawCircle(
        p,
        radius,
        Paint()..color = isToday ? todayColor : pointColor,
      );
      if (isToday) {
        canvas.drawCircle(
          p,
          radius + 1.6,
          Paint()
            ..color = todayColor.withValues(alpha: 0.25)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WeightSparklinePainter old) =>
      old.values != values ||
      old.lineColor != lineColor ||
      old.pointColor != pointColor ||
      old.todayColor != todayColor ||
      old.trackColor != trackColor;
}
