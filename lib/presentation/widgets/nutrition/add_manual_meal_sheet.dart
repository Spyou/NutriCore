import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:nutri_check/core/utils/components/custom_flushbar.dart';
import 'package:nutri_check/presentation/controllers/nutrition_controller.dart';

class AddManualMealSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final int? editIndex;

  const AddManualMealSheet({super.key, this.existing, this.editIndex});

  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? existing,
    int? editIndex,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) =>
          AddManualMealSheet(existing: existing, editIndex: editIndex),
    );
  }

  @override
  State<AddManualMealSheet> createState() => _AddManualMealSheetState();
}

class _AddManualMealSheetState extends State<AddManualMealSheet> {
  static const List<String> _mealTypes = [
    'breakfast',
    'lunch',
    'dinner',
    'snack',
    'meal',
  ];

  late final TextEditingController _nameCtl;
  late final TextEditingController _caloriesCtl;
  late final TextEditingController _proteinCtl;
  late final TextEditingController _carbsCtl;
  late final TextEditingController _fatCtl;
  late final TextEditingController _notesCtl;

  String _selectedType = 'meal';
  bool _submitting = false;

  bool get _isEdit => widget.editIndex != null && widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtl = TextEditingController(text: e?['name']?.toString() ?? '');
    _caloriesCtl = TextEditingController(
      text: e?['calories'] != null ? _formatInt(e!['calories']) : '',
    );
    _proteinCtl = TextEditingController(
      text: e?['proteins'] != null ? _formatDouble(e!['proteins']) : '',
    );
    _carbsCtl = TextEditingController(
      text: e?['carbs'] != null ? _formatDouble(e!['carbs']) : '',
    );
    _fatCtl = TextEditingController(
      text: e?['fat'] != null ? _formatDouble(e!['fat']) : '',
    );
    _notesCtl = TextEditingController(text: e?['notes']?.toString() ?? '');
    final type = e?['type']?.toString().toLowerCase();
    if (type != null && _mealTypes.contains(type)) {
      _selectedType = type;
    }
    _nameCtl.addListener(_onChanged);
    _caloriesCtl.addListener(_onChanged);
  }

  String _formatInt(dynamic v) {
    if (v is num) return v.toInt().toString();
    return v.toString();
  }

  String _formatDouble(dynamic v) {
    if (v is num) {
      if (v == v.toInt()) return v.toInt().toString();
      return v.toStringAsFixed(1);
    }
    return v.toString();
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _nameCtl
      ..removeListener(_onChanged)
      ..dispose();
    _caloriesCtl
      ..removeListener(_onChanged)
      ..dispose();
    _proteinCtl.dispose();
    _carbsCtl.dispose();
    _fatCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_submitting) return false;
    if (_nameCtl.text.trim().isEmpty) return false;
    final cals = int.tryParse(_caloriesCtl.text.trim());
    if (cals == null || cals <= 0) return false;
    return true;
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
      final name = _nameCtl.text.trim();
      final cals = int.tryParse(_caloriesCtl.text.trim()) ?? 0;
      final p = double.tryParse(_proteinCtl.text.trim()) ?? 0.0;
      final c = double.tryParse(_carbsCtl.text.trim()) ?? 0.0;
      final f = double.tryParse(_fatCtl.text.trim()) ?? 0.0;

      final now = DateTime.now();
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');

      final meal = <String, dynamic>{
        'name': name,
        'calories': cals,
        'proteins': p,
        'carbs': c,
        'fat': f,
        'type': _selectedType,
        'notes': _notesCtl.text.trim(),
        'time': '$hh:$mm',
        'favorite': widget.existing?['favorite'] == true,
        'imageUrl': widget.existing?['imageUrl'],
        'quantity': widget.existing?['quantity'],
      };

      final ctl = Get.find<NutritionController>();
      if (_isEdit) {
        await ctl.editMeal(widget.editIndex!, meal);
      } else {
        await ctl.addMeal(meal);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      CustomThemeFlushbar.show(
        title: _isEdit ? 'Saved' : 'Added',
        message: '$name · $cals kcal',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      CustomThemeFlushbar.show(
        title: 'Error',
        message: _isEdit
            ? 'Failed to update meal'
            : 'Failed to add meal to nutrition log',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

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
              Text(
                _isEdit ? 'Edit meal' : 'Add meal',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              _nameField(scheme, textTheme),
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
              Text(
                'Nutrition',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              _nutritionGrid(scheme, textTheme),
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

  Widget _nameField(ColorScheme scheme, TextTheme textTheme) {
    return TextField(
      controller: _nameCtl,
      textInputAction: TextInputAction.next,
      style: textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      decoration: _inputDecoration(
        scheme: scheme,
        labelText: 'Name',
        hintText: 'e.g., Grilled chicken bowl',
        prefixIcon: Icons.restaurant_menu_rounded,
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
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
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

  Widget _nutritionGrid(ColorScheme scheme, TextTheme textTheme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _compactNumberField(
                scheme: scheme,
                textTheme: textTheme,
                controller: _caloriesCtl,
                label: 'Calories *',
                suffix: 'kcal',
                icon: Icons.local_fire_department_rounded,
                allowDecimal: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _compactNumberField(
                scheme: scheme,
                textTheme: textTheme,
                controller: _proteinCtl,
                label: 'Protein',
                suffix: 'g',
                icon: Icons.fitness_center_rounded,
                allowDecimal: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _compactNumberField(
                scheme: scheme,
                textTheme: textTheme,
                controller: _carbsCtl,
                label: 'Carbs',
                suffix: 'g',
                icon: Icons.grain_rounded,
                allowDecimal: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _compactNumberField(
                scheme: scheme,
                textTheme: textTheme,
                controller: _fatCtl,
                label: 'Fat',
                suffix: 'g',
                icon: Icons.opacity_rounded,
                allowDecimal: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _compactNumberField({
    required ColorScheme scheme,
    required TextTheme textTheme,
    required TextEditingController controller,
    required String label,
    required String suffix,
    required IconData icon,
    required bool allowDecimal,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowDecimal ? RegExp(r'^\d*\.?\d{0,2}') : RegExp(r'^\d*'),
        ),
      ],
      style: textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      decoration: _inputDecoration(
        scheme: scheme,
        labelText: label,
        suffixText: suffix,
        prefixIcon: icon,
        isDense: true,
      ),
    );
  }

  Widget _notesField(ColorScheme scheme, TextTheme textTheme) {
    return TextField(
      controller: _notesCtl,
      maxLines: 2,
      style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
      decoration: _inputDecoration(
        scheme: scheme,
        labelText: 'Notes (optional)',
        hintText: 'e.g., post-workout, with rice',
        prefixIcon: Icons.notes_rounded,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required ColorScheme scheme,
    required String labelText,
    String? hintText,
    String? suffixText,
    IconData? prefixIcon,
    bool isDense = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      suffixText: suffixText,
      isDense: isDense,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: scheme.primary),
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
                    _isEdit ? 'Save changes' : 'Add to log',
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
