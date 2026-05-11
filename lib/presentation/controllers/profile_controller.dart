import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';
import 'package:nutri_check/domain/entities/user_profile.dart';
import 'package:nutri_check/presentation/pages/auth/login_page.dart';
import 'package:nutri_check/domain/repositories/user_repository.dart';
import 'package:nutri_check/domain/repositories/nutrition_repository.dart';
import 'package:nutri_check/domain/repositories/preferences_repository.dart';

import 'auth_controller.dart';
import 'nutrition_controller.dart';

class ProfileController extends GetxController {
  final UserRepository _userRepository;
  final NutritionRepository _nutritionRepository;
  final PreferencesRepository _preferencesRepository;

  ProfileController({
    required UserRepository userRepository,
    required NutritionRepository nutritionRepository,
    required PreferencesRepository preferencesRepository,
  })  : _userRepository = userRepository,
        _nutritionRepository = nutritionRepository,
        _preferencesRepository = preferencesRepository;

  var isLoading = false.obs;
  var profileImageUrl = ''.obs;
  var userName = ''.obs;
  var userEmail = ''.obs;
  var userBio = ''.obs;
  var currentWeight = 70.0.obs;
  var targetWeight = 65.0.obs;
  var height = 175.0.obs;
  var age = 25.obs;
  var gender = 'Male'.obs;
  var joinDate = DateTime.now().obs;

  var notificationsEnabled = true.obs;
  var darkModeEnabled = false.obs;
  var weeklyReportsEnabled = true.obs;
  var dataBackupEnabled = true.obs;
  var reminderEnabled = true.obs;
  var unitSystem = 'Metric'.obs;

  var totalMealsLogged = 0.obs;
  var totalCaloriesConsumed = 0.0.obs;
  var streakDays = 0.obs;
  var weeklyCalories = <double>[].obs;

  /// Rolling weight history (most-recent-last), populated from local
  /// `weight_history` storage entries shaped as `"YYYY-MM-DD:weight"`.
  /// Shape: `RxList<double>` capped at 30 entries (one per day).
  /// Consumers that need date-stamped pairs should read `storage.read('weight_history')`
  /// directly and split each entry on `:` -> `[dateString, weightString]`.
  var monthlyWeight = <double>[].obs;
  var totalDaysTracked = 0.obs;

  var isSaving = false.obs;
  var isUploadingImage = false.obs;
  var isSyncing = false.obs;
  var isExporting = false.obs;

  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final weightController = TextEditingController();
  final targetController = TextEditingController();
  final heightController = TextEditingController();
  final ageController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final storage = GetStorage();

  static const String _achievementsStorageKey = 'achievements_unlocks';
  static const String _goalHitDaysStorageKey = 'goal_hit_days';

  // Map of achievement key -> unlock epoch millis. Empty = never unlocked.
  final RxMap<String, int> achievementUnlocks = <String, int>{}.obs;

  // Set of YYYY-MM-DD strings where the user hit their calorie goal.
  final RxSet<String> goalHitDays = <String>{}.obs;

  // Reactive list of all achievements with computed state (read by the UI).
  // Each entry: { key, title, description, icon, unlocked, unlockedAt,
  // progress, progressMax }.
  final RxList<Map<String, dynamic>> achievements =
      <Map<String, dynamic>>[].obs;

  static const List<Map<String, dynamic>> _catalog = [
    {
      'key': 'first_meal',
      'title': 'First bite',
      'description': 'Log your first meal',
    },
    {
      'key': 'week_streak',
      'title': '7-day streak',
      'description': 'Log meals 7 days in a row',
    },
    {
      'key': 'month_streak',
      'title': '30-day streak',
      'description': 'Log meals 30 days in a row',
    },
    {
      'key': 'hundred_meals',
      'title': '100 meals',
      'description': 'Log 100 meals in total',
    },
    {
      'key': 'goal_hit_once',
      'title': 'On target',
      'description': 'Hit your calorie goal in a single day',
    },
    {
      'key': 'goal_hit_week',
      'title': 'Consistent week',
      'description': 'Hit your calorie goal on 5 days within a week',
    },
    {
      'key': 'weight_logged',
      'title': 'Step on the scale',
      'description': 'Log your weight for the first time',
    },
    {
      'key': 'half_year',
      'title': 'Half-year hero',
      'description': 'Log meals 180 days in a row',
    },
  ];

  var lastLoginDate = DateTime.now().obs;
  var profileCompleteness = 0.0.obs;
  var totalDataPoints = 0.obs;
  var averageCaloriesPerDay = 0.0.obs;
  var averageMealsPerDay = 0.0.obs;

  final List<Worker> _workers = [];
  UserProfile? _cachedProfile;

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  @override
  void onClose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    _disposeControllers();
    super.onClose();
  }

  Future<void> _initializeController() async {
    try {
      await _loadCachedData();
      await _loadUserProfile();
      await _loadUserStats();
      _setupReactiveListeners();
      _setupNutritionListeners();
      _calculateProfileCompleteness();
      await _loadAchievementsState();
      _setupAchievementListeners();
      _checkAchievements();
    } catch (e) {
      _showErrorSnackbar('Failed to initialize profile');
    }
  }

  void _setupAchievementListeners() {
    _workers.addAll([
      ever<int>(totalMealsLogged, (_) => _checkAchievements()),
      ever<int>(streakDays, (_) => _checkAchievements()),
      ever<double>(currentWeight, (_) => _checkAchievements()),
      ever<List<double>>(monthlyWeight, (_) => _checkAchievements()),
    ]);
    try {
      if (Get.isRegistered<NutritionController>()) {
        final nc = Get.find<NutritionController>();
        _workers.add(ever<double>(
          nc.totalCalories,
          (_) => _checkCalorieGoalHit(),
        ));
      }
    } catch (_) {}
  }

  Future<void> _loadAchievementsState() async {
    try {
      final raw = storage.read(_achievementsStorageKey);
      if (raw is Map) {
        achievementUnlocks.assignAll(
          raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
        );
      }
      final days = storage.read(_goalHitDaysStorageKey);
      if (days is List) {
        goalHitDays.assignAll(days.map((e) => e.toString()).toSet());
      }
    } catch (_) {}
  }

  Future<void> _persistAchievements() async {
    try {
      await storage.write(
        _achievementsStorageKey,
        Map<String, int>.from(achievementUnlocks),
      );
    } catch (_) {}
  }

  Future<void> _persistGoalHitDays() async {
    try {
      final list = goalHitDays.toList()..sort();
      await storage.write(_goalHitDaysStorageKey, list);
    } catch (_) {}
  }

  void _checkCalorieGoalHit() {
    if (!Get.isRegistered<NutritionController>()) return;
    final nc = Get.find<NutritionController>();
    final consumed = nc.totalCalories.value;
    final goal = nc.calorieGoal.value;
    if (goal <= 0) return;
    final ratio = consumed / goal;
    if (ratio >= 0.95 && ratio <= 1.05) {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (!goalHitDays.contains(today)) {
        goalHitDays.add(today);
        _persistGoalHitDays();
        _checkAchievements();
      }
    }
  }

  void _checkAchievements() {
    final newlyUnlocked = <String>[];
    for (final def in _catalog) {
      final key = def['key'] as String;
      if (achievementUnlocks.containsKey(key)) continue;
      if (_evaluate(key)) {
        achievementUnlocks[key] = DateTime.now().millisecondsSinceEpoch;
        newlyUnlocked.add(key);
      }
    }
    if (newlyUnlocked.isNotEmpty) {
      _persistAchievements();
      for (final key in newlyUnlocked.take(2)) {
        final def = _catalog.firstWhere((e) => e['key'] == key);
        HapticFeedback.mediumImpact();
        CustomThemeFlushbar.show(
          title: 'Achievement unlocked',
          message: '${def['title']} — ${def['description']}',
        );
      }
    }
    _refreshAchievementsList();
  }

  bool _evaluate(String key) {
    final meals = totalMealsLogged.value;
    final streak = streakDays.value;
    switch (key) {
      case 'first_meal':
        return meals >= 1;
      case 'week_streak':
        return streak >= 7;
      case 'month_streak':
        return streak >= 30;
      case 'half_year':
        return streak >= 180;
      case 'hundred_meals':
        return meals >= 100;
      case 'goal_hit_once':
        return goalHitDays.isNotEmpty;
      case 'goal_hit_week':
        return _hasGoalHitWeek(goalHitDays.toList()..sort());
      case 'weight_logged':
        return monthlyWeight.isNotEmpty;
      default:
        return false;
    }
  }

  bool _hasGoalHitWeek(List<String> sortedDays) {
    if (sortedDays.length < 5) return false;
    final set = sortedDays.toSet();
    for (final d in sortedDays) {
      final date = DateTime.tryParse(d);
      if (date == null) continue;
      int count = 0;
      for (int i = 0; i < 7; i++) {
        final check = date.subtract(Duration(days: i));
        final k = DateFormat('yyyy-MM-dd').format(check);
        if (set.contains(k)) count++;
      }
      if (count >= 5) return true;
    }
    return false;
  }

  void _refreshAchievementsList() {
    achievements.assignAll(_catalog.map((def) {
      final key = def['key'] as String;
      final unlockedAt = achievementUnlocks[key];
      final progress = _progressFor(key);
      return {
        'key': key,
        'title': def['title'],
        'description': def['description'],
        'icon': _iconFor(key),
        'unlocked': unlockedAt != null,
        'unlockedAt': unlockedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(unlockedAt),
        'progress': progress['current'],
        'progressMax': progress['max'],
      };
    }).toList());
  }

  Map<String, int> _progressFor(String key) {
    final meals = totalMealsLogged.value;
    final streak = streakDays.value;
    switch (key) {
      case 'first_meal':
        return {'current': meals.clamp(0, 1), 'max': 1};
      case 'week_streak':
        return {'current': streak.clamp(0, 7), 'max': 7};
      case 'month_streak':
        return {'current': streak.clamp(0, 30), 'max': 30};
      case 'half_year':
        return {'current': streak.clamp(0, 180), 'max': 180};
      case 'hundred_meals':
        return {'current': meals.clamp(0, 100), 'max': 100};
      case 'goal_hit_once':
        return {'current': goalHitDays.length.clamp(0, 1), 'max': 1};
      case 'goal_hit_week':
        return {'current': 0, 'max': 5};
      case 'weight_logged':
        return {'current': monthlyWeight.isEmpty ? 0 : 1, 'max': 1};
      default:
        return {'current': 0, 'max': 1};
    }
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'first_meal':
        return Icons.emoji_food_beverage_rounded;
      case 'week_streak':
        return Icons.local_fire_department_rounded;
      case 'month_streak':
        return Icons.whatshot_rounded;
      case 'hundred_meals':
        return Icons.restaurant_menu_rounded;
      case 'goal_hit_once':
        return Icons.flag_rounded;
      case 'goal_hit_week':
        return Icons.workspace_premium_rounded;
      case 'weight_logged':
        return Icons.monitor_weight_outlined;
      case 'half_year':
        return Icons.military_tech_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  Future<void> updateWeight(double kg) async {
    try {
      if (kg <= 0 || kg > 1000) {
        throw Exception('Weight must be between 1 and 1000 kg');
      }
      final oldWeight = currentWeight.value;
      currentWeight.value = kg;
      weightController.text = kg.toString();
      await _syncWeightWithNutrition(oldWeight, kg);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating weight: $e');
      }
      CustomThemeFlushbar.show(
        title: 'Update Failed',
        message: 'Failed to update weight: ${e.toString()}',
      );
    }
  }

  void _setupNutritionListeners() {
    try {
      final nutritionController = Get.find<NutritionController>();

      _workers.addAll([
        ever(nutritionController.todayMeals, (_) => _calculateStats()),
        ever(nutritionController.totalCalories, (_) => _calculateStats()),
        ever(nutritionController.viewMode, (_) => _calculateStats()),
      ]);

      _calculateStats();
    } catch (e) {
      Future.delayed(const Duration(seconds: 2), () {
        try {
          final nutritionController = Get.find<NutritionController>();
          _workers.addAll([
            ever(nutritionController.todayMeals, (_) => _calculateStats()),
            ever(nutritionController.totalCalories, (_) => _calculateStats()),
            ever(nutritionController.viewMode, (_) => _calculateStats()),
          ]);
          _calculateStats();
        } catch (e) {
          if (kDebugMode) {
            print('Failed nutrition listeners: $e');
          }
        }
      });
    }
  }

  Future<void> _calculateStats() async {
    try {
      final nutritionController = Get.find<NutritionController>();

      if (kDebugMode) {
        print('ProfileController: Calculating stats...');
      }

      final currentMeals = nutritionController.currentMeals;
      totalMealsLogged.value = currentMeals.length;
      totalCaloriesConsumed.value = nutritionController.totalCalories.value;

      await _calculateStreakDays();
      _calculateAdditionalStats();

      if (kDebugMode) {
        print(
          'ProfileController: Stats updated - Meals: ${totalMealsLogged.value}, Calories: ${totalCaloriesConsumed.value.toInt()}, Streak: ${streakDays.value}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('ProfileController: Error calculating stats: $e');
      }
    }
  }

  Future<void> _calculateStreakDays() async {
    try {
      final authController = Get.find<AuthController>();

      final user = authController.user;
      if (user == null) {
        streakDays.value = 0;
        return;
      }

      final uid = user.uid;
      final now = DateTime.now();
      final result = await _nutritionRepository.getMonthlyIntake(uid, now);

      final dateKeys = <String>{};

      result.fold(
        onSuccess: (intakes) {
          for (final intake in intakes) {
            if (intake.meals.isNotEmpty) {
              dateKeys.add(_formatDate(intake.date));
            }
          }
        },
        onFailure: (_) {},
      );

      int streak = 0;
      for (int i = 0; i < 30; i++) {
        final checkDate = now.subtract(Duration(days: i));
        final dateString = _formatDate(checkDate);

        if (dateKeys.contains(dateString)) {
          streak++;
        } else if (i > 0) {
          break;
        }
      }

      streakDays.value = streak;
      if (kDebugMode) {
        print('Calculated streak: $streak days');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating streak: $e');
      }
      streakDays.value = 0;
    }
  }

  void _calculateAdditionalStats() {
    try {
      final nutritionController = Get.find<NutritionController>();

      switch (nutritionController.viewMode.value) {
        case 'weekly':
          final weeklyStats = nutritionController.weeklyStats;
          final daysWithData = weeklyStats['daysWithData'] ?? 1;
          averageCaloriesPerDay.value =
              weeklyStats['averageCalories'] ?? 0.0;
          averageMealsPerDay.value = daysWithData > 0
              ? (weeklyStats['totalMeals'] ?? 0) / daysWithData.toDouble()
              : 0.0;
          totalDaysTracked.value = daysWithData;
          break;

        case 'monthly':
          final monthlyStats = nutritionController.monthlyStats;
          final daysWithData = monthlyStats['daysWithData'] ?? 1;
          averageCaloriesPerDay.value =
              monthlyStats['averageCalories'] ?? 0.0;
          averageMealsPerDay.value = daysWithData > 0
              ? (monthlyStats['totalMeals'] ?? 0) / daysWithData.toDouble()
              : 0.0;
          totalDaysTracked.value = daysWithData;
          break;

        default:
          averageCaloriesPerDay.value =
              nutritionController.totalCalories.value;
          averageMealsPerDay.value =
              nutritionController.todayMeals.length.toDouble();
          totalDaysTracked.value = 1;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating additional stats: $e');
      }
    }
  }

  Future<void> refreshStats() async {
    if (kDebugMode) {
      print('ProfileController: Manual stats refresh');
    }
    await _calculateStats();
  }

  String get formattedTotalCalories {
    if (totalCaloriesConsumed.value >= 1000) {
      return '${(totalCaloriesConsumed.value / 1000).toStringAsFixed(1)}k';
    }
    return totalCaloriesConsumed.value.toInt().toString();
  }

  String get formattedAverageCalories {
    if (averageCaloriesPerDay.value >= 1000) {
      return '${(averageCaloriesPerDay.value / 1000).toStringAsFixed(1)}k';
    }
    return averageCaloriesPerDay.value.toInt().toString();
  }

  Future<void> _loadCachedData() async {
    try {
      final cachedWeight = storage.read('user_weight');
      if (cachedWeight != null) {
        currentWeight.value = cachedWeight.toDouble();
      }

      final cachedName = storage.read('user_name');
      if (cachedName != null) {
        userName.value = cachedName;
      }

      final cachedEmail = storage.read('user_email');
      if (cachedEmail != null) {
        userEmail.value = cachedEmail;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cached data: $e');
      }
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      isLoading.value = true;
      final authController = Get.find<AuthController>();

      if (authController.user == null) {
        if (kDebugMode) {
          print('No authenticated user found');
        }
        return;
      }

      final user = authController.user!;

      await _extractUserAuthData(user);
      await _loadProfileFromRepo(user.uid);
      await _loadPreferences(user.uid);

      _updateControllers();

      await _syncWeightWithNutrition(70.0, currentWeight.value);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading profile: $e');
      }
      _showErrorSnackbar('Failed to load profile: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _extractUserAuthData(user) async {
    try {
      userName.value = user.displayName ?? 'Anonymous User';
      userEmail.value = user.email ?? '';
      profileImageUrl.value = user.photoURL ?? '';

      await storage.write('user_name', userName.value);
      await storage.write('user_email', userEmail.value);

      if (kDebugMode) {
        print('User auth data extracted: ${userName.value}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting user data: $e');
      }
    }
  }

  Future<void> _loadProfileFromRepo(String uid) async {
    try {
      final result = await _userRepository.getUserProfile(uid);

      await result.fold(
        onSuccess: (profile) async {
          _cachedProfile = profile;
          _applyProfileToObservables(profile);
        },
        onFailure: (_) async {
          if (kDebugMode) {
            print('No profile found, creating default');
          }
          await _createDefaultProfile(uid);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Profile load error: $e');
      }
    }
  }

  void _applyProfileToObservables(UserProfile profile) {
    if (profile.bio != null) userBio.value = profile.bio!;
    profileImageUrl.value =
        profile.profileImageUrl ?? profile.photoURL ?? '';
    currentWeight.value = profile.currentWeight;
    targetWeight.value = profile.targetWeight;
    height.value = profile.height;
    age.value = profile.age;
    gender.value = _genderToString(profile.gender);
    if (profile.joinDate != null) {
      joinDate.value = profile.joinDate!;
    }

    storage.write('user_weight', profile.currentWeight);
  }

  Future<void> _createDefaultProfile(String uid) async {
    try {
      final profile = UserProfile(
        id: uid,
        email: userEmail.value,
        displayName: userName.value,
        bio: '',
        joinDate: DateTime.now(),
      );

      final result = await _userRepository.createUserProfile(profile);

      if (result.isSuccess) {
        _cachedProfile = profile;
        if (kDebugMode) {
          print('Default profile created');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating default profile: $e');
      }
    }
  }

  Future<void> _loadPreferences(String uid) async {
    try {
      final result = await _preferencesRepository.getPreferences(uid);

      if (result.isSuccess) {
        final settings = result.value.settings;
        if (settings['notificationsEnabled'] is bool) {
          notificationsEnabled.value = settings['notificationsEnabled'];
        }
        if (settings['darkModeEnabled'] is bool) {
          darkModeEnabled.value = settings['darkModeEnabled'];
        }
        if (settings['weeklyReportsEnabled'] is bool) {
          weeklyReportsEnabled.value = settings['weeklyReportsEnabled'];
        }
        if (settings['dataBackupEnabled'] is bool) {
          dataBackupEnabled.value = settings['dataBackupEnabled'];
        }
        if (settings['reminderEnabled'] is bool) {
          reminderEnabled.value = settings['reminderEnabled'];
        }
        if (settings['unitSystem'] is String) {
          unitSystem.value = settings['unitSystem'];
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading preferences: $e');
      }
    }
  }

  void _setupReactiveListeners() {
    _workers.addAll([
      ever(currentWeight, (double weight) async {
        await _saveWeightPersistently(weight);
        await _updateWeightHistory(weight);
      }),
      ever(notificationsEnabled, (_) => _saveSettingsLocally()),
      ever(darkModeEnabled, (_) => _saveSettingsLocally()),
      ever(weeklyReportsEnabled, (_) => _saveSettingsLocally()),
    ]);
  }

  void _saveSettingsLocally() async {
    try {
      await storage.write('settings', {
        'notifications': notificationsEnabled.value,
        'darkMode': darkModeEnabled.value,
        'weeklyReports': weeklyReportsEnabled.value,
        'dataBackup': dataBackupEnabled.value,
        'reminder': reminderEnabled.value,
        'unitSystem': unitSystem.value,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error saving settings locally: $e');
      }
    }
  }

  Future<void> _saveWeightPersistently(double weight) async {
    try {
      await storage.write('user_weight', weight);
      if (kDebugMode) {
        print('Weight saved locally: ${weight}kg');
      }

      await _saveWeightToRepo(weight);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving weight persistently: $e');
      }
    }
  }

  Future<void> _saveWeightToRepo(double weight, [int retryCount = 0]) async {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.user;
      if (user == null) return;

      final uid = user.uid;
      final updatedProfile = _cachedProfile?.copyWith(currentWeight: weight) ??
          UserProfile(id: uid, email: userEmail.value, currentWeight: weight);

      final result = await _userRepository.updateUserProfile(updatedProfile);

      if (result.isSuccess) {
        _cachedProfile = updatedProfile;
        if (kDebugMode) {
          print('Weight synced via repo: ${weight}kg');
        }
      } else {
        throw Exception(result.failure.message);
      }
    } catch (e) {
      if (retryCount < 3) {
        if (kDebugMode) {
          print('Retrying weight save... (${retryCount + 1}/3)');
        }
        await Future.delayed(const Duration(seconds: 2));
        await _saveWeightToRepo(weight, retryCount + 1);
      } else {
        if (kDebugMode) {
          print('Failed to save weight: $e');
        }
      }
    }
  }

  Future<void> _updateWeightHistory(double weight) async {
    try {
      final history = storage.read('weight_history') ?? <String>[];
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final entry = '$today:$weight';

      history.removeWhere((entry) => entry.startsWith(today));
      history.add(entry);

      if (history.length > 90) {
        history.removeRange(0, history.length - 90);
      }

      await storage.write('weight_history', history);

      if (monthlyWeight.length >= 30) {
        monthlyWeight.removeAt(0);
      }
      monthlyWeight.add(weight);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating weight history: $e');
      }
    }
  }

  Future<void> _loadUserStats() async {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.user;
      if (user == null) return;

      await _loadNutritionStats(user.uid);
      await _loadWeightHistory();
      await _calculateActivityStats();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user stats: $e');
      }
    }
  }

  Future<void> _loadNutritionStats(String uid) async {
    try {
      final result =
          await _nutritionRepository.getMonthlyIntake(uid, DateTime.now());

      result.fold(
        onSuccess: (intakes) {
          int totalMeals = 0;
          double totalCals = 0.0;
          final Set<String> loggedDates = {};
          final List<double> dailyCalories = [];

          for (final intake in intakes) {
            totalMeals += intake.meals.length;
            totalCals += intake.totalCalories;
            dailyCalories.add(intake.totalCalories);
            loggedDates.add(_formatDate(intake.date));
          }

          totalMealsLogged.value = totalMeals;
          totalCaloriesConsumed.value = totalCals;
          weeklyCalories.value = dailyCalories.take(7).toList();
          totalDaysTracked.value = loggedDates.length;
          streakDays.value = _calculateStreak(loggedDates);

          if (kDebugMode) {
            print(
              'Nutrition stats loaded: $totalMeals meals, ${totalCals.toInt()} calories',
            );
          }
        },
        onFailure: (failure) {
          if (kDebugMode) {
            print('Error loading nutrition stats: ${failure.message}');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error loading nutrition stats: $e');
      }
    }
  }

  Future<void> _loadWeightHistory() async {
    try {
      final history = storage.read('weight_history') ?? <String>[];
      final weights = <double>[];

      for (String entry in history) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          final weight = double.tryParse(parts[1]);
          if (weight != null) {
            weights.add(weight);
          }
        }
      }

      monthlyWeight.value = weights.take(30).toList();
      if (kDebugMode) {
        print('Weight history loaded: ${weights.length} entries');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading weight history: $e');
      }
    }
  }

  Future<void> _calculateActivityStats() async {
    try {
      final lastLogin = storage.read('last_login_date');
      if (lastLogin != null) {
        lastLoginDate.value = DateTime.parse(lastLogin);
      }

      await storage.write('last_login_date', DateTime.now().toIso8601String());
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating activity stats: $e');
      }
    }
  }

  int _calculateStreak(Set<String> loggedDates) {
    if (loggedDates.isEmpty) return 0;

    final sortedDates = loggedDates.toList()..sort((a, b) => b.compareTo(a));
    final today = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final dateString = checkDate.toIso8601String().substring(0, 10);

      if (sortedDates.contains(dateString)) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }

    return streak;
  }

  void _calculateProfileCompleteness() {
    int completed = 0;
    final int total = 6;

    if (userName.value.isNotEmpty && userName.value != 'Anonymous User') {
      completed++;
    }
    if (userEmail.value.isNotEmpty) completed++;
    if (userBio.value.isNotEmpty) completed++;
    if (profileImageUrl.value.isNotEmpty) completed++;
    if (totalMealsLogged.value > 0) completed++;
    if (totalDaysTracked.value > 0) completed++;

    profileCompleteness.value = completed / total;
    if (kDebugMode) {
      print(
        'Profile completeness: ${(profileCompleteness.value * 100).toInt()}%',
      );
    }
  }

  Future<void> updateProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        isUploadingImage.value = true;

        final authController = Get.find<AuthController>();
        if (authController.user == null) {
          throw Exception('User not authenticated');
        }

        final user = authController.user!;

        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = await ref.putFile(
          File(image.path),
          SettableMetadata(contentType: 'image/jpeg'),
        );

        final downloadUrl = await uploadTask.ref.getDownloadURL();

        await user.updatePhotoURL(downloadUrl);

        final updatedProfile = _cachedProfile?.copyWith(
              profileImageUrl: downloadUrl,
              photoURL: downloadUrl,
            ) ??
            UserProfile(
              id: user.uid,
              email: user.email ?? '',
              profileImageUrl: downloadUrl,
              photoURL: downloadUrl,
            );

        final result = await _userRepository.updateUserProfile(updatedProfile);
        if (result.isSuccess) {
          _cachedProfile = updatedProfile;
        }

        profileImageUrl.value = downloadUrl;
        _calculateProfileCompleteness();
        CustomThemeFlushbar.show(
          title: 'Success',
          message: 'Profile image updated successfully',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile image: $e');
      }
      _showErrorSnackbar('Failed to update profile image: ${e.toString()}');
    } finally {
      isUploadingImage.value = false;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    double? currentWeight,
    double? targetWeight,
    double? userHeight,
    int? userAge,
    String? userGender,
  }) async {
    try {
      isSaving.value = true;

      final validationError = _validateProfileData(
        name,
        bio,
        currentWeight,
        targetWeight,
        userHeight,
        userAge,
        userGender,
      );

      if (validationError != null) {
        throw Exception(validationError);
      }

      final authController = Get.find<AuthController>();
      if (authController.user == null) {
        throw Exception('User not authenticated');
      }

      final user = authController.user!;

      await _updateAuthProfile(user, name);

      final updatedProfile = _cachedProfile?.copyWith(
            displayName: name?.trim(),
            bio: bio?.trim(),
            currentWeight: currentWeight,
            targetWeight: targetWeight,
            height: userHeight,
            age: userAge,
            gender: userGender != null ? _parseGender(userGender) : null,
          ) ??
          UserProfile(
            id: user.uid,
            email: user.email ?? '',
            displayName: name?.trim(),
            bio: bio?.trim(),
            currentWeight: currentWeight ?? this.currentWeight.value,
            targetWeight: targetWeight ?? this.targetWeight.value,
            height: userHeight ?? height.value,
            age: userAge ?? age.value,
            gender: userGender != null
                ? _parseGender(userGender)
                : _parseGender(gender.value),
          );

      final result = await _userRepository.updateUserProfile(updatedProfile);

      if (result.isSuccess) {
        _cachedProfile = updatedProfile;
      }

      await _updateLocalValues(
        name,
        bio,
        currentWeight,
        targetWeight,
        userHeight,
        userAge,
        userGender,
      );

      _updateControllers();
      _calculateProfileCompleteness();

      CustomThemeFlushbar.show(
        title: 'Profile Updated',
        message: 'Your profile has been updated successfully',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile: $e');
      }
      _showErrorSnackbar('Failed to update profile: ${e.toString()}');
    } finally {
      isSaving.value = false;
    }
  }

  String? _validateProfileData(
    String? name,
    String? bio,
    double? currentWeight,
    double? targetWeight,
    double? userHeight,
    int? userAge,
    String? userGender,
  ) {
    if (name != null && (name.trim().isEmpty || name.length > 50)) {
      return 'Name must be between 1 and 50 characters';
    }
    if (bio != null && bio.length > 500) {
      return 'Bio must be less than 500 characters';
    }
    if (currentWeight != null &&
        (currentWeight <= 0 || currentWeight > 1000)) {
      return 'Weight must be between 1 and 1000 kg';
    }
    if (targetWeight != null && (targetWeight <= 0 || targetWeight > 1000)) {
      return 'Target weight must be between 1 and 1000 kg';
    }
    if (userHeight != null && (userHeight <= 0 || userHeight > 300)) {
      return 'Height must be between 1 and 300 cm';
    }
    if (userAge != null && (userAge <= 0 || userAge > 150)) {
      return 'Age must be between 1 and 150 years';
    }
    return null;
  }

  Future<void> _updateAuthProfile(user, String? name) async {
    try {
      if (name != null && name.trim().isNotEmpty && name != userName.value) {
        await user.updateDisplayName(name.trim());
        if (kDebugMode) {
          print('Auth display name updated');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Auth update error (continuing): $e');
      }
    }
  }

  Future<void> _updateLocalValues(
    String? name,
    String? bio,
    double? currentWeight,
    double? targetWeight,
    double? userHeight,
    int? userAge,
    String? userGender,
  ) async {
    if (name != null && name.trim().isNotEmpty) {
      userName.value = name.trim();
      await storage.write('user_name', userName.value);
    }

    if (bio != null) userBio.value = bio.trim();

    if (currentWeight != null && currentWeight > 0) {
      final oldWeight = this.currentWeight.value;
      this.currentWeight.value = currentWeight;
      await _syncWeightWithNutrition(oldWeight, currentWeight);
    }

    if (targetWeight != null && targetWeight > 0) {
      this.targetWeight.value = targetWeight;
    }
    if (userHeight != null && userHeight > 0) height.value = userHeight;
    if (userAge != null && userAge > 0) age.value = userAge;
    if (userGender != null && userGender.isNotEmpty) gender.value = userGender;
  }

  Future<void> _syncWeightWithNutrition(
    double oldWeight,
    double newWeight,
  ) async {
    try {
      if (isSyncing.value) return;

      isSyncing.value = true;
      if (kDebugMode) {
        print('ProfileController: Syncing weight change...');
      }

      await _saveWeightPersistently(newWeight);

      try {
        final nutritionController = Get.find<NutritionController>();
        nutritionController.syncWeightChange(newWeight);
        if (kDebugMode) {
          print('Weight synced with NutritionController');
        }
      } catch (nutritionError) {
        if (kDebugMode) {
          print(
            'Nutrition sync failed (weight saved locally): $nutritionError',
          );
        }
        CustomThemeFlushbar.show(
          title: 'Partial Sync',
          message: 'Weight saved locally, nutrition sync will retry later',
        );
      }

      if (kDebugMode) {
        print('Weight sync complete: $oldWeight \u2192 $newWeight kg');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing weight: $e');
      }
    } finally {
      isSyncing.value = false;
    }
  }

  void _updateControllers() {
    nameController.text = userName.value;
    bioController.text = userBio.value;
    weightController.text = currentWeight.value.toString();
    targetController.text = targetWeight.value.toString();
    heightController.text = height.value.toString();
    ageController.text = age.value.toString();
  }

  Future<void> updateSettings({
    bool? notifications,
    bool? darkMode,
    bool? weeklyReports,
    bool? dataBackup,
    bool? reminder,
    String? unitSystem,
  }) async {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.user;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final uid = user.uid;

      if (notifications != null) notificationsEnabled.value = notifications;
      if (darkMode != null) darkModeEnabled.value = darkMode;
      if (weeklyReports != null) weeklyReportsEnabled.value = weeklyReports;
      if (dataBackup != null) dataBackupEnabled.value = dataBackup;
      if (reminder != null) reminderEnabled.value = reminder;
      if (unitSystem != null) this.unitSystem.value = unitSystem;

      UserPreferences prefs = const UserPreferences();
      final prefsResult = await _preferencesRepository.getPreferences(uid);
      if (prefsResult.isSuccess) {
        prefs = prefsResult.value;
      }

      final updatedSettings = Map<String, dynamic>.from(prefs.settings);
      if (notifications != null) {
        updatedSettings['notificationsEnabled'] = notifications;
      }
      if (darkMode != null) updatedSettings['darkModeEnabled'] = darkMode;
      if (weeklyReports != null) {
        updatedSettings['weeklyReportsEnabled'] = weeklyReports;
      }
      if (dataBackup != null) updatedSettings['dataBackupEnabled'] = dataBackup;
      if (reminder != null) updatedSettings['reminderEnabled'] = reminder;
      if (unitSystem != null) updatedSettings['unitSystem'] = unitSystem;

      final updatedPrefs = prefs.copyWith(settings: updatedSettings);
      await _preferencesRepository.savePreferences(uid, updatedPrefs);

      _saveSettingsLocally();

      CustomThemeFlushbar.show(
        title: 'Settings Updated',
        message: 'Your preferences have been saved',
      );
    } catch (e) {
      _showErrorSnackbar('Failed to update settings: ${e.toString()}');
    }
  }

  Future<void> exportUserData() async {
    try {
      isExporting.value = true;

      CustomThemeFlushbar.show(
        title: 'Exporting...',
        message: 'Preparing your data for export',
      );

      final authController = Get.find<AuthController>();
      final user = authController.user;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final exportData = await _collectExportData(user.uid);

      await storage.write(
        'exported_data_${DateTime.now().millisecondsSinceEpoch}',
        exportData,
      );

      CustomThemeFlushbar.show(
        title: 'Export Complete',
        message: 'Your data has been exported successfully',
      );
    } catch (e) {
      _showErrorSnackbar('Failed to export data: ${e.toString()}');
    } finally {
      isExporting.value = false;
    }
  }

  Future<Map<String, dynamic>> _collectExportData(String uid) async {
    final data = <String, dynamic>{};

    data['profile'] = {
      'name': userName.value,
      'email': userEmail.value,
      'bio': userBio.value,
      'weight': currentWeight.value,
      'height': height.value,
      'age': age.value,
      'gender': gender.value,
    };

    data['statistics'] = {
      'totalMeals': totalMealsLogged.value,
      'totalCalories': totalCaloriesConsumed.value,
      'streakDays': streakDays.value,
      'totalDaysTracked': totalDaysTracked.value,
    };

    data['weightHistory'] = storage.read('weight_history') ?? [];

    data['settings'] = {
      'notifications': notificationsEnabled.value,
      'darkMode': darkModeEnabled.value,
      'weeklyReports': weeklyReportsEnabled.value,
      'unitSystem': unitSystem.value,
    };

    data['exportedAt'] = DateTime.now().toIso8601String();

    return data;
  }

  Future<void> deleteAccount() async {
    try {
      final confirmed = await _showDeleteConfirmation();
      if (!confirmed) return;

      isLoading.value = true;
      final authController = Get.find<AuthController>();

      if (authController.user == null) {
        throw Exception('User not authenticated');
      }

      final user = authController.user!;

      final password = await _showPasswordDialog();
      if (password == null) {
        isLoading.value = false;
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      await _deleteUserData(user.uid);

      await storage.erase();

      await user.delete();

      Get.offAll(() => const LoginPage());

      CustomThemeFlushbar.show(
        title: 'Account Deleted',
        message: 'Your account and all data have been deleted successfully',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting account: $e');
      }
      _showErrorSnackbar('Failed to delete account: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    final ctx = Get.context;
    if (ctx == null) return false;

    final confirmed = await showModalBottomSheet<bool>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetCtx) {
        final scheme = Theme.of(sheetCtx).colorScheme;
        final textTheme = Theme.of(sheetCtx).textTheme;
        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: 16 + MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete account?',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This permanently removes your account, all logged meals, '
                  'and weight history. This cannot be undone.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(sheetCtx).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: scheme.outlineVariant),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetCtx).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return confirmed == true;
  }

  Future<String?> _showPasswordDialog() async {
    final passwordController = TextEditingController();
    final result = await Get.dialog<String>(
      AlertDialog(
        title: const Text('Re-authenticate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter your password to confirm account deletion.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: passwordController.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    passwordController.dispose();
    return result;
  }

  Future<void> _deleteUserData(String uid) async {
    await _userRepository.deleteUserProfile(uid);
    await _nutritionRepository.clearAllMeals(uid);
  }

  Future<void> signOut() async {
    try {
      _saveSettingsLocally();

      // Clear per-user local caches before tearing down the auth session
      // so the next signed-in user doesn't see stale data bleed through.
      try {
        final allKeys = storage.getKeys();
        final toRemove = <String>[];
        for (final k in allKeys) {
          final ks = k.toString();
          if (ks.startsWith('search_cache:') ||
              ks.startsWith('barcode_cache:')) {
            toRemove.add(ks);
          }
        }
        for (final k in toRemove) {
          await storage.remove(k);
        }
        await storage.remove('recent_searches');
        await storage.remove('weight_history');
        await storage.remove(_achievementsStorageKey);
        await storage.remove(_goalHitDaysStorageKey);
      } catch (e) {
        if (kDebugMode) {
          print('Error clearing local caches during sign-out: $e');
        }
      }

      // Clear in-memory Rx state.
      achievementUnlocks.clear();
      goalHitDays.clear();
      monthlyWeight.clear();
      achievements.clear();
      weeklyCalories.clear();
      totalMealsLogged.value = 0;
      totalCaloriesConsumed.value = 0.0;
      streakDays.value = 0;
      totalDaysTracked.value = 0;

      final authController = Get.find<AuthController>();
      await authController.signOut();

      final settings = storage.read('settings');
      await storage.erase();
      if (settings != null) {
        await storage.write('settings', settings);
      }

      Get.offAll(() => const LoginPage());
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
      _showErrorSnackbar('Failed to sign out: ${e.toString()}');
    }
  }

  Future<void> clearStoredData({bool keepSettings = true}) async {
    try {
      if (keepSettings) {
        final settings = storage.read('settings');
        await storage.erase();
        if (settings != null) {
          await storage.write('settings', settings);
        }
      } else {
        await storage.erase();
      }

      if (kDebugMode) {
        print('Stored data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing stored data: $e');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    CustomThemeFlushbar.show(title: '\u274C Error', message: message);
  }

  void _disposeControllers() {
    nameController.dispose();
    bioController.dispose();
    weightController.dispose();
    targetController.dispose();
    heightController.dispose();
    ageController.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Gender _parseGender(String value) {
    switch (value.toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        return Gender.other;
    }
  }

  String _genderToString(Gender value) {
    switch (value) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }

  double get bmi {
    if (height.value > 0 && currentWeight.value > 0) {
      final heightInMeters = height.value / 100;
      return currentWeight.value / (heightInMeters * heightInMeters);
    }
    return 0.0;
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  Color get bmiColor {
    final bmiValue = bmi;
    if (bmiValue < 18.5) return Colors.blue;
    if (bmiValue < 25) return Colors.green;
    if (bmiValue < 30) return Colors.orange;
    return Colors.red;
  }

  double get weightToTarget => currentWeight.value - targetWeight.value;

  String get weightToTargetText {
    final diff = weightToTarget;
    if (diff > 0) {
      return '${diff.toStringAsFixed(1)} kg above target';
    } else if (diff < 0) {
      return '${(-diff).toStringAsFixed(1)} kg to target';
    }
    return 'At target weight!';
  }

  String get profileCompletenessText {
    final percentage = (profileCompleteness.value * 100).toInt();
    if (percentage >= 90) return 'Profile Complete!';
    if (percentage >= 70) return 'Almost Complete';
    if (percentage >= 50) return 'Half Complete';
    return 'Needs Completion';
  }

  String get activityLevel {
    if (streakDays.value >= 30) return 'Super Active';
    if (streakDays.value >= 14) return 'Very Active';
    if (streakDays.value >= 7) return 'Active';
    if (streakDays.value >= 3) return 'Getting Started';
    return 'New User';
  }
}
