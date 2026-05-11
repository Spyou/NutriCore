import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

import '../../../core/utils/components/custom_flushbar.dart';
import '../../controllers/nutrition_controller.dart';

class AddToMealSheet extends StatefulWidget {
  final Product product;

  const AddToMealSheet({super.key, required this.product});

  static Future<void> show(BuildContext context, Product product) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => AddToMealSheet(product: product),
    );
  }

  @override
  State<AddToMealSheet> createState() => _AddToMealSheetState();
}

class _AddToMealSheetState extends State<AddToMealSheet> {
  static const List<String> _mealTypes = [
    'breakfast',
    'lunch',
    'dinner',
    'snack',
    'meal',
  ];

  final TextEditingController _quantityCtl =
      TextEditingController(text: '100');
  final TextEditingController _notesCtl = TextEditingController();

  String _selectedType = 'meal';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _quantityCtl.addListener(_onQuantityChanged);
  }

  @override
  void dispose() {
    _quantityCtl
      ..removeListener(_onQuantityChanged)
      ..dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  void _onQuantityChanged() => setState(() {});

  double get _quantity =>
      double.tryParse(_quantityCtl.text.trim())?.clamp(0, 100000) ?? 0;

  bool get _canSubmit => _quantity > 0 && !_submitting;

  int _calsPer100() {
    try {
      return widget.product.nutriments
              ?.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams)
              ?.toInt() ??
          0;
    } catch (_) {
      return 0;
    }
  }

  double _nutrientPer100(Nutrient n) {
    try {
      return widget.product.nutriments
              ?.getValue(n, PerSize.oneHundredGrams) ??
          0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (!Get.isRegistered<NutritionController>()) {
      CustomThemeFlushbar.show(
        title: 'Error',
        message: 'Nutrition log is not available right now',
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final factor = _quantity / 100.0;
      final cals = (_calsPer100() * factor).round();
      final p = _nutrientPer100(Nutrient.proteins) * factor;
      final c = _nutrientPer100(Nutrient.carbohydrates) * factor;
      final f = _nutrientPer100(Nutrient.fat) * factor;
      final fiber = _nutrientPer100(Nutrient.fiber) * factor;
      final sugar = _nutrientPer100(Nutrient.sugars) * factor;
      final sodium = _nutrientPer100(Nutrient.sodium) * factor;

      final now = DateTime.now();
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');

      final meal = <String, dynamic>{
        'name': widget.product.productName ?? 'Unknown product',
        'calories': cals,
        'proteins': p,
        'carbs': c,
        'fat': f,
        'fiber': fiber,
        'sugar': sugar,
        'sodium': sodium,
        'type': _selectedType,
        'time': '$hh:$mm',
        'quantity': _quantity,
        'barcode': widget.product.barcode,
        'brands': widget.product.brands,
        'imageUrl': widget.product.imageFrontUrl,
        'notes': _notesCtl.text.trim(),
        'favorite': false,
      };

      await Get.find<NutritionController>().addMeal(meal);

      if (!mounted) return;
      Navigator.of(context).pop();
      CustomThemeFlushbar.show(
        title: 'Added to nutrition log',
        message:
            '${meal['name']} · ${_quantity.toStringAsFixed(0)}g · $cals kcal',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      CustomThemeFlushbar.show(
        title: 'Error',
        message: 'Failed to add product to nutrition log',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    final factor = _quantity / 100.0;
    final computedKcal = (_calsPer100() * factor).round();
    final computedProtein = _nutrientPer100(Nutrient.proteins) * factor;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _header(scheme, textTheme),
              const SizedBox(height: 20),
              _nutritionPreview(scheme, textTheme),
              const SizedBox(height: 22),
              _quantityField(scheme, textTheme),
              const SizedBox(height: 8),
              Text(
                _quantity > 0
                    ? '≈ $computedKcal kcal · ${computedProtein.toStringAsFixed(1)}g protein'
                    : 'Enter a quantity to see the totals',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Meal type',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              _mealTypeChips(scheme, textTheme),
              const SizedBox(height: 22),
              _notesField(scheme, textTheme),
              const SizedBox(height: 24),
              _footer(scheme, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ColorScheme scheme, TextTheme textTheme) {
    final imageUrl =
        widget.product.imageFrontSmallUrl ?? widget.product.imageFrontUrl;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 56,
            height: 56,
            child: imageUrl == null || imageUrl.isEmpty
                ? Container(
                    color: scheme.primary.withValues(alpha: 0.08),
                    child: Icon(
                      Icons.fastfood_rounded,
                      color: scheme.primary.withValues(alpha: 0.4),
                      size: 24,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: scheme.primary.withValues(alpha: 0.08),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: scheme.primary.withValues(alpha: 0.08),
                      child: Icon(
                        Icons.image_rounded,
                        color: scheme.primary.withValues(alpha: 0.4),
                        size: 22,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.productName ?? 'Unknown product',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if ((widget.product.brands ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  widget.product.brands!,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _nutritionPreview(ColorScheme scheme, TextTheme textTheme) {
    final cals = _calsPer100();
    final p = _nutrientPer100(Nutrient.proteins);
    final c = _nutrientPer100(Nutrient.carbohydrates);
    final f = _nutrientPer100(Nutrient.fat);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _pill('$cals kcal', scheme.primary, textTheme),
        _pill('${p.toStringAsFixed(1)}g P', scheme.primary, textTheme),
        _pill('${c.toStringAsFixed(1)}g C', scheme.tertiary, textTheme),
        _pill('${f.toStringAsFixed(1)}g F', scheme.secondary, textTheme),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          alignment: Alignment.center,
          child: Text(
            'per 100g',
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pill(String text, Color accent, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: textTheme.labelMedium?.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _quantityField(ColorScheme scheme, TextTheme textTheme) {
    return TextField(
      controller: _quantityCtl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: 'Quantity',
        suffixText: 'g',
        prefixIcon: Icon(Icons.scale_rounded, color: scheme.primary),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
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
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _mealTypeChips(ColorScheme scheme, TextTheme textTheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _mealTypes.map((type) {
        final selected = _selectedType == type;
        final label = type[0].toUpperCase() + type.substring(1);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedType = type);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary
                    : scheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? scheme.primary
                      : scheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _notesField(ColorScheme scheme, TextTheme textTheme) {
    return TextField(
      controller: _notesCtl,
      maxLines: 2,
      style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
      decoration: InputDecoration(
        labelText: 'Notes (optional)',
        hintText: 'e.g., half serving, with milk',
        prefixIcon: Icon(Icons.notes_rounded, color: scheme.primary),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
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
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _footer(ColorScheme scheme, TextTheme textTheme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(color: scheme.outlineVariant),
              foregroundColor: scheme.onSurface,
            ),
            child: Text(
              'Cancel',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: _canSubmit ? _submit : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _submitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: scheme.onPrimary,
                    ),
                  )
                : Text(
                    'Add to log',
                    style: textTheme.titleSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
