import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';
import 'package:nutri_check/presentation/pages/auth/login_page.dart';

import '../../data/models/user_model.dart';
import '../pages/main_page.dart';
import '../services/user_service.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  final Rx<User?> _user = Rx<User?>(null);
  final Rx<UserModel?> _userModel = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  User? get user => _user.value;
  UserModel? get userModel => _userModel.value;
  bool get isLoggedIn => _user.value != null;

  @override
  void onInit() {
    super.onInit();

    _user.bindStream(_auth.authStateChanges());
    ever(_user, _setInitialScreen);
  }

  _setInitialScreen(User? user) async {
    if (user == null) {
      if (kDebugMode) {
        print('User not logged in');
      }
      Get.offAll(() => LoginPage());
    } else {
      if (kDebugMode) {
        print('User logged in: ${user.email}');
      }
      await _loadUserData();
      if (kDebugMode) {
        print('User data loaded');
      }
      Get.offAll(() => MainPage());
    }
  }

  Future<void> _loadUserData() async {
    if (_user.value != null) {
      try {
        final userData = await _userService.getUserData(_user.value!.uid);
        if (userData != null) {
          _userModel.value = userData;
        } else {
          await _createUserDocument(_user.value!);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error loading user data: $e');
        }
      }
    }
  }

  Future<void> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      isLoading.value = true;
      error.value = '';

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
        await _createUserDocument(
          userCredential.user!,
          displayName: displayName,
        );

        CustomThemeFlushbar(
          title: 'Success',
          message: 'Account created successfully!',
        );
      }
    } on FirebaseAuthException catch (e) {
      error.value = _getErrorMessage(e);
      CustomThemeFlushbar(title: 'Error', message: error.value);
    } catch (e) {
      error.value = 'An unexpected error occurred';
      CustomThemeFlushbar(title: 'Error', message: error.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      isLoading.value = true;
      error.value = '';

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      CustomThemeFlushbar(
        title: 'Login Successful!',
        message: 'Welcome back! Redirecting to your nutrition tracker...',
      );

      HapticFeedback.lightImpact();
    } on FirebaseAuthException catch (e) {
      error.value = _getErrorMessage(e);
      CustomThemeFlushbar(title: 'Login Failed', message: error.value);
    } catch (e) {
      error.value = 'An unexpected error occurred';
      CustomThemeFlushbar(title: 'Error', message: error.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _userModel.value = null;
      CustomThemeFlushbar(
        title: 'Success',
        message: 'Logged out successfully!',
      );
    } catch (e) {
      CustomThemeFlushbar(
        title: 'Error',
        message: 'Error signing out: ${e.toString()}',
      );
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      isLoading.value = true;
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar(
        'Success',
        'Password reset email sent! Check your inbox.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } on FirebaseAuthException catch (e) {
      CustomThemeFlushbar(title: 'Error', message: _getErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
    double? currentWeight,
    double? targetWeight,
    double? height,
    int? age,
    String? gender,
    String? activityLevel,
  }) async {
    try {
      if (_user.value != null && _userModel.value != null) {
        if (displayName != null) {
          await _user.value!.updateDisplayName(displayName);
        }
        if (photoURL != null) {
          await _user.value!.updatePhotoURL(photoURL);
        }

        final updatedUser = _userModel.value!.copyWith(
          displayName: displayName,
          photoURL: photoURL,
          currentWeight: currentWeight,
          targetWeight: targetWeight,
          height: height,
          age: age,
          gender: gender,
          activityLevel: activityLevel,
        );

        await _userService.updateUserData(updatedUser);
        _userModel.value = updatedUser;

        CustomThemeFlushbar(
          title: 'Success',
          message: 'Profile updated successfully!',
        );
      }
    } catch (e) {
      CustomThemeFlushbar(
        title: 'Error',
        message: 'Error updating profile: ${e.toString()}',
      );
    }
  }

  Future<void> updateNutritionGoals({
    double? calorieGoal,
    double? proteinGoal,
    double? carbGoal,
    double? fatGoal,
    double? waterGoal,
    int? stepsGoal,
  }) async {
    try {
      if (_userModel.value != null) {
        final updatedUser = _userModel.value!.copyWith(
          calorieGoal: calorieGoal,
          proteinGoal: proteinGoal,
          carbGoal: carbGoal,
          fatGoal: fatGoal,
          waterGoal: waterGoal,
          stepsGoal: stepsGoal,
        );

        await _userService.updateUserData(updatedUser);
        _userModel.value = updatedUser;

        CustomThemeFlushbar(
          title: 'Success',
          message: 'Nutrition goals updated!',
        );
      }
    } catch (e) {
      CustomThemeFlushbar(
        title: 'Error',
        message: 'Error updating goals: ${e.toString()}',
      );
    }
  }

  Future<void> _createUserDocument(User user, {String? displayName}) async {
    final userModel = UserModel(
      uid: user.uid,
      email: user.email!,
      displayName: displayName ?? user.displayName,
      photoURL: user.photoURL,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _userService.createUserData(userModel);
    _userModel.value = userModel;
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      default:
        return e.message ?? 'An error occurred';
    }
  }
}
