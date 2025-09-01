import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';

import '../controllers/auth_controller.dart';
import '../controllers/nutrition_controller.dart';

class ProfileController extends GetxController {
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

  var lastLoginDate = DateTime.now().obs;
  var profileCompleteness = 0.0.obs;
  var totalDataPoints = 0.obs;
  var averageCaloriesPerDay = 0.0.obs;
  var averageMealsPerDay = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  @override
  void onClose() {
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
    } catch (e) {
      _showErrorSnackbar('Failed to initialize profile');
    }
  }

  void _setupNutritionListeners() {
    try {
      final nutritionController = Get.find<NutritionController>();

      ever(nutritionController.todayMeals, (_) => _calculateStats());
      ever(nutritionController.totalCalories, (_) => _calculateStats());
      ever(nutritionController.viewMode, (_) => _calculateStats());

      _calculateStats();
    } catch (e) {
      Future.delayed(Duration(seconds: 2), () {
        try {
          final nutritionController = Get.find<NutritionController>();
          ever(nutritionController.todayMeals, (_) => _calculateStats());
          ever(nutritionController.totalCalories, (_) => _calculateStats());
          ever(nutritionController.viewMode, (_) => _calculateStats());
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
      // ignore: unused_local_variable
      final nutritionController = Get.find<NutritionController>();
      final authController = Get.find<AuthController>();

      if (authController.user == null) {
        streakDays.value = 0;
        return;
      }

      int streak = 0;
      DateTime currentDate = DateTime.now();

      for (int i = 0; i < 30; i++) {
        final checkDate = currentDate.subtract(Duration(days: i));
        final dateKey = _formatDateForFirebase(checkDate);
        final docId = '${authController.user!.uid}_$dateKey';

        try {
          final doc = await FirebaseFirestore.instance
              .collection('nutrition_entries')
              .doc(docId)
              .get();

          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            final meals = (data['meals'] as List<dynamic>?) ?? [];

            if (meals.isNotEmpty) {
              streak++;
            } else {
              break;
            }
          } else {
            break;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error checking streak for $dateKey: $e');
          }
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
          averageCaloriesPerDay.value = weeklyStats['averageCalories'] ?? 0.0;
          averageMealsPerDay.value = daysWithData > 0
              ? (weeklyStats['totalMeals'] ?? 0) / daysWithData.toDouble()
              : 0.0;
          totalDaysTracked.value = daysWithData;
          break;

        case 'monthly':
          final monthlyStats = nutritionController.monthlyStats;
          final daysWithData = monthlyStats['daysWithData'] ?? 1;
          averageCaloriesPerDay.value = monthlyStats['averageCalories'] ?? 0.0;
          averageMealsPerDay.value = daysWithData > 0
              ? (monthlyStats['totalMeals'] ?? 0) / daysWithData.toDouble()
              : 0.0;
          totalDaysTracked.value = daysWithData;
          break;

        default:
          averageCaloriesPerDay.value = nutritionController.totalCalories.value;
          averageMealsPerDay.value = nutritionController.todayMeals.length
              .toDouble();
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
      await _loadFirestoreProfile(user.uid);

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

  Future<void> _loadFirestoreProfile(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        await _safeExtractFirestoreData(data);
      } else {
        if (kDebugMode) {
          print('No Firestore profile found, using defaults');
        }
        await _createDefaultProfile(uid);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firestore profile load error: $e');
      }
    }
  }

  Future<void> _safeExtractFirestoreData(Map<String, dynamic> data) async {
    try {
      if (data['bio'] is String) userBio.value = data['bio'];
      if (data['gender'] is String) gender.value = data['gender'];
      if (data['unitSystem'] is String) unitSystem.value = data['unitSystem'];

      if (data['currentWeight'] is num) {
        final weight = (data['currentWeight'] as num).toDouble();
        if (weight > 0 && weight < 1000) {
          currentWeight.value = weight;
          await storage.write('user_weight', weight);
        }
      }

      if (data['targetWeight'] is num) {
        final target = (data['targetWeight'] as num).toDouble();
        if (target > 0 && target < 1000) {
          targetWeight.value = target;
        }
      }

      if (data['height'] is num) {
        final h = (data['height'] as num).toDouble();
        if (h > 0 && h < 300) {
          height.value = h;
        }
      }

      if (data['age'] is num) {
        final ageValue = (data['age'] as num).toInt();
        if (ageValue > 0 && ageValue < 150) {
          age.value = ageValue;
        }
      }

      notificationsEnabled.value = data['notificationsEnabled'] == true;
      darkModeEnabled.value = data['darkModeEnabled'] == true;
      weeklyReportsEnabled.value = data['weeklyReportsEnabled'] == true;
      dataBackupEnabled.value = data['dataBackupEnabled'] == true;
      reminderEnabled.value = data['reminderEnabled'] == true;

      if (data['joinDate'] is String) {
        try {
          joinDate.value = DateTime.parse(data['joinDate']);
        } catch (dateError) {
          if (kDebugMode) {
            print('Invalid date format: ${data['joinDate']}');
          }
        }
      }

      if (kDebugMode) {
        print('Firestore data extracted safely');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting Firestore data: $e');
      }
    }
  }

  Future<void> _createDefaultProfile(String uid) async {
    try {
      final defaultProfile = {
        'displayName': userName.value,
        'email': userEmail.value,
        'bio': '',
        'currentWeight': 70.0,
        'targetWeight': 65.0,
        'height': 175.0,
        'age': 25,
        'gender': 'Male',
        'unitSystem': 'Metric',
        'notificationsEnabled': true,
        'darkModeEnabled': false,
        'weeklyReportsEnabled': true,
        'dataBackupEnabled': true,
        'reminderEnabled': true,
        'joinDate': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(defaultProfile);

      if (kDebugMode) {
        print('Default profile created');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating default profile: $e');
      }
    }
  }

  void _setupReactiveListeners() {
    ever(currentWeight, (double weight) async {
      await _saveWeightPersistently(weight);
      await _updateWeightHistory(weight);
    });

    ever(notificationsEnabled, (bool enabled) => _saveSettingsLocally());
    ever(darkModeEnabled, (bool enabled) => _saveSettingsLocally());
    ever(weeklyReportsEnabled, (bool enabled) => _saveSettingsLocally());
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

      await _saveWeightToFirebase(weight);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving weight persistently: $e');
      }
    }
  }

  Future<void> _saveWeightToFirebase(
    double weight, [
    int retryCount = 0,
  ]) async {
    try {
      final authController = Get.find<AuthController>();
      if (authController.user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(authController.user!.uid)
          .set({
            'currentWeight': weight,
            'lastWeightUpdate': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));

      if (kDebugMode) {
        print('Weight synced to Firebase: ${weight}kg');
      }
    } catch (e) {
      if (retryCount < 3) {
        if (kDebugMode) {
          print('Retrying Firebase weight save... (${retryCount + 1}/3)');
        }
        await Future.delayed(Duration(seconds: 2));
        await _saveWeightToFirebase(weight, retryCount + 1);
      } else {
        if (kDebugMode) {
          print('Failed to save weight to Firebase : $e');
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
      if (authController.user == null) return;

      await _loadNutritionStats(authController.user!.uid);
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
      final querySnapshot = await FirebaseFirestore.instance
          .collection('nutrition_entries')
          .where('userId', isEqualTo: uid)
          .orderBy('date', descending: true)
          .limit(30)
          .get();

      int totalMeals = 0;
      double totalCals = 0.0;
      Set<String> loggedDates = {};
      List<double> dailyCalories = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final meals = data['meals'] as List<dynamic>? ?? [];

        double dayCalories = 0.0;
        for (var meal in meals) {
          if (meal is Map<String, dynamic>) {
            final calories = meal['calories'];
            if (calories is num) {
              dayCalories += calories.toDouble();
            }
          }
        }

        totalMeals += meals.length;
        totalCals += dayCalories;
        dailyCalories.add(dayCalories);

        if (data['date'] != null) {
          loggedDates.add(data['date'].toString().substring(0, 10));
        }
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
    int total = 10;

    if (userName.value.isNotEmpty && userName.value != 'Anonymous User') {
      completed++;
    }
    if (userEmail.value.isNotEmpty) completed++;
    if (userBio.value.isNotEmpty) completed++;
    if (profileImageUrl.value.isNotEmpty) completed++;
    if (currentWeight.value != 70.0) completed++;
    if (targetWeight.value != 65.0) completed++;
    if (height.value != 175.0) completed++;
    if (age.value != 25) completed++;
    if (gender.value.isNotEmpty) completed++;
    if (totalMealsLogged.value > 0) completed++;

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

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'profileImageUrl': downloadUrl,
          'lastImageUpdate': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        profileImageUrl.value = downloadUrl;
        _calculateProfileCompleteness();
        CustomThemeFlushbar(
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

      final updates = _prepareFirestoreUpdates(
        name,
        bio,
        currentWeight,
        targetWeight,
        userHeight,
        userAge,
        userGender,
      );

      if (updates.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(updates, SetOptions(merge: true));
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

      CustomThemeFlushbar(
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
    if (currentWeight != null && (currentWeight <= 0 || currentWeight > 1000)) {
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

  Map<String, dynamic> _prepareFirestoreUpdates(
    String? name,
    String? bio,
    double? currentWeight,
    double? targetWeight,
    double? userHeight,
    int? userAge,
    String? userGender,
  ) {
    final updates = <String, dynamic>{};

    if (name != null && name.trim().isNotEmpty) {
      updates['displayName'] = name.trim();
    }
    if (bio != null) updates['bio'] = bio.trim();
    if (currentWeight != null && currentWeight > 0) {
      updates['currentWeight'] = currentWeight;
    }
    if (targetWeight != null && targetWeight > 0) {
      updates['targetWeight'] = targetWeight;
    }
    if (userHeight != null && userHeight > 0) updates['height'] = userHeight;
    if (userAge != null && userAge > 0) updates['age'] = userAge;
    if (userGender != null && userGender.isNotEmpty) {
      updates['gender'] = userGender;
    }
    updates['updatedAt'] = DateTime.now().toIso8601String();
    return updates;
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
        CustomThemeFlushbar(
          title: 'Partial Sync',
          message: 'Weight saved locally, nutrition sync will retry later',
        );
      }

      if (kDebugMode) {
        print('Weight sync complete: $oldWeight → $newWeight kg');
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
      if (authController.user == null) {
        throw Exception('User not authenticated');
      }

      final user = authController.user!;
      final updates = <String, dynamic>{};

      if (notifications != null) {
        updates['notificationsEnabled'] = notifications;
        notificationsEnabled.value = notifications;
      }

      if (darkMode != null) {
        updates['darkModeEnabled'] = darkMode;
        darkModeEnabled.value = darkMode;
      }

      if (weeklyReports != null) {
        updates['weeklyReportsEnabled'] = weeklyReports;
        weeklyReportsEnabled.value = weeklyReports;
      }

      if (dataBackup != null) {
        updates['dataBackupEnabled'] = dataBackup;
        dataBackupEnabled.value = dataBackup;
      }

      if (reminder != null) {
        updates['reminderEnabled'] = reminder;
        reminderEnabled.value = reminder;
      }

      if (unitSystem != null) {
        updates['unitSystem'] = unitSystem;
        this.unitSystem.value = unitSystem;
      }

      if (updates.isNotEmpty) {
        updates['settingsUpdatedAt'] = DateTime.now().toIso8601String();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(updates, SetOptions(merge: true));
      }

      _saveSettingsLocally();

      CustomThemeFlushbar(
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

      CustomThemeFlushbar(
        title: 'Exporting...',
        message: 'Preparing your data for export',
      );

      final authController = Get.find<AuthController>();
      if (authController.user == null) {
        throw Exception('User not authenticated');
      }

      final exportData = await _collectExportData(authController.user!.uid);

      await storage.write(
        'exported_data_${DateTime.now().millisecondsSinceEpoch}',
        exportData,
      );

      CustomThemeFlushbar(
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

      await _deleteUserData(user.uid);

      await storage.erase();

      await user.delete();

      Get.offAllNamed('/login');

      CustomThemeFlushbar(
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
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete your account?'),
            SizedBox(height: 8),
            Text(
              'This will permanently delete:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• All your profile data'),
            Text('• All meal logs and nutrition data'),
            Text('• All scanned products'),
            Text('• All statistics and history'),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete Account'),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  Future<void> _deleteUserData(String uid) async {
    final batch = FirebaseFirestore.instance.batch();

    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    batch.delete(userDoc);

    final nutritionQuery = await FirebaseFirestore.instance
        .collection('nutrition_entries')
        .where('userId', isEqualTo: uid)
        .get();

    for (var doc in nutritionQuery.docs) {
      batch.delete(doc.reference);
    }

    final productsQuery = await FirebaseFirestore.instance
        .collection('scanned_products')
        .where('userId', isEqualTo: uid)
        .get();

    for (var doc in productsQuery.docs) {
      batch.delete(doc.reference);
    }

    final preferencesDoc = FirebaseFirestore.instance
        .collection('user_preferences')
        .doc(uid);
    batch.delete(preferencesDoc);

    await batch.commit();

    if (kDebugMode) {
      print('All user data deleted from Firestore');
    }
  }

  Future<void> signOut() async {
    try {
      _saveSettingsLocally();

      final authController = Get.find<AuthController>();
      await authController.signOut();

      final settings = storage.read('settings');
      await storage.erase();
      if (settings != null) {
        await storage.write('settings', settings);
      }

      Get.offAllNamed('/login');
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
    CustomThemeFlushbar(title: '❌ Error', message: message);
  }

  void _disposeControllers() {
    nameController.dispose();
    bioController.dispose();
    weightController.dispose();
    targetController.dispose();
    heightController.dispose();
    ageController.dispose();
  }

  String _formatDateForFirebase(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
