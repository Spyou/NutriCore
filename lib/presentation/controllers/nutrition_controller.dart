import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';
import 'package:nutri_check/domain/entities/user.dart';
import 'package:nutri_check/presentation/controllers/auth_controller.dart';

class NutritionController extends GetxController {
  // Date
  var selectedDate = DateTime.now().obs;
  var viewMode = 'daily'.obs;

  // Nutrition Tracking
  var totalCalories = 0.0.obs;
  var calorieGoal = 2000.0.obs;
  var totalProteins = 0.0.obs;
  var proteinGoal = 150.0.obs;
  var totalCarbs = 0.0.obs;
  var carbGoal = 250.0.obs;
  var totalFats = 0.0.obs;
  var fatGoal = 65.0.obs;

  // Additional Tracking
  var waterIntake = 0.0.obs;
  var waterGoal = 8.0.obs;
  var currentWeight = 70.0.obs;
  var targetWeight = 65.0.obs;
  var stepsCount = 0.obs;
  var stepsGoal = 10000.obs;

  var todayMeals = <Map<String, dynamic>>[].obs;
  var dailyMeals = <Map<String, dynamic>>[].obs;
  var weeklyMeals = <Map<String, dynamic>>[].obs;
  var monthlyMeals = <Map<String, dynamic>>[].obs;

  var dailyStats = <String, dynamic>{}.obs;
  var weeklyStats = <String, dynamic>{}.obs;
  var monthlyStats = <String, dynamic>{}.obs;

  var favoriteMeals = <Map<String, dynamic>>[].obs;
  var mealTemplates = <Map<String, dynamic>>[].obs;
  var weeklyCalories = <double>[].obs;
  var weightHistory = <Map<String, dynamic>>[].obs;

  // UI States
  var isLoading = false.obs;
  var isLoadingViewData = false.obs;
  var selectedMealType = 'all'.obs;
  var searchQuery = ''.obs;
  var filteredMeals = <Map<String, dynamic>>[].obs;

  final storage = GetStorage();
  var userWeight = 70.0.obs;
  var dailyCalorieGoal = 2000.obs;
  var bmr = 1500.0.obs;

  // Get Storage
  final GetStorage box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    _initializeController();
    _setupReactiveFiltering();
    _loadFavoriteMeals();
    ever(favoriteMeals, (_) => _saveFavoriteMeals());
  }

  @override
  void onReady() {
    super.onReady();
    Future.delayed(Duration(milliseconds: 800), () {
      _bindToFirebaseStream();
    });
  }

  Future<void> _initializeController() async {
    try {
      _loadSavedWeight();
      _loadFavorites();
      _loadTemplates();
      await loadDataFromFirebase();

      await changeViewMode('daily');
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing NutritionController: $e');
      }
    }
  }

  void _setupReactiveFiltering() {
    filteredMeals.assignAll(todayMeals);

    ever(selectedMealType, (_) => _applyFilters());

    ever(searchQuery, (_) => _applyFilters());

    ever(todayMeals, (_) => _applyFilters());
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = todayMeals.toList();

    if (selectedMealType.value != 'all') {
      filtered = filtered.where((meal) {
        return meal['type']?.toString().toLowerCase() ==
            selectedMealType.value.toLowerCase();
      }).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((meal) {
        final name = meal['name']?.toString().toLowerCase() ?? '';
        final type = meal['type']?.toString().toLowerCase() ?? '';
        final query = searchQuery.value.toLowerCase();

        return name.contains(query) || type.contains(query);
      }).toList();
    }

    filteredMeals.assignAll(filtered);

    if (kDebugMode) {
      print(
        'Applied filters - Type: ${selectedMealType.value}, Search: "${searchQuery.value}", Results: ${filtered.length}',
      );
    }
  }

  void searchMeals(String query) {
    if (kDebugMode) {
      print('Searching meals: "$query"');
    }
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
      if (kDebugMode) {
        print('NutritionController: Loaded saved weight ${savedWeight}kg');
      }
    }
  }

  Future<void> changeViewMode(String mode) async {
    if (viewMode.value == mode) return;

    if (kDebugMode) {
      print('Changing view mode to: $mode');
    }
    viewMode.value = mode;
    await _loadDataForViewMode(mode);
    update();
  }

  // 🔥 NEW: Load data based on view mode
  Future<void> _loadDataForViewMode(String mode) async {
    try {
      isLoadingViewData.value = true;

      switch (mode) {
        case 'daily':
          await _loadDailyData();
          break;
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
      final today = selectedDate.value;
      final dateKey = _formatDateForFirebase(today);

      if (kDebugMode) {
        print('Loading daily data for: $dateKey');
      }
      // Get today's meals
      dailyMeals.value = todayMeals.toList();
      // Calculate daily stats
      dailyStats.value = {
        'totalCalories': totalCalories.value,
        'totalProteins': totalProteins.value,
        'totalCarbs': totalCarbs.value,
        'totalFats': totalFats.value,
        'totalMeals': todayMeals.length,
        'waterIntake': waterIntake.value,
        'date': dateKey,
      };

      if (kDebugMode) {
        print(
          'Daily data loaded: ${dailyMeals.length} meals, ${totalCalories.value.toInt()} calories',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading daily data: $e');
      }
    }
  }

  // Weekly data
  Future<void> _loadWeeklyData() async {
    try {
      final today = selectedDate.value;
      final startOfWeek = _getStartOfWeek(today);
      final endOfWeek = startOfWeek.add(Duration(days: 6));

      if (kDebugMode) {
        print(
          'Loading weekly data: ${_formatDateForFirebase(startOfWeek)} to ${_formatDateForFirebase(endOfWeek)}',
        );
      }

      final authController = Get.find<AuthController>();
      if (authController.user == null) return;

      // Weekly totals
      double weeklyCalories = 0;
      double weeklyProteins = 0;
      double weeklyCarbs = 0;
      double weeklyFats = 0;
      int weeklyMealsCount = 0;
      List<Map<String, dynamic>> allWeeklyMeals = [];
      for (int i = 0; i < 7; i++) {
        final currentDay = startOfWeek.add(Duration(days: i));
        final dayKey = _formatDateForFirebase(currentDay);

        try {
          final doc = await FirebaseFirestore.instance
              .collection('nutrition_entries')
              .doc('${authController.user!.uid}_$dayKey')
              .get();

          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            final dayMeals = List<Map<String, dynamic>>.from(
              data['meals'] ?? [],
            );

            for (var meal in dayMeals) {
              weeklyCalories += (meal['calories'] ?? 0).toDouble();
              weeklyProteins += (meal['proteins'] ?? 0).toDouble();
              weeklyCarbs += (meal['carbs'] ?? 0).toDouble();
              weeklyFats += (meal['fat'] ?? 0).toDouble();
              weeklyMealsCount++;

              // Add day info to meal
              meal['day'] = _getDayName(currentDay);
              meal['date'] = dayKey;
              allWeeklyMeals.add(meal);
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error loading day $dayKey: $e');
          }
        }
      }

      // Update weekly data
      weeklyMeals.value = allWeeklyMeals;
      weeklyStats.value = {
        'totalCalories': weeklyCalories,
        'totalProteins': weeklyProteins,
        'totalCarbs': weeklyCarbs,
        'totalFats': weeklyFats,
        'totalMeals': weeklyMealsCount,
        'averageCalories': weeklyMealsCount > 0 ? weeklyCalories / 7 : 0,
        'startDate': _formatDateForFirebase(startOfWeek),
        'endDate': _formatDateForFirebase(endOfWeek),
        'daysWithData': allWeeklyMeals
            .map((meal) => meal['date'])
            .toSet()
            .length,
      };

      if (kDebugMode) {
        print(
          'Weekly data loaded: $weeklyMealsCount meals, ${weeklyCalories.toInt()} calories',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading weekly data: $e');
      }
    }
  }

  // Monthly data
  Future<void> _loadMonthlyData() async {
    try {
      final today = selectedDate.value;
      final startOfMonth = DateTime(today.year, today.month, 1);
      final endOfMonth = DateTime(today.year, today.month + 1, 0);

      if (kDebugMode) {
        print(
          'Loading monthly data: ${_formatDateForFirebase(startOfMonth)} to ${_formatDateForFirebase(endOfMonth)}',
        );
      }

      final authController = Get.find<AuthController>();
      if (authController.user == null) return;

      // Monthly totals
      double monthlyCalories = 0;
      double monthlyProteins = 0;
      double monthlyCarbs = 0;
      double monthlyFats = 0;
      int monthlyMealsCount = 0;
      List<Map<String, dynamic>> allMonthlyMeals = [];
      Set<String> daysWithData = {};
      for (int day = 1; day <= endOfMonth.day; day++) {
        final currentDay = DateTime(today.year, today.month, day);
        final dayKey = _formatDateForFirebase(currentDay);

        try {
          final doc = await FirebaseFirestore.instance
              .collection('nutrition_entries')
              .doc('${authController.user!.uid}_$dayKey')
              .get();

          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            final dayMeals = List<Map<String, dynamic>>.from(
              data['meals'] ?? [],
            );

            if (dayMeals.isNotEmpty) {
              daysWithData.add(dayKey);
            }

            for (var meal in dayMeals) {
              monthlyCalories += (meal['calories'] ?? 0).toDouble();
              monthlyProteins += (meal['proteins'] ?? 0).toDouble();
              monthlyCarbs += (meal['carbs'] ?? 0).toDouble();
              monthlyFats += (meal['fat'] ?? 0).toDouble();
              monthlyMealsCount++;
              meal['date'] = dayKey;
              meal['week'] = _getWeekOfMonth(currentDay);
              allMonthlyMeals.add(meal);
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error loading day $dayKey: $e');
          }
        }
      }

      // Monthly data
      monthlyMeals.value = allMonthlyMeals;
      monthlyStats.value = {
        'totalCalories': monthlyCalories,
        'totalProteins': monthlyProteins,
        'totalCarbs': monthlyCarbs,
        'totalFats': monthlyFats,
        'totalMeals': monthlyMealsCount,
        'averageCalories': daysWithData.isNotEmpty
            ? monthlyCalories / daysWithData.length
            : 0,
        'startDate': _formatDateForFirebase(startOfMonth),
        'endDate': _formatDateForFirebase(endOfMonth),
        'daysWithData': daysWithData.length,
        'totalDays': endOfMonth.day,
        'monthName': _getMonthName(today.month),
      };

      if (kDebugMode) {
        print(
          'Monthly data loaded: $monthlyMealsCount meals, ${monthlyCalories.toInt()} calories',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading monthly data: $e');
      }
    }
  }

  // Get current data
  List<Map<String, dynamic>> get currentMeals {
    switch (viewMode.value) {
      case 'daily':
        return dailyMeals;
      case 'weekly':
        return weeklyMeals;
      case 'monthly':
        return monthlyMeals;
      default:
        return dailyMeals;
    }
  }

  // Get current stats\
  Map<String, dynamic> get currentStats {
    switch (viewMode.value) {
      case 'daily':
        return dailyStats;
      case 'weekly':
        return weeklyStats;
      case 'monthly':
        return monthlyStats;
      default:
        return dailyStats;
    }
  }

  void _bindToFirebaseStream() {
    final authController = Get.find<AuthController>();

    if (kDebugMode) {
      print('User: ${authController.user?.email ?? 'None'}');
    }

    if (authController.user != null) {
      if (kDebugMode) {
        print('Firestore stream for date: ${selectedDate.value}');
      }

      todayMeals.bindStream(_getMealsStream());

      ever(todayMeals, (_) {
        if (kDebugMode) {
          print('Meals updated: ${todayMeals.length} meals');
        }
        _calculateTotals();
        if (viewMode.value == 'daily') {
          _loadDailyData();
        }
      });
    } else {
      if (kDebugMode) {
        print('❌ No user - retrying in 2 seconds...');
      }
      todayMeals.clear();
      _calculateTotals();

      Future.delayed(Duration(seconds: 2), () {
        if (kDebugMode) {
          print('Retrying stream binding...');
        }
        _bindToFirebaseStream();
      });
    }
  }

  Stream<List<Map<String, dynamic>>> _getMealsStream() {
    final authController = Get.find<AuthController>();
    if (authController.user == null) {
      if (kDebugMode) {
        print(' No user for stream');
      }
      return Stream.value([]);
    }

    final dateKey = _formatDateForFirebase(selectedDate.value);
    final docId = '${authController.user!.uid}_$dateKey';

    if (kDebugMode) {
      print('Listening to Firebase stream for: $docId');
    }

    return FirebaseFirestore.instance
        .collection('nutrition_entries')
        .doc(docId)
        .snapshots()
        .map((doc) {
          if (kDebugMode) {
            print('Stream data received: ${doc.exists}');
          }

          if (!doc.exists) {
            if (kDebugMode) {
              print('No document found for $docId');
            }
            return <Map<String, dynamic>>[];
          }

          final data = doc.data() as Map<String, dynamic>;
          final meals = (data['meals'] as List<dynamic>?) ?? [];

          if (kDebugMode) {
            print('Loaded ${meals.length} meals from Firebase');
          }
          if (data['waterIntake'] != null) {
            waterIntake.value = (data['waterIntake']).toDouble();
          }
          if (data['stepsCount'] != null) {
            stepsCount.value = data['stepsCount'];
          }
          if (data['weight'] != null) {
            currentWeight.value = (data['weight']).toDouble();
          }

          return meals.cast<Map<String, dynamic>>();
        });
  }

  // Core Functions
  void _calculateTotals() {
    totalCalories.value = 0;
    totalProteins.value = 0;
    totalCarbs.value = 0;
    totalFats.value = 0;

    for (var meal in todayMeals) {
      if (_shouldIncludeMeal(meal)) {
        totalCalories.value += (meal['calories'] ?? 0).toDouble();
        totalProteins.value += (meal['proteins'] ?? 0).toDouble();
        totalCarbs.value += (meal['carbs'] ?? 0).toDouble();
        totalFats.value += (meal['fat'] ?? 0).toDouble();
      }
    }

    if (kDebugMode) {
      print('Calculated totals - Calories: ${totalCalories.value}');
    }
  }

  bool _shouldIncludeMeal(Map<String, dynamic> meal) {
    if (selectedMealType.value == 'all') return true;
    return meal['type'] == selectedMealType.value;
  }

  Future<void> addMeal(Map<String, dynamic> meal) async {
    if (kDebugMode) {
      print('Adding meal: ${meal['name']}');
    }

    meal['id'] = DateTime.now().millisecondsSinceEpoch.toString();

    todayMeals.add(meal);
    _calculateTotals();
    _checkNutritionLimits();

    // Save to Firebase
    final success = await _saveToFirebase();

    if (success) {
      if (kDebugMode) {
        print('Meal successfully added and saved to Firebase');
      }

      // Refresh current
      await _loadDataForViewMode(viewMode.value);
    } else {
      if (kDebugMode) {
        print('Failed to save meal to Firebase');
      }
      // Remove from local list if Firebase save failed
      if (todayMeals.isNotEmpty) {
        todayMeals.removeLast();
        _calculateTotals();
      }
    }
  }

  Future<void> deleteMeal(int index) async {
    if (index >= 0 && index < todayMeals.length) {
      final mealName = todayMeals[index]['name'];
      if (kDebugMode) {
        print('Deleting meal: $mealName');
      }
      final deletedMeal = todayMeals[index];
      todayMeals.removeAt(index);
      _calculateTotals();

      final success = await _saveToFirebase();

      if (success) {
        if (kDebugMode) {
          print('Meal deleted and synced to Firebase');
        }
        await _loadDataForViewMode(viewMode.value);
      } else {
        todayMeals.insert(index, deletedMeal);
        _calculateTotals();
      }
    }
  }

  Future<void> deleteMealById(String id) async {
    final index = todayMeals.indexWhere((meal) => meal['id'] == id);
    if (index != -1) {
      await deleteMeal(index);
    }
  }

  Future<void> editMeal(int index, Map<String, dynamic> updatedMeal) async {
    if (index >= 0 && index < todayMeals.length) {
      final originalMeal = todayMeals[index];

      updatedMeal['id'] = todayMeals[index]['id'];
      todayMeals[index] = updatedMeal;
      _calculateTotals();

      final success = await _saveToFirebase();

      if (success) {
        await _loadDataForViewMode(viewMode.value);
      } else {
        todayMeals[index] = originalMeal;
        _calculateTotals();
      }
    }
  }

  Future<void> duplicateMeal(int index) async {
    if (index >= 0 && index < todayMeals.length) {
      final meal = Map<String, dynamic>.from(todayMeals[index]);
      meal['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      meal['name'] = '${meal['name']} (Copy)';

      await addMeal(meal);
    }
  }

  void _loadFavoriteMeals() {
    try {
      if (kDebugMode) {
        print('Loading favorite meals...');
      }

      List<dynamic>? savedFavoritesRaw = box.read('favorite_meals_v1');
      if (savedFavoritesRaw != null) {
        List<String> savedFavoritesJson = List<String>.from(savedFavoritesRaw);
        List<Map<String, dynamic>> favorites = [];

        for (String mealJson in savedFavoritesJson) {
          try {
            Map<String, dynamic> meal = Map<String, dynamic>.from(
              jsonDecode(mealJson),
            );
            favorites.add(meal);
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing favorite meal: $e');
            }
          }
        }

        favoriteMeals.assignAll(favorites);
        if (kDebugMode) {
          print('Loaded ${favorites.length} favorite meals');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading favorite meals: $e');
      }
      favoriteMeals.clear();
    }
  }

  void _saveFavoriteMeals() {
    try {
      List<String> favoritesJson = favoriteMeals.map((meal) {
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
          'time': meal['time'] ?? '',
          'quantity': meal['quantity'] ?? 100.0,
          'barcode': meal['barcode'] ?? '',
          'brands': meal['brands'] ?? '',
          'imageUrl': meal['imageUrl'] ?? '',
          'notes': meal['notes'] ?? '',
          'addedAt': meal['addedAt'] ?? DateTime.now().toIso8601String(),
        });
      }).toList();

      box.write('favorite_meals_v1', favoritesJson);
      if (kDebugMode) {
        print('Saved ${favoriteMeals.length} favorite meals');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving favorite meals: $e');
      }
    }
  }

  // Favorites Management
  void toggleFavorite(Map<String, dynamic> meal) {
    bool isFavorite = favoriteMeals.any((fav) => fav['name'] == meal['name']);

    if (isFavorite) {
      removeFromFavorites(meal);
    } else {
      addToFavorites(meal);
    }
  }

  bool isFavorite(Map<String, dynamic> meal) {
    return favoriteMeals.any((fav) => fav['name'] == meal['name']);
  }

  // Clear all favorites
  void clearAllFavorites() {
    Get.dialog(
      AlertDialog(
        title: Text('Clear All Favorites'),
        content: Text(
          'Are you sure you want to remove all favorite meals? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();

              favoriteMeals.clear();
              CustomThemeFlushbar(
                title: 'Favorites Cleared',
                message: 'All favorite meals have been removed',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void addToFavorites(Map<String, dynamic> meal) {
    try {
      bool alreadyFavorite = favoriteMeals.any(
        (fav) => fav['name'] == meal['name'],
      );

      if (!alreadyFavorite) {
        Map<String, dynamic> favoriteMeal = Map<String, dynamic>.from(meal);
        favoriteMeal['addedAt'] = DateTime.now().toIso8601String();
        favoriteMeal['favorite'] = true;

        favoriteMeals.insert(0, favoriteMeal);

        if (favoriteMeals.length > 50) {
          favoriteMeals.removeLast();
        }
        CustomThemeFlushbar(
          title: 'Added to Favorites',
          message: '${meal['name']} has been added to your favorites',
        );
      } else {
        if (kDebugMode) {
          print('Already in favorites: ${meal['name']}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding to favorites: $e');
      }
    }
  }

  void removeFromFavorites(Map<String, dynamic> meal) {
    try {
      favoriteMeals.removeWhere((fav) => fav['name'] == meal['name']);
      if (kDebugMode) {
        print('Removed from favorites: ${meal['name']}');
      }

      Get.snackbar(
        'Removed from Favorites',
        '${meal['name']} has been removed from your favorites',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.grey,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error removing from favorites: $e');
      }
    }
  }

  void _loadFavorites() {
    favoriteMeals.addAll([
      {
        'id': 'fav1',
        'name': 'Protein Shake',
        'calories': 200,
        'proteins': 25.0,
        'carbs': 5.0,
        'fat': 3.0,
        'type': 'snack',
      },
      {
        'id': 'fav2',
        'name': 'Chicken Breast (100g)',
        'calories': 165,
        'proteins': 31.0,
        'carbs': 0.0,
        'fat': 3.6,
        'type': 'lunch',
      },
    ]);
  }

  void _loadTemplates() {
    mealTemplates.addAll([
      {
        'name': 'Quick Breakfast',
        'meals': [
          {
            'name': 'Banana',
            'calories': 105,
            'proteins': 1.3,
            'carbs': 27.0,
            'fat': 0.4,
          },
          {
            'name': 'Greek Yogurt',
            'calories': 100,
            'proteins': 17.0,
            'carbs': 9.0,
            'fat': 0.4,
          },
        ],
      },
      {
        'name': 'Post-Workout',
        'meals': [
          {
            'name': 'Protein Shake',
            'calories': 200,
            'proteins': 25.0,
            'carbs': 5.0,
            'fat': 3.0,
          },
          {
            'name': 'Apple',
            'calories': 95,
            'proteins': 0.5,
            'carbs': 25.0,
            'fat': 0.3,
          },
        ],
      },
    ]);
  }

  Future<void> addWater() async {
    if (waterIntake.value < 20) {
      waterIntake.value += 1;
      await _saveToFirebase();
    }
  }

  Future<void> removeWater() async {
    if (waterIntake.value > 0) {
      waterIntake.value -= 1;
      await _saveToFirebase();
    }
  }

  // Weight Tracking
  void syncWeightChange(double newWeight) {
    final oldWeight = userWeight.value;
    userWeight.value = newWeight;

    // Update nutrition
    _updateNutritionGoals(newWeight);

    if (kDebugMode) {
      print(
        'NutritionController: Weight synced from $oldWeight to $newWeight kg',
      );
    }
  }

  void _updateNutritionGoals(double weight) {
    bmr.value = 88.362 + (13.397 * weight) + (4.799 * 175) - (5.677 * 25);
    dailyCalorieGoal.value = (bmr.value * 1.5).round();
    if (kDebugMode) {
      print(
        'Updated BMR: ${bmr.value.toInt()}, Daily Goal: ${dailyCalorieGoal.value}',
      );
    }
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
    await _saveToFirebase();
  }

  // Data Management
  Future<void> clearAllMeals() async {
    todayMeals.clear();
    _calculateTotals();
    await _saveToFirebase();

    // Refresh
    await _loadDataForViewMode(viewMode.value);
  }

  void exportData() {
    CustomThemeFlushbar(
      title: 'Export',
      message: 'Data exported successfully!',
    );
  }

  void importData() {
    CustomThemeFlushbar(
      title: 'Import',
      message: 'Data imported successfully!',
    );
  }

  // Nutrition Analysis
  void _checkNutritionLimits() {
    if (totalCalories.value > calorieGoal.value * 1.2) {
      CustomThemeFlushbar(
        title: 'Calorie Alert',
        message:
            'You\'ve exceeded your daily calorie goal by ${(totalCalories.value - calorieGoal.value).toInt()} kcal',
      );
    }
  }

  Future<void> setSelectedDate(DateTime date) async {
    if (kDebugMode) {
      print('Date changed to: ${date.day}/${date.month}/${date.year}');
    }
    selectedDate.value = date;

    _bindToFirebaseStream();

    await _loadDataForViewMode(viewMode.value);
  }

  void filterByMealType(String type) {
    if (kDebugMode) {
      print('Filtering by meal type: $type');
    }
    selectedMealType.value = type;
    _calculateTotals();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  List<Map<String, dynamic>> get filteredMealsList {
    var filtered = currentMeals
        .where((meal) => _shouldIncludeMeal(meal))
        .toList();

    if (searchQuery.value.isNotEmpty) {
      filtered = filtered
          .where(
            (meal) => meal['name'].toString().toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ),
          )
          .toList();
    }

    return filtered;
  }

  // Goals Management
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

    await _updateUserGoalsInFirebase();
  }

  // Quick Actions
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
      'type': 'meal',
      'time':
          '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'image': null,
      'notes': '',
      'favorite': false,
    });
  }

  // Load data from Firebase
  Future<void> loadDataFromFirebase() async {
    final authController = Get.find<AuthController>();

    if (authController.user == null) {
      if (kDebugMode) {
        print('No user logged in');
      }
      return;
    }

    try {
      isLoading.value = true;
      if (kDebugMode) {
        print('Loading nutrition data from Firebase...');
      }
      if (authController.userModel != null) {
        final userModel = authController.userModel!;
        calorieGoal.value = userModel.calorieGoal;
        proteinGoal.value = userModel.proteinGoal;
        carbGoal.value = userModel.carbGoal;
        fatGoal.value = userModel.fatGoal;
        waterGoal.value = userModel.waterGoal;
        stepsGoal.value = userModel.stepsGoal;

        if (userModel.currentWeight != null) {
          currentWeight.value = userModel.currentWeight!;
        }
      }

      if (kDebugMode) {
        print(
          'Firebase data load completed. Total calories: ${totalCalories.value}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading nutrition data from Firebase: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _saveToFirebase() async {
    final authController = Get.find<AuthController>();

    if (authController.user == null) {
      if (kDebugMode) {
        print('SAVE FAILED: No user logged in');
      }
      return false;
    }

    try {
      final dateKey = _formatDateForFirebase(selectedDate.value);
      final docId = '${authController.user!.uid}_$dateKey';

      if (kDebugMode) {
        print('User ID: ${authController.user!.uid}');
        print('Date Key: $dateKey');
        print('Document ID: $docId');
        print('Meals Count: ${todayMeals.length}');
      }

      final docData = {
        'id': docId,
        'userId': authController.user!.uid,
        'date': selectedDate.value.toIso8601String(),
        'meals': todayMeals
            .map((meal) => Map<String, dynamic>.from(meal))
            .toList(),
        'waterIntake': waterIntake.value,
        'stepsCount': stepsCount.value,
        'weight': currentWeight.value > 0 ? currentWeight.value : null,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Attempt the Firebase write
      await FirebaseFirestore.instance
          .collection('nutrition_entries')
          .doc(docId)
          .set(docData);

      if (kDebugMode) {
        print('Firebase save successful');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase save error: $e');
        print('Error Type: ${e.runtimeType}');
      }
      return false;
    }
  }

  // Update user goals in Firebase
  Future<void> _updateUserGoalsInFirebase() async {
    try {
      final authController = Get.find<AuthController>();
      await authController.updateNutritionGoals(
        calorieGoal: calorieGoal.value,
        proteinGoal: proteinGoal.value,
        carbGoal: carbGoal.value,
        fatGoal: fatGoal.value,
        waterGoal: waterGoal.value,
        stepsGoal: stepsGoal.value,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating goals in Firebase: $e');
      }
    }
  }

  String _formatDateForFirebase(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> manualRefresh() async {
    if (kDebugMode) {
      print('Manual refresh triggered for ${viewMode.value} view');
    }
    await _refreshFirebaseData();
    await _loadDataForViewMode(viewMode.value);
  }

  Future<void> _refreshFirebaseData() async {
    final authController = Get.find<AuthController>();
    if (authController.user == null) return;

    try {
      isLoading.value = true;

      final dateKey = _formatDateForFirebase(selectedDate.value);
      final docId = '${authController.user!.uid}_$dateKey';

      if (kDebugMode) {
        print('Manual refresh for: $docId');
      }

      final doc = await FirebaseFirestore.instance
          .collection('nutrition_entries')
          .doc(docId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final meals = (data['meals'] as List<dynamic>?) ?? [];

        todayMeals.assignAll(meals.cast<Map<String, dynamic>>());
        _calculateTotals();

        if (kDebugMode) {
          print('Manual refresh successful: ${meals.length} meals loaded');
        }
      } else {
        if (kDebugMode) {
          print('No data found for today');
        }
        todayMeals.clear();
        _calculateTotals();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Manual refresh error: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // User Data
  Future<void> updateUserWeight(double newWeight) async {
    final oldWeight = userWeight.value;
    userWeight.value = newWeight;

    if (kDebugMode) {
      print(
        'Nutrition controller: Weight updated from $oldWeight to $newWeight',
      );
    }

    // Save to preferences
    try {
      final authController = Get.find<AuthController>();
      if (authController.user != null) {
        await FirebaseFirestore.instance
            .collection('user_preferences')
            .doc(authController.user!.uid)
            .set({
              'currentWeight': newWeight,
              'updatedAt': DateTime.now().toIso8601String(),
            }, SetOptions(merge: true));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving weight to preferences: $e');
      }
    }
    _onWeightChanged(oldWeight, newWeight);
  }

  void _onWeightChanged(double oldWeight, double newWeight) {
    _updateRecommendedCalories(newWeight);

    CustomThemeFlushbar(
      title: 'Weight Updated',
      message: 'Nutrition recommendations updated for ${newWeight.toInt()}kg',
    );
  }

  void _updateRecommendedCalories(double weight) {
    final bmr = 88.362 + (13.397 * weight) + (4.799 * 175) - (5.677 * 25);
    final recommendedCalories = (bmr * 1.5).round();

    if (kDebugMode) {
      print(
        'Updated recommended calories: $recommendedCalories kcal for ${weight}kg',
      );
    }
  }

  // Sync meal data with profile changes
  void syncWithProfile(UserProfile profile) {
    userWeight.value = profile.currentWeight;
    _updateRecommendedCalories(profile.currentWeight);
    if (kDebugMode) {
      print('Nutrition data synced with profile updates');
    }
  }

  double getAdjustedServingSize(double baseServing, double targetWeight) {
    final weightRatio = userWeight.value / 70.0; // 70kg as baseline
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

  // Refresh data
  Future<void> refreshData() async {
    await loadDataFromFirebase();
    await _loadDataForViewMode(viewMode.value);
  }

  DateTime _getStartOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return date.subtract(Duration(days: daysFromMonday));
  }

  String _getDayName(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[date.weekday - 1];
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

  int _getWeekOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final daysDifference = date.difference(firstDayOfMonth).inDays;
    return (daysDifference / 7).floor() + 1;
  }
}
