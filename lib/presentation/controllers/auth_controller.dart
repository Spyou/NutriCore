import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';
import 'package:nutri_check/presentation/pages/auth/login_page.dart';

import '../../data/models/user_model.dart';
import '../../domain/entities/user_profile.dart' show Gender;
import '../pages/auth/onboarding_page.dart';
import '../pages/main_page.dart';
import '../services/user_service.dart';
import 'profile_controller.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = Get.find<UserService>();
  final GetStorage _storage = GetStorage();

  // Local-session storage keys. These mirror the most recent
  // signed-in user so app restarts can route + render instantly,
  // before Firestore round-trips complete.
  static const String _kSessionUid = 'session.uid';
  static const String _kSessionDisplayName = 'session.displayName';
  static const String _kSessionEmail = 'session.email';
  static const String _kSessionPhotoURL = 'session.photoURL';
  static const String _kSessionOnboardingComplete = 'session.onboardingComplete';

  Worker? _authStateWorker;

  final Rx<User?> _user = Rx<User?>(null);
  final Rx<UserModel?> _userModel = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  User? get user => _user.value;
  UserModel? get userModel => _userModel.value;
  bool get isLoggedIn => _user.value != null;

  // Public Rx getters so other controllers (e.g. ProfileController) can
  // subscribe to user/model changes without reaching into private state.
  Rx<User?> get userRx => _user;
  Rx<UserModel?> get userModelRx => _userModel;

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

  /// Persists the in-memory _userModel (or the explicit overrides) into
  /// GetStorage under the `session.*` keys. Called whenever the model is
  /// authoritatively updated so app restarts can render + route instantly.
  void _saveSession({
    String? uid,
    String? displayName,
    String? email,
    String? photoURL,
    bool? onboardingComplete,
  }) {
    try {
      final model = _userModel.value;
      final resolvedUid = uid ?? model?.uid ?? _user.value?.uid;
      if (resolvedUid == null || resolvedUid.isEmpty) return;
      _storage.write(_kSessionUid, resolvedUid);
      _storage.write(
        _kSessionDisplayName,
        displayName ?? model?.displayName ?? _user.value?.displayName ?? '',
      );
      _storage.write(
        _kSessionEmail,
        email ?? model?.email ?? _user.value?.email ?? '',
      );
      _storage.write(
        _kSessionPhotoURL,
        photoURL ?? model?.photoURL ?? _user.value?.photoURL ?? '',
      );
      _storage.write(
        _kSessionOnboardingComplete,
        onboardingComplete ?? model?.onboardingComplete ?? false,
      );
    } catch (e) {
      if (kDebugMode) print('Error saving session: $e');
    }
  }

  Map<String, dynamic> _loadSession() {
    try {
      return {
        'uid': _storage.read(_kSessionUid),
        'displayName': _storage.read(_kSessionDisplayName),
        'email': _storage.read(_kSessionEmail),
        'photoURL': _storage.read(_kSessionPhotoURL),
        'onboardingComplete': _storage.read(_kSessionOnboardingComplete),
      };
    } catch (_) {
      return const {};
    }
  }

  void _clearSession() {
    try {
      _storage.remove(_kSessionUid);
      _storage.remove(_kSessionDisplayName);
      _storage.remove(_kSessionEmail);
      _storage.remove(_kSessionPhotoURL);
      _storage.remove(_kSessionOnboardingComplete);
    } catch (_) {}
  }

  Future<void> _setInitialScreen(User? user) async {
    if (user == null) {
      if (kDebugMode) {
        print('User not logged in');
      }
      _clearSession();
      _userModel.value = null;
      // Reset ProfileController so the previous user's data doesn't
      // bleed into the login screen / next account.
      try {
        Get.find<ProfileController>().resetUserState();
      } catch (_) {}
      Get.offAll(() => const LoginPage());
      return;
    }

    if (kDebugMode) {
      print('User logged in: ${user.email}');
    }

    // Hydrate _userModel optimistically from local session so the UI
    // can render the name immediately on restart. Firestore refresh
    // below will overwrite if the server has newer data.
    final session = _loadSession();
    bool? localOnboardingComplete;
    if (session['uid'] == user.uid) {
      localOnboardingComplete = session['onboardingComplete'] == true;
      _userModel.value = UserModel(
        uid: user.uid,
        email: (session['email'] as String?)?.isNotEmpty == true
            ? session['email'] as String
            : (user.email ?? ''),
        displayName: (session['displayName'] as String?)?.isNotEmpty == true
            ? session['displayName'] as String
            : user.displayName,
        photoURL: (session['photoURL'] as String?)?.isNotEmpty == true
            ? session['photoURL'] as String
            : user.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        onboardingComplete: localOnboardingComplete,
      );
    }

    // Refresh from Firestore — authoritative. Blocks routing so the
    // onboarding decision uses the latest persisted flag.
    await _loadUserData();
    _saveSession();

    if (kDebugMode) {
      print('User data loaded; '
          'onboardingComplete=${_userModel.value?.onboardingComplete}');
    }

    // Force ProfileController to re-read everything for THIS user — it
    // may have initialized before the auth session restored.
    try {
      await Get.find<ProfileController>().reloadUserProfile();
    } catch (_) {}

    final modelComplete = _userModel.value?.onboardingComplete;
    final needsOnboarding =
        (modelComplete ?? localOnboardingComplete ?? false) != true;
    if (needsOnboarding) {
      Get.offAll(() => const OnboardingPage());
    } else {
      Get.offAll(() => MainPage());
    }
  }

  Future<void> _loadUserData() async {
    if (_user.value != null) {
      try {
        final userData = await _userService.getUserData(_user.value!.uid);
        if (userData != null) {
          _userModel.value = userData;
          _saveSession();
        } else {
          // Doc missing. Auto-create ONLY when FirebaseAuth already
          // carries a usable displayName — otherwise we'd race a
          // freshly-running signup flow and overwrite it with a
          // nameless doc. Signup/Google flows call _createUserDocument /
          // _ensureUserDocument explicitly with the right name.
          final authName = _user.value!.displayName?.trim() ?? '';
          if (authName.isNotEmpty) {
            await _createUserDocument(
              _user.value!,
              displayName: authName,
            );
          }
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
        await userCredential.user!.reload();
        // Persist the user doc with onboardingComplete: false so the
        // auth-state listener routes to OnboardingPage on the next pass.
        await _createUserDocument(
          userCredential.user!,
          displayName: displayName,
        );

        // ProfileController is permanent; force it to re-read the now-
        // populated user doc so the name shows everywhere.
        try {
          await Get.find<ProfileController>().reloadUserProfile();
        } catch (_) {}

        // Re-trigger the listener after the doc exists so it picks up
        // the correct onboardingComplete value.
        await _setInitialScreen(_user.value);

        CustomThemeFlushbar.show(
          title: 'Welcome',
          message: 'Account created. Let\'s personalize your goals.',
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
      try {
        await Get.find<ProfileController>().reloadUserProfile();
      } catch (_) {}
      // Re-trigger the listener so it reads the now-current
      // onboardingComplete and routes accordingly.
      await _setInitialScreen(_user.value);
      final label = (user.displayName?.isNotEmpty == true)
          ? user.displayName
          : (user.email?.isNotEmpty == true ? user.email : null);
      CustomThemeFlushbar.show(
        title: 'Welcome',
        message: label != null ? 'Signed in as $label' : 'Signed in successfully',
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

  /// Ensures a Firestore user doc exists for [uid]. Returns `true` when a
  /// new doc was just created (caller should route to onboarding), or
  /// `false` when the doc already existed (returning user).
  Future<bool> _ensureUserDocument(
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
      _saveSession();
      return true;
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
      _saveSession();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _userModel.value = null;
      _clearSession();
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

  /// Sets `onboardingComplete: true` on the user doc and refreshes the
  /// local _userModel cache. Called once when the user finishes the
  /// onboarding flow. Resilient to a null in-memory model: when the
  /// model hasn't loaded yet but a FirebaseAuth user is present, we
  /// write the flag directly via a merge-set so it still persists.
  Future<void> markOnboardingComplete() async {
    final user = _user.value;
    if (user == null) return;
    final current = _userModel.value;
    try {
      if (current != null) {
        final updated = current.copyWith(onboardingComplete: true);
        await _userService.updateUserData(updated);
        _userModel.value = updated;
      } else {
        // Belt-and-suspenders: merge-set the flag straight onto the
        // doc so the source of truth is always written, even if the
        // local model hasn't loaded yet for any reason.
        await _userService.setOnboardingComplete(user.uid);
      }
    } catch (e) {
      if (kDebugMode) print('Error marking onboarding complete: $e');
    }
    // Persist the flag locally regardless — restart routing depends
    // on it and shouldn't be gated on a successful Firestore write.
    _saveSession(onboardingComplete: true);
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
        _saveSession();

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
    _saveSession();
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
