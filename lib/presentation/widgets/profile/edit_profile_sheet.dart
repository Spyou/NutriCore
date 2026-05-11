import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/utils/components/custom_flushbar.dart';
import '../../controllers/profile_controller.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const EditProfileSheet(),
    );
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final ProfileController controller;

  late final TextEditingController _nameCtl;
  late final TextEditingController _bioCtl;
  late final TextEditingController _weightCtl;
  late final TextEditingController _targetCtl;
  late final TextEditingController _heightCtl;
  late final TextEditingController _ageCtl;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ProfileController>();
    _nameCtl = TextEditingController(text: controller.userName.value);
    _bioCtl = TextEditingController(text: controller.userBio.value);
    _weightCtl = TextEditingController(
      text: controller.currentWeight.value.toStringAsFixed(1),
    );
    _targetCtl = TextEditingController(
      text: controller.targetWeight.value.toStringAsFixed(1),
    );
    _heightCtl = TextEditingController(
      text: controller.height.value.toStringAsFixed(0),
    );
    _ageCtl = TextEditingController(text: controller.age.value.toString());
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _bioCtl.dispose();
    _weightCtl.dispose();
    _targetCtl.dispose();
    _heightCtl.dispose();
    _ageCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final name = _nameCtl.text.trim();
      final bio = _bioCtl.text.trim();
      final weight = double.tryParse(_weightCtl.text.trim());
      final target = double.tryParse(_targetCtl.text.trim());
      final height = double.tryParse(_heightCtl.text.trim());
      final age = int.tryParse(_ageCtl.text.trim());

      await controller.updateProfile(
        name: name.isEmpty ? null : name,
        bio: bio,
        currentWeight: weight,
        targetWeight: target,
        userHeight: height,
        userAge: age,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      CustomThemeFlushbar.show(
        title: 'Saved',
        message: 'Profile updated',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      CustomThemeFlushbar.show(
        title: 'Error',
        message: 'Failed to update profile',
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
                'Edit profile',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 20),
              _avatarRow(scheme),
              const SizedBox(height: 20),
              _textField(
                controller: _nameCtl,
                scheme: scheme,
                textTheme: textTheme,
                label: 'Name',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              _textField(
                controller: _bioCtl,
                scheme: scheme,
                textTheme: textTheme,
                label: 'Bio',
                hint: 'A short note about you',
                icon: Icons.notes_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _textField(
                      controller: _weightCtl,
                      scheme: scheme,
                      textTheme: textTheme,
                      label: 'Current weight',
                      icon: Icons.monitor_weight_outlined,
                      suffix: 'kg',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _textField(
                      controller: _targetCtl,
                      scheme: scheme,
                      textTheme: textTheme,
                      label: 'Target weight',
                      icon: Icons.flag_rounded,
                      suffix: 'kg',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _textField(
                      controller: _heightCtl,
                      scheme: scheme,
                      textTheme: textTheme,
                      label: 'Height',
                      icon: Icons.height_rounded,
                      suffix: 'cm',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _textField(
                      controller: _ageCtl,
                      scheme: scheme,
                      textTheme: textTheme,
                      label: 'Age',
                      icon: Icons.cake_outlined,
                      suffix: 'yrs',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _footer(scheme, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarRow(ColorScheme scheme) {
    return Center(
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          children: [
            Obx(() {
              final url = controller.profileImageUrl.value;
              return Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(top: 8, left: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.08),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: url.isEmpty
                    ? Icon(
                        Icons.person_rounded,
                        size: 36,
                        color: scheme.primary.withValues(alpha: 0.5),
                      )
                    : CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: scheme.primary.withValues(alpha: 0.08),
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          Icons.person_rounded,
                          size: 36,
                          color: scheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
              );
            }),
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    controller.updateProfileImage();
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary,
                      border: Border.all(color: scheme.surface, width: 2),
                    ),
                    child: Obx(() {
                      if (controller.isUploadingImage.value) {
                        return Padding(
                          padding: const EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        );
                      }
                      return Icon(
                        Icons.photo_camera_rounded,
                        size: 16,
                        color: scheme.onPrimary,
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required ColorScheme scheme,
    required TextTheme textTheme,
    required String label,
    String? hint,
    required IconData icon,
    String? suffix,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Icon(icon, color: scheme.primary),
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
            onPressed: _submitting ? null : _submit,
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
                    'Save',
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
