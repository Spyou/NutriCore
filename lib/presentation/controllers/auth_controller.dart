import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';
import 'package:nutri_check/presentation/pages/auth/login_page.dart';

import '../../data/models/user_model.dart';
import '../../domain/entities/user_profile.dart' show Gender;
import '../pages/main_page.dart';
import '../services/user_service.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = Get.find<UserService>();

  Worker? _authStateWorker;

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
    _authStateWorker = ever(_user, _setInitialScreen);
  }

  @override
  void onClose() {
    _authStateWorker?.dispose();
    super.onClose();
  }

  Future<void> _setInitialScreen(User? user) async {
    if (user == null) {
      if (kDebugMode) {
        print('User not logged in');
      }
      Get.offAll(() => const LoginPage());
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

      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
        await _createUserDocument(
          userCredential.user!,
          displayName: displayName,
        );

        CustomThemeFlushbar.show(
          title: 'Success',
          message: 'Account created successfully!',
        );
      }
    } on FirebaseAuthException catch (e) {
      error.value = _getErrorMessage(e);
      CustomThemeFlushbar.show(title: 'Error', message: error.value);
    } catch (e) {
      error.value = 'An unexpected error occurred';
      CustomThemeFlushbar.show(title: 'Error', message: error.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      isLoading.value = true;
      error.value = '';

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      CustomThemeFlushbar.show(
        title: 'Login Successful!',
        message: 'Welcome back! Redirecting to your nutrition tracker...',
      );

      HapticFeedback.lightImpact();
    } on FirebaseAuthException catch (e) {
      error.value = _getErrorMessage(e);
      CustomThemeFlushbar.show(title: 'Login Failed', message: error.value);
    } catch (e) {
      error.value = 'An unexpected error occurred';
      CustomThemeFlushbar.show(title: 'Error', message: error.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User aborted the dialog — silent return.
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      // Known incompatibility between some firebase_auth + google_sign_in
      // versions throws a PigeonUserDetails cast error even when the
      // sign-in succeeds. Catch it and verify via currentUser before
      // surfacing as a real failure.
      try {
        await FirebaseAuth.instance.signInWithCredential(credential);
      } catch (e) {
        if (kDebugMode) {
          print('signInWithCredential threw, will verify via currentUser: $e');
        }
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Google sign-in did not produce a Firebase user');
      }
      await _ensureUserDocument(
        user.uid,
        user.displayName ?? '',
        user.email ?? '',
        photoUrl: user.photoURL,
      );
      CustomThemeFlushbar.show(
        title: 'Welcome',
        message: 'Signed in as ${user.displayName ?? user.email ?? "you"}',
      );
    } catch (e) {
      CustomThemeFlushbar.show(
        title: 'Sign-in failed',
        message: 'Couldn\'t sign in with Google. Try again.',
      );
      if (kDebugMode) print('Google sign-in error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _ensureUserDocument(
    String uid,
    String name,
    String email, {
    String? photoUrl,
  }) async {
    final existing = await _userService.getUserData(uid);
    if (existing == null) {
      final userModel = UserModel(
        uid: uid,
        email: email,
        displayName: name.isEmpty ? null : name,
        photoURL: photoUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _userService.createUserData(userModel);
      _userModel.value = userModel;
    } else {
      final needsName =
          (existing.displayName == null || existing.displayName!.isEmpty) &&
              name.isNotEmpty;
      final needsPhoto = (existing.photoURL == null ||
              existing.photoURL!.isEmpty) &&
          photoUrl != null &&
          photoUrl.isNotEmpty;
      if (needsName || needsPhoto) {
        final updated = existing.copyWith(
          displayName: needsName ? name : null,
          photoURL: needsPhoto ? photoUrl : null,
        );
        await _userService.updateUserData(updated);
        _userModel.value = updated;
      } else {
        _userModel.value = existing;
      }
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _userModel.value = null;
      CustomThemeFlushbar.show(
        title: 'Success',
        message: 'Logged out successfully!',
      );
    } catch (e) {
      CustomThemeFlushbar.show(
        title: 'Error',
        message: 'Error signing out: ${e.toString()}',
      );
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      isLoading.value = true;
      await _auth.sendPasswordResetEmail(email: email);
      CustomThemeFlushbar.show(
        title: 'Success',
        message: 'Password reset email sent! Check your inbox.',
      );
    } on FirebaseAuthException catch (e) {
      CustomThemeFlushbar.show(title: 'Error', message: _getErrorMessage(e));
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
          gender: gender != null
              ? Gender.values.firstWhere(
                  (e) => e.name.toLowerCase() == gender.toLowerCase(),
                  orElse: () => Gender.male,
                )
              : null,
          activityLevel: activityLevel,
        );

        await _userService.updateUserData(updatedUser);
        _userModel.value = updatedUser;

        CustomThemeFlushbar.show(
          title: 'Success',
          message: 'Profile updated successfully!',
        );
      }
    } catch (e) {
      CustomThemeFlushbar.show(
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

        CustomThemeFlushbar.show(
          title: 'Success',
          message: 'Nutrition goals updated!',
        );
      }
    } catch (e) {
      CustomThemeFlushbar.show(
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
