import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../controllers/auth_controller.dart';
import 'signup_page.dart';

class LoginPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthController authController = Get.find();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                _buildHeader(context),
                const SizedBox(height: 40),
                _buildEmailField(),
                const SizedBox(height: 20),
                _buildPasswordField(),
                const SizedBox(height: 12),
                _buildForgotPassword(context),
                const SizedBox(height: 30),
                _buildLoginButton(), // ← Only this should use Obx
                const SizedBox(height: 20),
                _buildDivider(context),
                const SizedBox(height: 20),
                _buildSignUpLink(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.local_fire_department,
            color: AppColors.textOnPrimary,
            size: 32,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome Back!',
          style: AppTextStyles.displayLarge(
            context,
          ).copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue tracking your nutrition',
          style: AppTextStyles.bodyLarge(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Please enter your email';
        }
        if (!GetUtils.isEmail(value!)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Please enter your password';
        }
        if (value!.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildForgotPassword(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _showForgotPasswordDialog,
        child: Text(
          'Forgot Password?',
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Builder(
      builder: (context) => Obx(
        () => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: authController.isLoading.value ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: authController.isLoading.value
                  ? Colors.grey
                  : AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: authController.isLoading.value
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Signing In...',
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Sign In',
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textTertiary),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildSignUpLink(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Don\'t have an account? ',
            style: AppTextStyles.bodyMedium(context),
          ),
          TextButton(
            onPressed: () => Get.to(() => SignUpPage()),
            child: Text(
              'Sign Up',
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      authController.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Enter your email',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.trim().isNotEmpty) {
                authController.resetPassword(emailController.text.trim());
                Get.back();
              }
            },
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );
  }
}
