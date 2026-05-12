import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/nutrition_controller.dart';
import '../../controllers/profile_controller.dart';
import '../main_page.dart';

/// Multi-step onboarding flow that runs once after a brand-new account
/// is created (email signup or first Google sign-in). Collects an
/// optional avatar, basic info, body metrics, activity level and a
/// suggested calorie target so the user lands on the home tab with
/// values that actually reflect them — not the global defaults.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const int _stepCount = 5;
  static const List<double> _activityMultipliers = [
    1.2, // sedentary
    1.375, // light
    1.55, // moderate
    1.725, // active
    1.9, // very active
  ];
  static const List<String> _activityKeys = [
    'sedentary',
    'light',
    'moderate',
    'active',
    'very_active',
  ];

  final PageController _pageController = PageController();
  int _step = 0;

  late final ProfileController _profile;
  AuthController? _auth;

  // Step 2 — basic info.
  final TextEditingController _nameCtl = TextEditingController();
  String _gender = 'Male';
  DateTime? _dob;

  // Step 3 — body metrics.
  final TextEditingController _heightCtl = TextEditingController();
  final TextEditingController _weightCtl = TextEditingController();
  final TextEditingController _targetCtl = TextEditingController();

  // Step 4 — activity level (0..4).
  int? _activityIndex;

  // Step 5 — calorie goal (kcal/day). Lazily computed when user reaches
  // the step, recomputed if they go back and change something earlier.
  int? _calorieGoal;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _profile = Get.find<ProfileController>();
    try {
      _auth = Get.find<AuthController>();
    } catch (_) {
      _auth = null;
    }
    // Prefill name from anywhere it might already exist — profile,
    // auth model, FirebaseAuth, or email. The user can edit before
    // continuing. Treat "Anonymous User" / "User" / empty as not-set.
    String resolved = '';
    final fromProfile = _profile.userName.value.trim();
    if (fromProfile.isNotEmpty &&
        fromProfile != 'Anonymous User' &&
        fromProfile != 'User') {
      resolved = fromProfile;
    } else if (_auth?.userModel?.displayName?.trim().isNotEmpty == true) {
      resolved = _auth!.userModel!.displayName!.trim();
    } else if (_auth?.user?.displayName?.trim().isNotEmpty == true) {
      resolved = _auth!.user!.displayName!.trim();
    }
    _nameCtl.text = resolved;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtl.dispose();
    _heightCtl.dispose();
    _weightCtl.dispose();
    _targetCtl.dispose();
    super.dispose();
  }

  int? _ageFromDob(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    final hadBirthday = (now.month > dob.month) ||
        (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthday) age -= 1;
    return age;
  }

  double? get _heightCm => double.tryParse(_heightCtl.text.trim());
  double? get _weightKg => double.tryParse(_weightCtl.text.trim());
  double? get _targetKg => double.tryParse(_targetCtl.text.trim());

  bool get _step2Valid =>
      _nameCtl.text.trim().isNotEmpty &&
      _gender.isNotEmpty &&
      _dob != null;

  bool get _step3Valid {
    final h = _heightCm;
    final w = _weightKg;
    final t = _targetKg;
    return (h != null && h > 0) &&
        (w != null && w > 0) &&
        (t != null && t > 0);
  }

  bool get _step4Valid => _activityIndex != null;

  int _computeTdee() {
    final h = _heightCm ?? 175.0;
    final w = _weightKg ?? 70.0;
    final age = _ageFromDob(_dob) ?? 25;
    // Mifflin-St Jeor.
    final bmrMale = (10 * w) + (6.25 * h) - (5 * age) + 5;
    final bmrFemale = (10 * w) + (6.25 * h) - (5 * age) - 161;
    final double bmr;
    switch (_gender) {
      case 'Male':
        bmr = bmrMale;
        break;
      case 'Female':
        bmr = bmrFemale;
        break;
      default:
        bmr = (bmrMale + bmrFemale) / 2;
    }
    final mult = _activityMultipliers[_activityIndex ?? 2];
    final tdee = (bmr * mult).round();
    // Snap to nearest 10 kcal for a nicer-looking suggestion.
    return ((tdee / 10).round()) * 10;
  }

  void _ensureCalorieGoalSeeded() {
    _calorieGoal ??= _computeTdee();
  }

  void _continue() {
    HapticFeedback.selectionClick();
    if (_step >= _stepCount - 1) return;
    setState(() => _step = _step + 1);
    if (_step == _stepCount - 1) _ensureCalorieGoalSeeded();
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    HapticFeedback.selectionClick();
    if (_step == 0) return;
    setState(() => _step = _step - 1);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  /// User opted to bypass onboarding entirely. Mark complete with the
  /// global defaults — they can finish setup later via the banner on
  /// Home or from Settings.
  Future<void> _skipAll() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (_auth != null) {
        await _auth!.markOnboardingComplete();
      }
      if (!mounted) return;
      Get.offAll(() => MainPage());
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final activityKey = _activityKeys[_activityIndex ?? 2];

      final enteredName = _nameCtl.text.trim();

      // Persist profile fields via the existing controller method.
      // Pass `name` ONLY when the user actually typed something so we
      // don't overwrite an existing display name with empty.
      await _profile.updateProfile(
        name: enteredName.isNotEmpty ? enteredName : null,
        currentWeight: _weightKg,
        targetWeight: _targetKg,
        userHeight: _heightCm,
        userAge: _ageFromDob(_dob),
        userGender: _gender,
      );

      // Make sure FirebaseAuth and the AuthController user model also
      // carry the name — otherwise `user.displayName` stays empty on
      // restart and the greeting falls back to email-derived "check1".
      if (enteredName.isNotEmpty && _auth != null) {
        try {
          await _auth!.updateProfile(displayName: enteredName);
        } catch (_) {/* non-fatal */}
      }

      // Persist activity level. The profile controller doesn't take it
      // directly, so write it to the storage key the rest of the app
      // can read and also push it onto the user model via AuthController.
      _profile.activityLevelChoice.value = activityKey;
      await _profile.storage.write('activity_level', activityKey);
      if (_auth != null) {
        await _auth!.updateProfile(activityLevel: activityKey);
      }

      // Persist calorie goal — push through NutritionController.updateGoals
      // so it writes to preferences + reflects in the home dashboard.
      final goal = (_calorieGoal ?? _computeTdee()).toDouble();
      try {
        if (Get.isRegistered<NutritionController>()) {
          await Get.find<NutritionController>().updateGoals(calories: goal);
        }
      } catch (_) {/* non-fatal */}

      // Mark onboarding complete on the user doc — this is the source
      // of truth the auth-state listener reads to decide routing.
      try {
        if (_auth != null) {
          await _auth!.markOnboardingComplete();
        }
      } catch (_) {/* non-fatal */}

      if (!mounted) return;
      Get.offAll(() => MainPage());
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  Future<void> _skipPhoto() async {
    _continue();
  }

  Future<void> _pickPhoto() async {
    HapticFeedback.lightImpact();
    await _profile.updateProfileImage();
  }

  Future<void> _pickDob() async {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final initial = _dob ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 5, now.month, now.day),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: scheme.primary,
                  onPrimary: scheme.onPrimary,
                ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(scheme),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (i) {
                  setState(() => _step = i);
                  if (i == _stepCount - 1) _ensureCalorieGoalSeeded();
                },
                children: [
                  _stepWelcome(),
                  _stepBasic(),
                  _stepMetrics(),
                  _stepActivity(),
                  _stepCalories(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------
  // Top bar with back button and progress dots.
  // --------------------------------------------------------------------

  Widget _topBar(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: _step == 0
                ? const SizedBox.shrink()
                : IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: scheme.onSurface,
                    ),
                    onPressed: _back,
                  ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_stepCount, (i) {
                final isCurrent = i == _step;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isCurrent ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? scheme.primary
                        : scheme.outlineVariant.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
          SizedBox(
            height: 44,
            child: TextButton(
              onPressed: _saving ? null : _skipAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Skip',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------
  // Step 1 — welcome + optional avatar.
  // --------------------------------------------------------------------

  Widget _stepWelcome() {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Text(
            "Let's set up your profile",
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'A few details to personalize your goals.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 48),
          Obx(() {
            final url = _profile.profileImageUrl.value;
            final uploading = _profile.isUploadingImage.value;
            return GestureDetector(
              onTap: uploading ? null : _pickPhoto,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.outlineVariant,
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: uploading
                      ? Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: scheme.primary,
                            ),
                          ),
                        )
                      : (url.isEmpty
                          ? Icon(
                              Icons.person_outline_rounded,
                              size: 56,
                              color: scheme.primary.withValues(alpha: 0.7),
                            )
                          : CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              placeholder: (_, __) => Container(
                                color: scheme.primary.withValues(alpha: 0.08),
                              ),
                              errorWidget: (_, __, ___) => Icon(
                                Icons.person_outline_rounded,
                                size: 56,
                                color: scheme.primary.withValues(alpha: 0.7),
                              ),
                            )),
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          Obx(() {
            final url = _profile.profileImageUrl.value;
            return Text(
              url.isEmpty ? 'Tap to add a photo' : 'Tap to change photo',
              style: text.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            );
          }),
          const Spacer(),
          _primaryButton('Continue', _continue),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _skipPhoto,
            child: Text(
              'Skip for now',
              style: text.labelLarge?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------
  // Step 2 — name, gender, dob.
  // --------------------------------------------------------------------

  Widget _stepBasic() {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A bit about you',
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll use this to calculate your daily targets.",
            style: text.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 28),
          _label('Your name', scheme, text),
          const SizedBox(height: 8),
          _themedField(
            controller: _nameCtl,
            hint: 'How should we call you?',
            prefixIcon: Icons.person_outline_rounded,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 22),
          _label('Gender', scheme, text),
          const SizedBox(height: 10),
          Row(
            children: [
              _genderChip('Male', scheme, text),
              const SizedBox(width: 8),
              _genderChip('Female', scheme, text),
              const SizedBox(width: 8),
              _genderChip('Other', scheme, text),
            ],
          ),
          const SizedBox(height: 22),
          _label('Date of birth', scheme, text),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _pickDob,
            child: IgnorePointer(
              child: TextField(
                controller: TextEditingController(
                  text: _dob == null
                      ? ''
                      : '${_dob!.day.toString().padLeft(2, '0')} / '
                          '${_dob!.month.toString().padLeft(2, '0')} / '
                          '${_dob!.year}',
                ),
                style: text.bodyLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _inputDecoration(
                  scheme: scheme,
                  hint: 'DD / MM / YYYY',
                  prefixIcon: Icons.cake_outlined,
                  suffixIcon: Icons.calendar_today_rounded,
                ),
              ),
            ),
          ),
          if (_dob != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_ageFromDob(_dob)} years old',
              style: text.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
          const Spacer(),
          _primaryButton(
            'Continue',
            _step2Valid ? _continue : null,
          ),
        ],
      ),
    );
  }

  Widget _genderChip(String label, ColorScheme scheme, TextTheme text) {
    final selected = _gender == label;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _gender = label);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: Text(
              label,
              style: text.labelLarge?.copyWith(
                color: selected ? scheme.onPrimary : scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------
  // Step 3 — height, weight, target weight.
  // --------------------------------------------------------------------

  Widget _stepMetrics() {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Body metrics',
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll use these for your calorie target and BMI.",
            style: text.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 28),
          _label('Height', scheme, text),
          const SizedBox(height: 8),
          _themedField(
            controller: _heightCtl,
            hint: '175',
            prefixIcon: Icons.height_rounded,
            suffixText: 'cm',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          _label('Current weight', scheme, text),
          const SizedBox(height: 8),
          _themedField(
            controller: _weightCtl,
            hint: '70',
            prefixIcon: Icons.monitor_weight_outlined,
            suffixText: 'kg',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          _label('Target weight', scheme, text),
          const SizedBox(height: 8),
          _themedField(
            controller: _targetCtl,
            hint: '65',
            prefixIcon: Icons.flag_rounded,
            suffixText: 'kg',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const Spacer(),
          _primaryButton(
            'Continue',
            _step3Valid ? _continue : null,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------
  // Step 4 — activity level cards.
  // --------------------------------------------------------------------

  Widget _stepActivity() {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    const levels = [
      _ActivityOption(
        icon: Icons.airline_seat_recline_extra_rounded,
        title: 'Sedentary',
        subtitle: 'Little or no exercise',
      ),
      _ActivityOption(
        icon: Icons.directions_walk_rounded,
        title: 'Light',
        subtitle: 'Light exercise 1-3 days/week',
      ),
      _ActivityOption(
        icon: Icons.directions_run_rounded,
        title: 'Moderate',
        subtitle: 'Moderate exercise 3-5 days/week',
      ),
      _ActivityOption(
        icon: Icons.fitness_center_rounded,
        title: 'Active',
        subtitle: 'Heavy exercise 6-7 days/week',
      ),
      _ActivityOption(
        icon: Icons.local_fire_department_rounded,
        title: 'Very Active',
        subtitle: 'Very heavy / 2x per day',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How active are you?',
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick the option that best matches a typical week.',
            style: text.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: levels.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final opt = levels[i];
                final selected = _activityIndex == i;
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activityIndex = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primary.withValues(alpha: 0.12)
                          : scheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? scheme.primary
                            : scheme.outlineVariant,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? scheme.primary
                                : scheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            opt.icon,
                            size: 22,
                            color: selected
                                ? scheme.onPrimary
                                : scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt.title,
                                style: text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                opt.subtitle,
                                style: text.bodySmall?.copyWith(
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 160),
                          opacity: selected ? 1 : 0,
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: scheme.primary,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _primaryButton(
            'Continue',
            _step4Valid ? _continue : null,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------
  // Step 5 — calorie goal.
  // --------------------------------------------------------------------

  Widget _stepCalories() {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final goal = _calorieGoal ?? _computeTdee();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your daily calorie target',
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suggested for you based on your inputs. You can change '
            'this anytime.',
            style: text.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 36),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 28,
              ),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _stepButton(
                    icon: Icons.remove_rounded,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _calorieGoal = (goal - 50).clamp(800, 6000);
                      });
                    },
                    scheme: scheme,
                  ),
                  const SizedBox(width: 18),
                  Column(
                    children: [
                      Text(
                        '$goal',
                        style: text.displayMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'kcal / day',
                        style: text.labelLarge?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  _stepButton(
                    icon: Icons.add_rounded,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _calorieGoal = (goal + 50).clamp(800, 6000);
                      });
                    },
                    scheme: scheme,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _calorieGoal = _computeTdee());
              },
              icon: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: scheme.primary,
              ),
              label: Text(
                'Reset to suggested',
                style: text.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Spacer(),
          _primaryButton(
            _saving ? 'Setting up…' : 'Get started',
            _saving ? null : _finish,
          ),
        ],
      ),
    );
  }

  Widget _stepButton({
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme scheme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: scheme.onPrimary, size: 22),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------
  // Shared widgets.
  // --------------------------------------------------------------------

  Widget _label(String text, ColorScheme scheme, TextTheme tt) {
    return Text(
      text,
      style: tt.labelLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required ColorScheme scheme,
    String? hint,
    IconData? prefixIcon,
    IconData? suffixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      suffixText: suffixText,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: scheme.primary),
      suffixIcon: suffixIcon == null
          ? null
          : Icon(suffixIcon, color: scheme.onSurface.withValues(alpha: 0.6)),
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

  Widget _themedField({
    required TextEditingController controller,
    String? hint,
    IconData? prefixIcon,
    String? suffixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: text.bodyLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      decoration: _inputDecoration(
        scheme: scheme,
        hint: hint,
        prefixIcon: prefixIcon,
        suffixText: suffixText,
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor:
              scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor:
              scheme.onSurface.withValues(alpha: 0.38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: text.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: onPressed == null
                ? scheme.onSurface.withValues(alpha: 0.38)
                : scheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _ActivityOption {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ActivityOption({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
