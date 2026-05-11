import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../widgets/auth/animated_auth_background.dart';
import '../../widgets/auth/animated_auth_field.dart';
import '../../widgets/auth/auth_enter.dart';
import '../../widgets/auth/auth_footer.dart';
import '../../widgets/auth/auth_google_button.dart';
import '../../widgets/auth/auth_or_divider.dart';
import '../../widgets/auth/auth_wordmark.dart';
import '../../widgets/auth/morphing_primary_button.dart';
import '../../widgets/auth/password_strength_indicator.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _nameFieldKey = GlobalKey<AnimatedAuthFieldState>();
  final _emailFieldKey = GlobalKey<AnimatedAuthFieldState>();
  final _passwordFieldKey = GlobalKey<AnimatedAuthFieldState>();
  final _confirmFieldKey = GlobalKey<AnimatedAuthFieldState>();

  final AuthController _authController = Get.find();

  String _password = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your name';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your email';
    if (!GetUtils.isEmail(v.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Please enter a password';
    if (v.length < 6) return 'Must be at least 6 characters';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != _passwordController.text) return "Passwords don't match";
    return null;
  }

  void _signUp() {
    final name = _nameFieldKey.currentState?.validateAndShake() ?? false;
    final email = _emailFieldKey.currentState?.validateAndShake() ?? false;
    final pw = _passwordFieldKey.currentState?.validateAndShake() ?? false;
    final confirm = _confirmFieldKey.currentState?.validateAndShake() ?? false;
    if (!name || !email || !pw || !confirm) {
      HapticFeedback.lightImpact();
      return;
    }
    _authController.signUpWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
    );
  }

  void _onGooglePressed() {
    HapticFeedback.selectionClick();
    _authController.signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: AnimatedAuthBackground(
          child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: AuthEnter(child: AuthWordmark()),
                ),
                const SizedBox(height: 48),
                AuthEnter(
                  delay: const Duration(milliseconds: 80),
                  child: Text(
                    'Create\naccount.',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      letterSpacing: -1.6,
                      color: scheme.onSurface,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AuthEnter(
                  delay: const Duration(milliseconds: 140),
                  child: Text(
                    'Takes less than a minute to get started.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                AuthEnter(
                  delay: const Duration(milliseconds: 200),
                  child: AnimatedAuthField(
                    key: _nameFieldKey,
                    controller: _nameController,
                    hint: 'Full name',
                    leadingIcon: Icons.person_outline_rounded,
                    autofillHint: AutofillHints.name,
                    validator: _validateName,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _emailFieldKey.currentState?.focus(),
                  ),
                ),
                const SizedBox(height: 14),
                AuthEnter(
                  delay: const Duration(milliseconds: 240),
                  child: AnimatedAuthField(
                    key: _emailFieldKey,
                    controller: _emailController,
                    hint: 'Email address',
                    leadingIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    autofillHint: AutofillHints.email,
                    validator: _validateEmail,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _passwordFieldKey.currentState?.focus(),
                  ),
                ),
                const SizedBox(height: 14),
                AuthEnter(
                  delay: const Duration(milliseconds: 280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedAuthField(
                        key: _passwordFieldKey,
                        controller: _passwordController,
                        hint: 'Password',
                        leadingIcon: Icons.lock_outline_rounded,
                        obscure: true,
                        showEyeToggle: true,
                        autofillHint: AutofillHints.newPassword,
                        validator: _validatePassword,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) =>
                            _confirmFieldKey.currentState?.focus(),
                        onChanged: (v) {
                          setState(() => _password = v);
                          if (_confirmController.text.isNotEmpty &&
                              _confirmController.text == v) {
                            _confirmFieldKey.currentState?.clearError();
                          }
                        },
                      ),
                      PasswordStrengthIndicator(password: _password),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AuthEnter(
                  delay: const Duration(milliseconds: 320),
                  child: AnimatedAuthField(
                    key: _confirmFieldKey,
                    controller: _confirmController,
                    hint: 'Confirm password',
                    leadingIcon: Icons.verified_outlined,
                    obscure: true,
                    showEyeToggle: true,
                    validator: _validateConfirm,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _signUp(),
                  ),
                ),
                const SizedBox(height: 28),
                AuthEnter(
                  delay: const Duration(milliseconds: 360),
                  child: Obx(
                    () => MorphingPrimaryButton(
                      label: 'Create account',
                      isLoading: _authController.isLoading.value,
                      onPressed: _signUp,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const AuthEnter(
                  delay: Duration(milliseconds: 400),
                  child: AuthOrDivider(),
                ),
                const SizedBox(height: 16),
                AuthEnter(
                  delay: const Duration(milliseconds: 440),
                  child: AuthGoogleButton(
                    label: 'Continue with Google',
                    onPressed: _onGooglePressed,
                  ),
                ),
                const SizedBox(height: 40),
                AuthEnter(
                  delay: const Duration(milliseconds: 480),
                  child: AuthFooter(
                    prompt: 'Already have an account?',
                    cta: 'Sign in',
                    onCtaTap: () => Get.back(),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
