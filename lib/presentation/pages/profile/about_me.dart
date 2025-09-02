import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutri_check/core/constants/app_colors.dart';
import 'package:nutri_check/core/constants/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

class DeveloperAndDonationSection extends StatelessWidget {
  final String developerName = "Krishna Vishwakarma";
  final String developerEmail = "krishnavishwakarma2525@gmail.com";
  final String upiId = "krishnavishwakarma9136@okhdfcbank";
  final String githubUrl = "https://github.com/spyou";
  final String linkedinUrl =
      "https://linkedin.com/in/krishna-vishwakarma-8974b332a";
  // final String appVersion = "1.0.0";
  // final String developmentYear = "2025";

  const DeveloperAndDonationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDeveloperSection(context),
        SizedBox(height: 24),
        _buildDonationSection(context),
        SizedBox(height: 24),
        // _buildAppInfoSection(context),
      ],
    );
  }

  Widget _buildDeveloperSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person, color: Colors.white, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Developer',
                      style: AppTextStyles.headingSmall(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Meet the creator behind NutriCheck',
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Developer Info
          _buildInfoRow(Icons.person_outline, 'Name', developerName),
          SizedBox(height: 12),
          _buildInfoRow(
            Icons.email_outlined,
            'Email',
            developerEmail,
            isClickable: true,
          ),
          SizedBox(height: 16),
          // Social Links
          Row(
            children: [
              _buildSocialButton(
                icon: Icons.code,
                label: 'GitHub',
                color: Colors.black87,
                onTap: () => _launchUrl(githubUrl, context: context),
              ),
              SizedBox(width: 12),
              _buildSocialButton(
                icon: Icons.work_outline,
                label: 'LinkedIn',
                color: Color(0xFF0077B5),
                onTap: () => _launchUrl(linkedinUrl, context: context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonationSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success.withOpacity(0.1), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success,
                      AppColors.success.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.favorite, color: Colors.white, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Support Development',
                      style: AppTextStyles.headingSmall(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      'Help keep NutriCheck free and improve',
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          Text(
            'If you love using NutriCheck and want to support its development, you can buy me a coffee! ☕ Your support helps me dedicate more time to adding new features and keeping the app free for everyone.',
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textPrimary, height: 1.4),
          ),
          SizedBox(height: 16),

          // UPI Info Card
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.info,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'UPI ID',
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        upiId,
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _copyToClipboard(context, upiId),
                      icon: Icon(Icons.copy, color: AppColors.info),
                      tooltip: 'Copy UPI ID',
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          // Donation Buttons
          Row(
            children: [
              Expanded(
                child: _buildDonationButton(
                  context,
                  icon: Icons.payment,
                  label: 'Pay via UPI',
                  color: AppColors.success,
                  onTap: () => _launchUPI(context),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildDonationButton(
                  context,
                  icon: Icons.coffee,
                  label: 'Buy Coffee ₹50',
                  color: AppColors.warning,
                  onTap: () => _launchUPIWithAmount(context, '50'),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Quick Amount Buttons
          Text(
            'Quick Amounts:',
            style: AppTextStyles.labelMedium(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildQuickAmountButton(context, '₹10', '10'),
              SizedBox(width: 8),
              _buildQuickAmountButton(context, '₹25', '25'),
              SizedBox(width: 8),
              _buildQuickAmountButton(context, '₹100', '100'),
              SizedBox(width: 8),
              _buildQuickAmountButton(context, '₹500', '500'),
            ],
          ),
          SizedBox(height: 12),

          // Appreciation Note
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: AppColors.warning, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Every contribution helps improve NutriCheck for everyone!',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildAppInfoSection(BuildContext context) {
  //   return Container(
  //     margin: EdgeInsets.symmetric(horizontal: 20),
  //     padding: EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [AppColors.info.withOpacity(0.1), AppColors.surface],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: AppColors.info.withOpacity(0.2)),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 10,
  //           offset: Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Container(
  //               padding: EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 gradient: LinearGradient(
  //                   colors: [AppColors.info, AppColors.info.withOpacity(0.8)],
  //                 ),
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Icon(Icons.info_outline, color: Colors.white, size: 24),
  //             ),
  //             SizedBox(width: 16),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     'App Information',
  //                     style: AppTextStyles.headingSmall(context).copyWith(
  //                       fontWeight: FontWeight.bold,
  //                       color: AppColors.info,
  //                     ),
  //                   ),
  //                   Text(
  //                     'Version and development details',
  //                     style: AppTextStyles.bodySmall(
  //                       context,
  //                     ).copyWith(color: AppColors.textSecondary),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: 16),

  //         _buildInfoRow(Icons.apps, 'App Version', appVersion),
  //         SizedBox(height: 12),
  //         _buildInfoRow(
  //           Icons.calendar_today,
  //           'Development Year',
  //           developmentYear,
  //         ),
  //         SizedBox(height: 12),
  //         _buildInfoRow(Icons.flutter_dash, 'Built with', 'Flutter & Dart'),
  //         SizedBox(height: 12),
  //         _buildInfoRow(Icons.psychology, 'AI Powered by', 'Google Gemini'),
  //         SizedBox(height: 16),

  //         Container(
  //           padding: EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             color: AppColors.info.withOpacity(0.05),
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: Text(
  //             '🚀 NutriCheck v$appVersion - Your AI-powered nutrition companion featuring barcode scanning, meal photo analysis, and personalized nutrition tracking. Made with ❤️ in India.',
  //             style: AppTextStyles.bodySmall(
  //               context,
  //             ).copyWith(color: AppColors.textSecondary, height: 1.4),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isClickable = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: isClickable ? () => _launchUrl('mailto:$value') : null,
            child: Text(
              value,
              style: TextStyle(
                color: isClickable ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                decoration: isClickable ? TextDecoration.underline : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonationButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(
    BuildContext context,
    String label,
    String amount,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _launchUPIWithAmount(context, amount),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 UPI Payment Methods
  Future<void> _launchUPI(BuildContext context) async {
    final upiUrl = 'upi://pay?pa=$upiId&pn=$developerName&cu=INR&mode=02';
    await _launchUrl(
      upiUrl,
      context: context,
      errorMessage:
          'Could not open UPI app. Please make sure you have Google Pay, PhonePe, or any UPI app installed.',
    );
  }

  Future<void> _launchUPIWithAmount(BuildContext context, String amount) async {
    final upiUrl =
        'upi://pay?pa=$upiId&pn=$developerName&am=$amount&cu=INR&tn=Coffee for NutriCheck Developer - Thank you!&mode=02';
    await _launchUrl(
      upiUrl,
      context: context,
      errorMessage:
          'Could not open UPI app. Please make sure you have Google Pay, PhonePe, or any UPI app installed.',
    );

    // Show thank you message
    _showThankYouMessage(context, amount);
  }

  Future<void> _launchUrl(
    String url, {
    BuildContext? context,
    String? errorMessage,
  }) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Show success message for UPI
        if (url.contains('upi://') && context != null) {
          Flushbar(
            title: 'Opening UPI App',
            message: 'Redirecting to your payment app...',
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.info,
            icon: Icon(Icons.payment, color: Colors.white),
          ).show(context);
        }
      } else {
        if (context != null) {
          Flushbar(
            title: 'Error',
            message: errorMessage ?? 'Could not launch $url',
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
            icon: Icon(Icons.error, color: Colors.white),
          ).show(context);
        }
      }
    } catch (e) {
      if (context != null) {
        Flushbar(
          title: 'Error',
          message: errorMessage ?? 'Could not launch $url',
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
          icon: Icon(Icons.error, color: Colors.white),
        ).show(context);
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    Flushbar(
      title: 'Copied!',
      message: 'UPI ID copied to clipboard',
      duration: Duration(seconds: 2),
      backgroundColor: AppColors.success,
      icon: Icon(Icons.copy, color: Colors.white),
    ).show(context);
  }

  void _showThankYouMessage(BuildContext context, String amount) {
    Future.delayed(Duration(seconds: 1), () {
      Flushbar(
        title: 'Thank You!',
        message: 'Your ₹$amount contribution means the world to me!',
        duration: Duration(seconds: 4),
        backgroundColor: AppColors.warning,
        icon: Icon(Icons.favorite, color: Colors.white),
      ).show(context);
    });
  }
}
