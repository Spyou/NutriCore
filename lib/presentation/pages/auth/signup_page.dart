import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../controllers/auth_controller.dart';

class SignUpPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthController authController = Get.find();

  SignUpPage({super.key});

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
                const SizedBox(height: 40),
                _buildHeader(context),
                const SizedBox(height: 40),
                _buildNameField(),
                const SizedBox(height: 20),
                _buildEmailField(),
                const SizedBox(height: 20),
                _buildPasswordField(),
                const SizedBox(height: 20),
                _buildConfirmPasswordField(),
                const SizedBox(height: 30),
                _buildSignUpButton(),
                const SizedBox(height: 20),
                _buildDivider(),
                const SizedBox(height: 20),
                _buildLoginLink(context),
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
        IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
        ),
        const SizedBox(height: 20),
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
            Icons.person_add,
            color: AppColors.textOnPrimary,
            size: 32,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Create Account',
          style: AppTextStyles.displayLarge(
            context,
          ).copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Join us to start your nutrition journey',
          style: AppTextStyles.bodyLarge(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Full Name',
        prefixIcon: const Icon(Icons.person_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Please enter your full name';
        }
        return null;
      },
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
          return 'Please enter a password';
        }
        if (value!.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        prefixIcon: const Icon(Icons.lock_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildSignUpButton() {
    return Builder(
      builder: (context) => Obx(
        () => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: authController.isLoading.value ? null : _signUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: authController.isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Create Account',
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

  Widget _buildDivider() {
    return Builder(
      builder: (context) => Row(
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
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Sign In',
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _signUp() {
    if (_formKey.currentState!.validate()) {
      authController.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
    }
  }
}
