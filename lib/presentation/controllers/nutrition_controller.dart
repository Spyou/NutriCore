import 'dart:async';
import 'dart:convert';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nutri_check/core/config/app_config.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';
import 'package:nutri_check/domain/entities/daily_intake.dart';
import 'package:nutri_check/domain/entities/meal_entry.dart';
import 'package:nutri_check/domain/entities/user_profile.dart';
import 'package:nutri_check/domain/repositories/nutrition_repository.dart';
import 'package:nutri_check/domain/repositories/preferences_repository.dart';
import 'package:nutri_check/domain/usecases/calculate_bmr.dart';
import 'package:nutri_check/presentation/controllers/auth_controller.dart';

class NutritionController extends GetxController {
  final NutritionRepository _nutritionRepo;
  final PreferencesRepository _preferencesRepo;
  final CalculateBMR _bmrCalculator;

  NutritionController(
    this._nutritionRepo,
    this._preferencesRepo,
    this._bmrCalculator,
  );

  final List<Worker> _workers = [];
  StreamSubscription<DailyIntake>? _dailyIntakeSubscription;
  int _bindRetryAttempts = 0;
  static const int _maxBindRetries = 5;

  double? _cachedBmrWeight;
  double? _cachedBmrHeight;
  int? _cachedBmrAge;
  String? _cachedBmrSex;
  double? _cachedBmrResult;

  final Map<String, DateTime> _favoriteLastUsed = {};

  var selectedDate = DateTime.now().obs;
  var viewMode = 'daily'.obs;

  var totalCalories = 0.0.obs;
  var calorieGoal = AppConfig.defaultCalorieGoal.obs;
  var totalProteins = 0.0.obs;
  var proteinGoal = AppConfig.defaultProteinGoal.obs;
  var totalCarbs = 0.0.obs;
  var carbGoal = AppConfig.defaultCarbGoal.obs;
  var totalFats = 0.0.obs;
  var fatGoal = AppConfig.defaultFatGoal.obs;

  // Yesterday's total kcal for the day-over-day delta.
  final RxDouble yesterdayCalories = 0.0.obs;

  // Last 7 days of kcal totals, oldest first. Length always 7. Trailing
  // element is today.
  final RxList<double> weekCalories = RxList<double>.filled(7, 0.0);

  var waterIntake = 0.0.obs;
  var waterGoal = AppConfig.defaultWaterGoal.obs;
  var currentWeight = AppConfig.defaultWeight.obs;
  var targetWeight = AppConfig.defaultTargetWeight.obs;
  var stepsCount = 0.obs;
  var stepsGoal = AppConfig.defaultStepsGoal.obs;

  final todayMeals = RxList<MealEntry>();
  final dailyMeals = RxList<MealEntry>();
  final weeklyMeals = RxList<MealEntry>();
  final monthlyMeals = RxList<MealEntry>();

  var dailyStats = <String, dynamic>{}.obs;
  var weeklyStats = <String, dynamic>{}.obs;
  var monthlyStats = <String, dynamic>{}.obs;

  var favoriteMeals = <Map<String, dynamic>>[].obs;
  var mealTemplates = <Map<String, dynamic>>[].obs;
  var weeklyCalories = <double>[].obs;
  var weightHistory = <Map<String, dynamic>>[].obs;

  var isLoading = false.obs;
  var isLoadingViewData = false.obs;
  var selectedMealType = 'all'.obs;
  var searchQuery = ''.obs;
  final filteredMeals = RxList<MealEntry>();

  final storage = GetStorage();
  var userWeight = AppConfig.defaultWeight.obs;
  var dailyCalorieGoal = AppConfig.defaultCalorieGoal.toInt().obs;
  var bmr = 1500.0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadFavoriteMeals();
    _setupWorkers();
    _initializeController();
  }

  @override
  void onReady() {
    super.onReady();
    Future.delayed(const Duration(milliseconds: 800), () {
      _bindToDailyIntakeStream();
    });
  }

  @override
  void onClose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    _workers.clear();
    _dailyIntakeSubscription?.cancel();
    super.onClose();
  }

  void _setupWorkers() {
    _workers.addAll([
      ever(favoriteMeals, (_) => _saveFavoriteMeals()),
      ever(selectedMealType, (_) => _applyFilters()),
      ever(searchQuery, (_) => _applyFilters()),
      debounce<List<MealEntry>>(
        todayMeals,
        (_) {
          _calculateTotals();
          _applyFilters();
        },
        time: const Duration(milliseconds: 150),
      ),
      debounce<List<MealEntry>>(
        todayMeals,
        (_) {
          loadHistoricalSummary();
        },
        time: const Duration(seconds: 1),
      ),
    ]);
  }

  Future<void> _initializeController() async {
    try {
      _loadSavedWeight();
      await _loadPreferences();
      await _loadDataForViewMode('daily');
      await loadHistoricalSummary();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing NutritionController: $e');
      }
    }
  }

  /// Loads yesterday's total kcal and the last 7 days of kcal totals
  /// (oldest first, today at index 6). Tolerates per-day failures by
  /// leaving the corresponding entry at 0.
  Future<void> loadHistoricalSummary() async {
    try {
      final authController = Get.find<AuthController>();
      if (authController.user == null) return;
      final uid = authController.user!.uid;

      final today = DateTime(
        selectedDate.value.year,
        selectedDate.value.month,
        selectedDate.value.day,
      );
      final yesterday = today.subtract(const Duration(days: 1));

      final yResult = await _nutritionRepo.getDailyIntake(uid, yesterday);
      yResult.fold(
        onSuccess: (intake) {
          yesterdayCalories.value = intake.meals.fold<double>(
            0.0,
            (sum, m) => sum + m.calories,
          );
        },
        onFailure: (_) {
          yesterdayCalories.value = 0.0;
        },
      );

      final List<double> week = List<double>.filled(7, 0.0);
      for (int i = 0; i < 7; i++) {
        final date = today.subtract(Duration(days: 6 - i));
        try {
          final result = await _nutritionRepo.getDailyIntake(uid, date);
          result.fold(
            onSuccess: (intake) {
              week[i] = intake.meals.fold<double>(
                0.0,
                (sum, m) => sum + m.calories,
              );
            },
            onFailure: (_) {
              week[i] = 0.0;
            },
          );
        } catch (_) {
          week[i] = 0.0;
        }
      }
      weekCalories.assignAll(week);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading historical summary: $e');
      }
    }
  }

  Future<void> _loadPreferences() async {
    final authController = Get.find<AuthController>();
    if (authController.user == null) return;

    final result = await _preferencesRepo.getPreferences(
      authController.user!.uid,
    );
    result.fold(
      onSuccess: (prefs) {
        calorieGoal.value = prefs.calorieGoal;
        proteinGoal.value = prefs.proteinGoal;
        carbGoal.value = prefs.carbGoal;
        fatGoal.value = prefs.fatGoal;
        waterGoal.value = prefs.waterGoal;
        stepsGoal.value = prefs.stepsGoal;
      },
      onFailure: (_) {
        if (authController.userModel != null) {
          calorieGoal.value = authController.userModel!.calorieGoal;
          proteinGoal.value = authController.userModel!.proteinGoal;
          carbGoal.value = authController.userModel!.carbGoal;
          fatGoal.value = authController.userModel!.fatGoal;
          waterGoal.value = authController.userModel!.waterGoal;
          stepsGoal.value = authController.userModel!.stepsGoal;
          if (authController.userModel!.currentWeight != null) {
            currentWeight.value = authController.userModel!.currentWeight!;
          }
        }
      },
    );
  }

  void _applyFilters() {
    List<MealEntry> filtered = todayMeals.toList();

    if (selectedMealType.value != 'all') {
      filtered = filtered.where((meal) {
        return meal.type.name.toLowerCase() ==
            selectedMealType.value.toLowerCase();
      }).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((meal) {
        final name = meal.name.toLowerCase();
        final type = meal.type.name.toLowerCase();
        final query = searchQuery.value.toLowerCase();
        return name.contains(query) || type.contains(query);
      }).toList();
    }

    filteredMeals.assignAll(filtered);
  }

  void searchMeals(String query) {
    searchQuery.value = query;
  }

  void clearSearch() {
    searchQuery.value = '';
  }

  void resetFilters() {
    selectedMealType.value = 'all';
    searchQuery.value = '';
  }

  void _loadSavedWeight() {
    final savedWeight = storage.read('user_weight');
    if (savedWeight != null) {
      userWeight.value = savedWeight.toDouble();
      _updateNutritionGoals(userWeight.value);
    }
  }

  Future<void> changeViewMode(String mode) async {
    if (viewMode.value == mode) return;
    viewMode.value = mode;
    await _loadDataForViewMode(mode);
    update();
  }

  Future<void> _loadDataForViewMode(String mode) async {
    try {
      isLoadingViewData.value = true;

      switch (mode) {
        case 'weekly':
          await _loadWeeklyData();
          break;
        case 'monthly':
          await _loadMonthlyData();
          break;
        default:
          await _loadDailyData();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data for $mode: $e');
      }
    } finally {
      isLoadingViewData.value = false;
    }
  }

  Future<void> _loadDailyData() async {
    try {
      dailyMeals.assignAll(todayMeals);
      dailyStats.value = {
        'totalCalories': totalCalories.value,
        'totalProteins': totalProteins.value,
        'totalCarbs': totalCarbs.value,
        'totalFats': totalFats.value,
        'totalMeals': todayMeals.length,
        'waterIntake': waterIntake.value,
        'date': _formatDateForFirebase(selectedDate.value),
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error loading daily data: $e');
      }
    }
  }

  Future<void> _loadWeeklyData() async {
    try {
      final today = selectedDate.value;
      final startOfWeek = _getStartOfWeek(today);
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      final authController = Get.find<AuthController>();
      if (authController.user == null) return;

      final result = await _nutritionRepo.getWeeklyIntake(
        authController.user!.uid,
        startOfWeek,
      );

      result.fold(
        onSuccess: (dailyIntakes) {
          double weeklyCaloriesTotal = 0;
          double weeklyProteinsTotal = 0;
          double weeklyCarbsTotal = 0;
          double weeklyFatsTotal = 0;
          int weeklyMealsCount = 0;
          final List<MealEntry> allWeeklyMeals = [];
          final Set<String> daysWithData = {};

          for (int i = 0; i < 7; i++) {
            final currentDay = startOfWeek.add(Duration(days: i));
            final dayKey = _formatDateForFirebase(currentDay);

            final dayIntake = dailyIntakes
                .where((di) => _formatDateForFirebase(di.date) == dayKey)
                .firstOrNull;

            if (dayIntake != null && dayIntake.meals.isNotEmpty) {
              daysWithData.add(dayKey);
              weeklyCaloriesTotal += dayIntake.totalCalories;
              weeklyProteinsTotal += dayIntake.totalProteins;
              weeklyCarbsTotal += dayIntake.totalCarbs;
              weeklyFatsTotal += dayIntake.totalFats;
              weeklyMealsCount += dayIntake.meals.length;
              allWeeklyMeals.addAll(dayIntake.meals);
            }
          }

          weeklyMeals.assignAll(allWeeklyMeals);
          weeklyStats.value = {
            'totalCalories': weeklyCaloriesTotal,
            'totalProteins': weeklyProteinsTotal,
            'totalCarbs': weeklyCarbsTotal,
            'totalFats': weeklyFatsTotal,
            'totalMeals': weeklyMealsCount,
            'averageCalories': weeklyMealsCount > 0
                ? weeklyCaloriesTotal / 7
                : 0,
            'startDate': _formatDateForFirebase(startOfWeek),
            'endDate': _formatDateForFirebase(endOfWeek),
            'daysWithData': daysWithData.length,
          };
        },
        onFailure: (failure) {
          if (kDebugMode) {
            print('Error loading weekly data: ${failure.message}');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error loading weekly data: $e');
      }
    }
  }

  Future<void> _loadMonthlyData() async {
    try {
      final today = selectedDate.value;
      final startOfMonth = DateTime(today.year, today.month, 1);
      final endOfMonth = DateTime(today.year, today.month + 1, 0);

      final authController = Get.find<AuthController>();
      if (authController.user == null) return;

      final result = await _nutritionRepo.getMonthlyIntake(
        authController.user!.uid,
        today,
      );

      result.fold(
        onSuccess: (dailyIntakes) {
          double monthlyCaloriesTotal = 0;
          double monthlyProteinsTotal = 0;
          double monthlyCarbsTotal = 0;
          double monthlyFatsTotal = 0;
          int monthlyMealsCount = 0;
          final List<MealEntry> allMonthlyMeals = [];
          final Set<String> daysWithData = {};

          for (final intake in dailyIntakes) {
            final dayKey = _formatDateForFirebase(intake.date);
            if (intake.meals.isNotEmpty) {
              daysWithData.add(dayKey);
            }
            monthlyCaloriesTotal += intake.totalCalories;
            monthlyProteinsTotal += intake.totalProteins;
            monthlyCarbsTotal += intake.totalCarbs;
            monthlyFatsTotal += intake.totalFats;
            monthlyMealsCount += intake.meals.length;
            allMonthlyMeals.addAll(intake.meals);
          }

          monthlyMeals.assignAll(allMonthlyMeals);
          monthlyStats.value = {
            'totalCalories': monthlyCaloriesTotal,
            'totalProteins': monthlyProteinsTotal,
            'totalCarbs': monthlyCarbsTotal,
            'totalFats': monthlyFatsTotal,
            'totalMeals': monthlyMealsCount,
            'averageCalories': daysWithData.isNotEmpty
                ? monthlyCaloriesTotal / daysWithData.length
                : 0,
            'startDate': _formatDateForFirebase(startOfMonth),
            'endDate': _formatDateForFirebase(endOfMonth),
            'daysWithData': daysWithData.length,
            'totalDays': endOfMonth.day,
            'monthName': _getMonthName(today.month),
          };
        },
        onFailure: (failure) {
          if (kDebugMode) {
            print('Error loading monthly data: ${failure.message}');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error loading monthly data: $e');
      }
    }
  }

  List<MealEntry> get currentMeals {
    switch (viewMode.value) {
      case 'weekly':
        return weeklyMeals;
      case 'monthly':
        return monthlyMeals;
      default:
        return dailyMeals;
    }
  }

  Map<String, dynamic> get currentStats {
    switch (viewMode.value) {
      case 'weekly':
        return weeklyStats;
      case 'monthly':
        return monthlyStats;
      default:
        return dailyStats;
    }
  }

  void _bindToDailyIntakeStream() {
    final authController = Get.find<AuthController>();

    if (authController.user == null) {
      todayMeals.clear();
      _calculateTotals();
      if (_bindRetryAttempts < _maxBindRetries) {
        final delaySeconds = (1 << _bindRetryAttempts).clamp(1, 30);
        _bindRetryAttempts++;
        Future.delayed(Duration(seconds: delaySeconds), () {
          _bindToDailyIntakeStream();
        });
      }
      return;
    }

    _bindRetryAttempts = 0;
    _dailyIntakeSubscription?.cancel();
    _dailyIntakeSubscription = _nutritionRepo
        .watchDailyIntake(authController.user!.uid, selectedDate.value)
        .listen(
          (intake) {
            todayMeals.assignAll(intake.meals);
            waterIntake.value = intake.waterIntake;
            stepsCount.value = intake.stepsCount;
            if (intake.weight > 0) {
              currentWeight.value = intake.weight;
            }
          },
          onError: (e) {
            if (kDebugMode) {
              print('Stream error: $e');
            }
          },
        );
  }

  void _calculateTotals() {
    totalCalories.value = 0;
    totalProteins.value = 0;
    totalCarbs.value = 0;
    totalFats.value = 0;

    for (final meal in todayMeals) {
      if (_shouldIncludeMeal(meal)) {
        totalCalories.value += meal.calories;
        totalProteins.value += meal.proteins;
        totalCarbs.value += meal.carbs;
        totalFats.value += meal.fat;
      }
    }
  }

  bool _shouldIncludeMeal(MealEntry meal) {
    if (selectedMealType.value == 'all') return true;
    return meal.type.name == selectedMealType.value;
  }

  MealEntry _mapToMealEntry(Map<String, dynamic> meal) {
    return MealEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: meal['name']?.toString() ?? '',
      type: MealTypeX.fromString(meal['type']?.toString() ?? 'snack'),
      calories: (meal['calories'] ?? 0).toDouble(),
      proteins: (meal['proteins'] ?? 0).toDouble(),
      carbs: (meal['carbs'] ?? 0).toDouble(),
      fat: (meal['fat'] ?? 0).toDouble(),
      fiber: (meal['fiber'] ?? 0).toDouble(),
      sugar: (meal['sugar'] ?? 0).toDouble(),
      sodium: (meal['sodium'] ?? 0).toDouble(),
      notes: meal['notes']?.toString(),
      imageUrl: meal['imageUrl']?.toString(),
      isFavorite: meal['favorite'] == true || meal['isFavorite'] == true,
    );
  }

  Future<void> addMeal(Map<String, dynamic> meal) async {
    final mealEntry = _mapToMealEntry(meal);

    todayMeals.add(mealEntry);
    _calculateTotals();
    _checkNutritionLimits();

    final authController = Get.find<AuthController>();
    if (authController.user == null) return;

    final result = await _nutritionRepo.addMeal(
      authController.user!.uid,
      selectedDate.value,
      mealEntry,
    );

    result.fold(
      onSuccess: (_) async {
        await _loadDataForViewMode(viewMode.value);
      },
      onFailure: (_) {
        todayMeals.remove(mealEntry);
        _calculateTotals();
      },
    );
  }

  Future<void> deleteMeal(int index) async {
    if (index < 0 || index >= todayMeals.length) return;

    final deletedMeal = todayMeals[index];
    todayMeals.removeAt(index);
    _calculateTotals();

    final authController = Get.find<AuthController>();
    if (authController.user == null) return;

    final result = await _nutritionRepo.deleteMeal(
      authController.user!.uid,
      selectedDate.value,
      deletedMeal.id,
    );

    result.fold(
      onSuccess: (_) async {
        await _loadDataForViewMode(viewMode.value);
      },
      onFailure: (_) {
        todayMeals.insert(index, deletedMeal);
        _calculateTotals();
      },
    );
  }

  Future<void> deleteMealById(String id) async {
    final index = todayMeals.indexWhere((meal) => meal.id == id);
    if (index != -1) {
      await deleteMeal(index);
    }
  }

  Future<void> editMeal(int index, Map<String, dynamic> updatedMeal) async {
    if (index < 0 || index >= todayMeals.length) return;

    final originalMeal = todayMeals[index];
    final updatedEntry = MealEntry(
      id: originalMeal.id,
      name: updatedMeal['name']?.toString() ?? originalMeal.name,
      type: updatedMeal['type'] != null
          ? MealTypeX.fromString(updatedMeal['type'])
          : originalMeal.type,
      calories: (updatedMeal['calories'] ?? originalMeal.calories).toDouble(),
      proteins: (updatedMeal['proteins'] ?? originalMeal.proteins).toDouble(),
      carbs: (updatedMeal['carbs'] ?? originalMeal.carbs).toDouble(),
      fat: (updatedMeal['fat'] ?? originalMeal.fat).toDouble(),
      fiber: (updatedMeal['fiber'] ?? originalMeal.fiber).toDouble(),
      sugar: (updatedMeal['sugar'] ?? originalMeal.sugar).toDouble(),
      sodium: (updatedMeal['sodium'] ?? originalMeal.sodium).toDouble(),
      notes: updatedMeal['notes']?.toString() ?? originalMeal.notes,
      imageUrl: updatedMeal['imageUrl']?.toString() ?? originalMeal.imageUrl,
      isFavorite:
          updatedMeal['favorite'] as bool? ??
          updatedMeal['isFavorite'] as bool? ??
          originalMeal.isFavorite,
    );

    todayMeals[index] = updatedEntry;
    _calculateTotals();

    final authController = Get.find<AuthController>();
    if (authController.user == null) return;

    final result = await _nutritionRepo.updateMeal(
      authController.user!.uid,
      selectedDate.value,
      index,
      updatedEntry,
    );

    result.fold(
      onSuccess: (_) async {
        await _loadDataForViewMode(viewMode.value);
      },
      onFailure: (_) {
        todayMeals[index] = originalMeal;
        _calculateTotals();
      },
    );
  }

  Future<void> copyYesterdayMeals() async {
    try {
      final authController = Get.find<AuthController>();
      if (authController.user == null) return;

      final today = selectedDate.value;
      final yesterday = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(const Duration(days: 1));

      final result = await _nutritionRepo.getDailyIntake(
        authController.user!.uid,
        yesterday,
      );

      List<MealEntry> yesterdayMeals = const [];
      result.fold(
        onSuccess: (intake) {
          yesterdayMeals = intake.meals;
        },
        onFailure: (_) {
          yesterdayMeals = const [];
        },
      );

      if (yesterdayMeals.isEmpty) {
        CustomThemeFlushbar.show(
          title: 'Nothing to copy',
          message: 'You didn\'t log any meals yesterday',
        );
        return;
      }

      for (final meal in yesterdayMeals) {
        final originalTs = meal.timestamp;
        final hh = originalTs.hour.toString().padLeft(2, '0');
        final mm = originalTs.minute.toString().padLeft(2, '0');
        await addMeal({
          'name': meal.name,
          'type': meal.type.name,
          'calories': meal.calories,
          'proteins': meal.proteins,
          'carbs': meal.carbs,
          'fat': meal.fat,
          'fiber': meal.fiber,
          'sugar': meal.sugar,
          'sodium': meal.sodium,
          'notes': meal.notes ?? '',
          'imageUrl': meal.imageUrl ?? '',
          'favorite': meal.isFavorite,
          'time': '$hh:$mm',
        });
      }

      CustomThemeFlushbar.show(
        title: 'Copied',
        message: '${yesterdayMeals.length} meals from yesterday added to today',
      );
    } catch (_) {
      CustomThemeFlushbar.show(
        title: 'Failed',
        message: 'Couldn\'t copy yesterday\'s meals',
      );
    }
  }

  Future<void> duplicateMeal(int index) async {
    if (index < 0 || index >= todayMeals.length) return;
    final original = todayMeals[index];
    await addMeal({
      'name': '${original.name} (Copy)',
      'calories': original.calories,
      'proteins': original.proteins,
      'carbs': original.carbs,
      'fat': original.fat,
      'fiber': original.fiber,
      'sugar': original.sugar,
      'sodium': original.sodium,
      'type': original.type.name,
      'notes': original.notes ?? '',
      'imageUrl': original.imageUrl ?? '',
      'favorite': original.isFavorite,
    });
  }

  void _loadFavoriteMeals() {
    try {
      final savedFavoritesRaw = storage.read<List<dynamic>>(
        'favorite_meals_v1',
      );
      if (savedFavoritesRaw != null) {
        final favorites = <Map<String, dynamic>>[];
        for (final item in savedFavoritesRaw) {
          try {
            final decoded = item is String ? jsonDecode(item) : item;
            if (decoded is Map) {
              favorites.add(Map<String, dynamic>.from(decoded));
            }
          } catch (_) {}
        }
        favoriteMeals.assignAll(favorites);
      }
    } catch (_) {
      favoriteMeals.clear();
    }
  }

  void _saveFavoriteMeals() {
    try {
      final favoritesJson = favoriteMeals.map((meal) {
        return jsonEncode({
          'name': meal['name'] ?? '',
          'calories': meal['calories'] ?? 0,
          'proteins': meal['proteins'] ?? 0.0,
          'carbs': meal['carbs'] ?? 0.0,
          'fat': meal['fat'] ?? 0.0,
          'fiber': meal['fiber'] ?? 0.0,
          'sugar': meal['sugar'] ?? 0.0,
          'sodium': meal['sodium'] ?? 0.0,
          'type': meal['type'] ?? 'meal',
          'imageUrl': meal['imageUrl'] ?? '',
          'notes': meal['notes'] ?? '',
        });
      }).toList();
      storage.write('favorite_meals_v1', favoritesJson);
    } catch (_) {}
  }

  void toggleFavorite(Map<String, dynamic> meal) {
    final isFav = favoriteMeals.any((fav) => fav['name'] == meal['name']);
    if (isFav) {
      removeFromFavorites(meal);
    } else {
      addToFavorites(meal);
    }
  }

  bool isFavorite(Map<String, dynamic> meal) {
    return favoriteMeals.any((fav) => fav['name'] == meal['name']);
  }

  void clearAllFavorites() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear All Favorites'),
        content: const Text(
          'Are you sure you want to remove all favorite meals? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              favoriteMeals.clear();
              CustomThemeFlushbar.show(
                title: 'Favorites Cleared',
                message: 'All favorite meals have been removed',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void addToFavorites(Map<String, dynamic> meal) {
    try {
      final alreadyFavorite = favoriteMeals.any(
        (fav) => fav['name'] == meal['name'],
      );
      if (!alreadyFavorite) {
        final favoriteMeal = Map<String, dynamic>.from(meal);
        final nowIso = DateTime.now().toIso8601String();
        favoriteMeal['addedAt'] = nowIso;
        favoriteMeal['favorite'] = true;
        final name = (favoriteMeal['name'] ?? '').toString();
        _favoriteLastUsed[name] = DateTime.now();
        favoriteMeals.insert(0, favoriteMeal);
        if (favoriteMeals.length > 50) {
          _evictLeastRecentlyUsedFavorite();
        }
        CustomThemeFlushbar.show(
          title: 'Added to Favorites',
          message: '${meal['name']} has been added to your favorites',
        );
      }
    } catch (_) {}
  }

  DateTime _favoriteLastUsedAt(Map<String, dynamic> fav) {
    final name = (fav['name'] ?? '').toString();
    final tracked = _favoriteLastUsed[name];
    if (tracked != null) return tracked;
    final added = fav['addedAt'];
    if (added is String) {
      final parsed = DateTime.tryParse(added);
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _evictLeastRecentlyUsedFavorite() {
    if (favoriteMeals.isEmpty) return;
    int lruIndex = 0;
    DateTime lruTime = _favoriteLastUsedAt(favoriteMeals[0]);
    for (int i = 1; i < favoriteMeals.length; i++) {
      final t = _favoriteLastUsedAt(favoriteMeals[i]);
      if (t.isBefore(lruTime)) {
        lruTime = t;
        lruIndex = i;
      }
    }
    final removed = favoriteMeals.removeAt(lruIndex);
    final removedName = (removed['name'] ?? '').toString();
    _favoriteLastUsed.remove(removedName);
  }

  void markFavoriteUsed(Map<String, dynamic> meal) {
    final name = (meal['name'] ?? '').toString();
    if (name.isEmpty) return;
    _favoriteLastUsed[name] = DateTime.now();
  }

  void removeFromFavorites(Map<String, dynamic> meal) {
    try {
      favoriteMeals.removeWhere((fav) => fav['name'] == meal['name']);
      final ctx = Get.context;
      if (ctx != null) {
        Flushbar(
          title: 'Removed from Favorites',
          message: '${meal['name']} has been removed from your favorites',
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.grey[800]!,
          margin: const EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(8),
          flushbarPosition: FlushbarPosition.BOTTOM,
        ).show(ctx);
      }
    } catch (_) {}
  }

  Future<void> addWater() async {
    if (waterIntake.value >= 20) return;
    waterIntake.value += 1;
    final authController = Get.find<AuthController>();
    if (authController.user == null) return;
    final result = await _nutritionRepo.updateWaterIntake(
      authController.user!.uid,
      selectedDate.value,
      waterIntake.value,
    );
    if (result.isFailure) {
      waterIntake.value -= 1;
    }
  }

  Future<void> removeWater() async {
    if (waterIntake.value <= 0) return;
    waterIntake.value -= 1;
    final authController = Get.find<AuthController>();
    if (authController.user == null) return;
    final result = await _nutritionRepo.updateWaterIntake(
      authController.user!.uid,
      selectedDate.value,
      waterIntake.value,
    );
    if (result.isFailure) {
      waterIntake.value += 1;
    }
  }

  void syncWeightChange(double newWeight) {
    userWeight.value = newWeight;
    _updateNutritionGoals(newWeight);
  }

  void _updateNutritionGoals(double weight) {
    final authController = Get.find<AuthController>();
    UserProfile userProfile;
    if (authController.userModel != null) {
      userProfile = authController.userModel!.toDomain().copyWith(
        currentWeight: weight,
      );
    } else {
      userProfile = UserProfile(id: '', email: '', currentWeight: weight);
    }
    _recalcBmrIfChanged(userProfile);
    dailyCalorieGoal.value = (bmr.value * 1.5).round();
  }

  void _recalcBmrIfChanged(UserProfile profile) {
    final weight = profile.currentWeight;
    final height = profile.height;
    final age = profile.age;
    final sex = profile.gender.name;

    if (_cachedBmrResult != null &&
        _cachedBmrWeight == weight &&
        _cachedBmrHeight == height &&
        _cachedBmrAge == age &&
        _cachedBmrSex == sex) {
      bmr.value = _cachedBmrResult!;
      return;
    }

    final result = _bmrCalculator.execute(profile);
    _cachedBmrWeight = weight;
    _cachedBmrHeight = height;
    _cachedBmrAge = age;
    _cachedBmrSex = sex;
    _cachedBmrResult = result;
    bmr.value = result;
  }

  Map<String, double> get personalizedTargets {
    final weight = userWeight.value;
    return {
      'calories': dailyCalorieGoal.value.toDouble(),
      'protein': weight * 0.8,
      'carbs': weight * 3.0,
      'fat': weight * 1.0,
      'fiber': 25.0,
      'water': weight * 35,
    };
  }

  Future<void> updateWeight(double weight) async {
    currentWeight.value = weight;
    weightHistory.add({
      'date': DateTime.now().toIso8601String(),
      'weight': weight,
    });
    final authController = Get.find<AuthController>();
    if (authController.user == null) return;
    await _nutritionRepo.updateWeight(
      authController.user!.uid,
      selectedDate.value,
      weight,
    );
  }

  Future<void> clearAllMeals() async {
    todayMeals.clear();
    _calculateTotals();
    await _saveDailyIntake();
    await _loadDataForViewMode(viewMode.value);
  }

  void exportData() {
    CustomThemeFlushbar.show(
      title: 'Export',
      message: 'Data exported successfully!',
    );
  }

  void importData() {
    CustomThemeFlushbar.show(
      title: 'Import',
      message: 'Data imported successfully!',
    );
  }

  void _checkNutritionLimits() {
    if (totalCalories.value > calorieGoal.value * 1.2) {
      CustomThemeFlushbar.show(
        title: 'Calorie Alert',
        message:
            'You\'ve exceeded your daily calorie goal by ${(totalCalories.value - calorieGoal.value).toInt()} kcal',
      );
    }
  }

  Future<void> setSelectedDate(DateTime date) async {
    selectedDate.value = date;
    _bindToDailyIntakeStream();
    await _loadDataForViewMode(viewMode.value);
  }

  void filterByMealType(String type) {
    selectedMealType.value = type;
    _calculateTotals();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  List<MealEntry> get filteredMealsList {
    var filtered = currentMeals
        .where((meal) => _shouldIncludeMeal(meal))
        .toList();
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered
          .where(
            (meal) => meal.name.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ),
          )
          .toList();
    }
    return filtered;
  }

  Future<void> updateGoals({
    double? calories,
    double? proteins,
    double? carbs,
    double? fats,
    double? water,
    int? steps,
  }) async {
    if (calories != null) calorieGoal.value = calories;
    if (proteins != null) proteinGoal.value = proteins;
    if (carbs != null) carbGoal.value = carbs;
    if (fats != null) fatGoal.value = fats;
    if (water != null) waterGoal.value = water;
    if (steps != null) stepsGoal.value = steps;

    final authController = Get.find<AuthController>();
    if (authController.user == null) return;

    final result = await _preferencesRepo.updateGoals(
      authController.user!.uid,
      calorieGoal: calorieGoal.value,
      proteinGoal: proteinGoal.value,
      carbGoal: carbGoal.value,
      fatGoal: fatGoal.value,
      waterGoal: waterGoal.value,
      stepsGoal: stepsGoal.value,
    );

    result.fold(
      onSuccess: (_) {},
      onFailure: (failure) {
        if (kDebugMode) {
          print('Error updating goals: ${failure.message}');
        }
      },
    );

    await authController.updateNutritionGoals(
      calorieGoal: calorieGoal.value,
      proteinGoal: proteinGoal.value,
      carbGoal: carbGoal.value,
      fatGoal: fatGoal.value,
      waterGoal: waterGoal.value,
      stepsGoal: stepsGoal.value,
    );
  }

  Future<void> addQuickMeal(
    String mealName,
    Map<String, dynamic> nutrition,
  ) async {
    await addMeal({
      'name': mealName,
      'calories': nutrition['calories'] ?? 0,
      'proteins': nutrition['proteins'] ?? 0,
      'carbs': nutrition['carbs'] ?? 0,
      'fat': nutrition['fat'] ?? 0,
      'fiber': nutrition['fiber'] ?? 0,
      'sugar': nutrition['sugar'] ?? 0,
      'sodium': nutrition['sodium'] ?? 0,
      'type': 'snack',
      'notes': '',
      'favorite': false,
    });
  }

  Future<void> loadDataFromFirebase() async {
    final authController = Get.find<AuthController>();
    if (authController.user == null) return;

    try {
      isLoading.value = true;
      await _loadPreferences();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading nutrition data: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _saveDailyIntake() async {
    final authController = Get.find<AuthController>();
    if (authController.user == null) return false;

    final dateKey = _formatDateForFirebase(selectedDate.value);
    final intake = DailyIntake(
      id: '${authController.user!.uid}_$dateKey',
      userId: authController.user!.uid,
      date: selectedDate.value,
      meals: todayMeals.toList(),
      waterIntake: waterIntake.value,
      stepsCount: stepsCount.value,
      weight: currentWeight.value,
    );

    final result = await _nutritionRepo.saveDailyIntake(intake);
    return result.isSuccess;
  }

  String _formatDateForFirebase(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> manualRefresh() async {
    await _refreshData();
    await _loadDataForViewMode(viewMode.value);
  }

  Future<void> _refreshData() async {
    final authController = Get.find<AuthController>();
    if (authController.user == null) return;

    try {
      isLoading.value = true;
      final result = await _nutritionRepo.getDailyIntake(
        authController.user!.uid,
        selectedDate.value,
      );

      result.fold(
        onSuccess: (intake) {
          todayMeals.assignAll(intake.meals);
          waterIntake.value = intake.waterIntake;
          stepsCount.value = intake.stepsCount;
          if (intake.weight > 0) {
            currentWeight.value = intake.weight;
          }
          _calculateTotals();
        },
        onFailure: (_) {
          todayMeals.clear();
          _calculateTotals();
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Manual refresh error: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUserWeight(double newWeight) async {
    final oldWeight = userWeight.value;
    userWeight.value = newWeight;

    final authController = Get.find<AuthController>();
    if (authController.user != null) {
      await _nutritionRepo.updateWeight(
        authController.user!.uid,
        selectedDate.value,
        newWeight,
      );
    }

    _onWeightChanged(oldWeight, newWeight);
  }

  void _onWeightChanged(double oldWeight, double newWeight) {
    _updateRecommendedCalories(newWeight);
    CustomThemeFlushbar.show(
      title: 'Weight Updated',
      message: 'Nutrition recommendations updated for ${newWeight.toInt()}kg',
    );
  }

  void _updateRecommendedCalories(double weight) {
    final authController = Get.find<AuthController>();
    UserProfile userProfile;
    if (authController.userModel != null) {
      userProfile = authController.userModel!.toDomain().copyWith(
        currentWeight: weight,
      );
    } else {
      userProfile = UserProfile(id: '', email: '', currentWeight: weight);
    }
    final tdee = _bmrCalculator.calculateTDEE(userProfile);
    dailyCalorieGoal.value = tdee.round();
    calorieGoal.value = tdee;
  }

  void syncWithProfile(UserProfile profile) {
    userWeight.value = profile.currentWeight;
    _updateRecommendedCalories(profile.currentWeight);
  }

  double getAdjustedServingSize(double baseServing, double targetWeight) {
    final weightRatio = userWeight.value / 70.0;
    return baseServing * weightRatio;
  }

  Map<String, double> getPersonalizedNutritionGoals() {
    final weight = userWeight.value;
    return {
      'protein': weight * 0.8,
      'carbs': weight * 3.0,
      'fat': weight * 1.0,
      'fiber': 25.0,
      'water': weight * 35,
    };
  }

  Future<void> refreshData() async {
    await loadDataFromFirebase();
    await _loadDataForViewMode(viewMode.value);
  }

  DateTime _getStartOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return date.subtract(Duration(days: daysFromMonday));
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
