import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/utils/components/custom_flushbar.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/auth/animated_auth_background.dart';
import '../../widgets/auth/animated_auth_field.dart';
import '../../widgets/auth/auth_enter.dart';
import '../../widgets/auth/auth_footer.dart';
import '../../widgets/auth/auth_google_button.dart';
import '../../widgets/auth/auth_or_divider.dart';
import '../../widgets/auth/auth_wordmark.dart';
import '../../widgets/auth/morphing_primary_button.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFieldKey = GlobalKey<AnimatedAuthFieldState>();
  final _passwordFieldKey = GlobalKey<AnimatedAuthFieldState>();
  final AuthController _authController = Get.find();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your email';
    if (!GetUtils.isEmail(v.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Please enter your password';
    if (v.length < 6) return 'Must be at least 6 characters';
    return null;
  }

  void _login() {
    final emailOk = _emailFieldKey.currentState?.validateAndShake() ?? false;
    final pwOk = _passwordFieldKey.currentState?.validateAndShake() ?? false;
    if (!emailOk || !pwOk) {
      HapticFeedback.lightImpact();
      return;
    }
    _authController.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  void _onGooglePressed() {
    HapticFeedback.selectionClick();
    _authController.signInWithGoogle();
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final scheme = Theme.of(context).colorScheme;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: scheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reset password',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  fontFamily: 'Inter',
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your email and we'll send you a reset link.",
                style: TextStyle(
                  fontSize: 14,
                  color: scheme.onSurface.withValues(alpha: 0.7),
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 20),
              AnimatedAuthField(
                controller: emailController,
                hint: 'Email address',
                leadingIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                autofillHint: AutofillHints.email,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitReset(emailController),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _submitReset(emailController),
                    child: const Text('Send link'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((_) => emailController.dispose());
  }

  void _submitReset(TextEditingController emailController) {
    final email = emailController.text.trim();
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      CustomThemeFlushbar.show(
        title: 'Invalid email',
        message: 'Enter a valid email',
      );
      return;
    }
    _authController.resetPassword(email);
    Get.back();
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: AuthEnter(child: AuthWordmark()),
                          ),
                          const SizedBox(height: 64),
                          AuthEnter(
                            delay: const Duration(milliseconds: 80),
                            child: Text(
                              'Welcome\nback.',
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
                              'Sign in to continue tracking your nutrition.',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.45,
                                color: scheme.onSurface.withValues(alpha: 0.6),
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          AuthEnter(
                            delay: const Duration(milliseconds: 200),
                            child: AnimatedAuthField(
                              key: _emailFieldKey,
                              controller: _emailController,
                              hint: 'Email address',
                              leadingIcon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              autofillHint: AutofillHints.email,
                              validator: _validateEmail,
                              autofocus: true,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) =>
                                  _passwordFieldKey.currentState?.focus(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          AuthEnter(
                            delay: const Duration(milliseconds: 240),
                            child: AnimatedAuthField(
                              key: _passwordFieldKey,
                              controller: _passwordController,
                              hint: 'Password',
                              leadingIcon: Icons.lock_outline_rounded,
                              obscure: true,
                              showEyeToggle: true,
                              autofillHint: AutofillHints.password,
                              validator: _validatePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _login(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          AuthEnter(
                            delay: const Duration(milliseconds: 280),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 36),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.primary,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          AuthEnter(
                            delay: const Duration(milliseconds: 320),
                            child: Obx(
                              () => MorphingPrimaryButton(
                                label: 'Sign in',
                                isLoading: _authController.isLoading.value,
                                onPressed: _login,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const AuthEnter(
                            delay: Duration(milliseconds: 360),
                            child: AuthOrDivider(),
                          ),
                          const SizedBox(height: 16),
                          AuthEnter(
                            delay: const Duration(milliseconds: 400),
                            child: AuthGoogleButton(
                              label: 'Continue with Google',
                              onPressed: _onGooglePressed,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 32),
                          AuthEnter(
                            delay: const Duration(milliseconds: 440),
                            child: AuthFooter(
                              prompt: "Don't have an account?",
                              cta: 'Sign up',
                              onCtaTap: () => Get.to(() => const SignUpPage()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          ),
        ),
      ),
    );
  }
}
