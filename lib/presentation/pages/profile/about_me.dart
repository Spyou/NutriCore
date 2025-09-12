import 'package:another_flushbar/flushbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutri_check/core/constants/app_colors.dart';
import 'package:nutri_check/core/constants/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

class DeveloperAndDonationSection extends StatelessWidget {
  final String developerName = "Krishna Vishwakarma";
  final String developerEmail = "krishnavishwakarma2525@gmail.com";
  final String upiId = "krishnavishwakarma9136@okhdfcbank";
  final String buyMeACoffeeUrl = "https://buymeacoffee.com/krishna069";
  final String githubUrl = "https://github.com/spyou";
  final String linkedinUrl =
      "https://linkedin.com/in/krishna-vishwakarma-8974b332a";

  const DeveloperAndDonationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDeveloperSection(context),
        SizedBox(height: 24),
        // _buildDonationSection(context),
        // SizedBox(height: 24),
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
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                      'https://avatars.githubusercontent.com/u/88382789?v=4',
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About the Developer',
                      style: AppTextStyles.headingSmall(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'App Developer & UI/UX Designer',
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
                onTap: () {
                  launchUrl(Uri.parse(githubUrl));
                },
              ),
              SizedBox(width: 12),
              _buildSocialButton(
                icon: Icons.work_outline,
                label: 'LinkedIn',
                color: Color(0xFF0077B5),
                onTap: () {
                  launchUrl(Uri.parse(linkedinUrl));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
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
                  label: 'Buy Coffee',
                  color: AppColors.warning,
                  onTap: () {
                    _launchUrl(buyMeACoffeeUrl, context: context);
                  },
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

  // 🔥 ENHANCED: Robust UPI Payment Methods
  Future<void> _launchUPI(BuildContext context) async {
    final upiUrl = _buildUPIUrl();
    await _launchPaymentUrl(context, upiUrl, 'UPI payment');
  }

  Future<void> _launchUPIWithAmount(BuildContext context, String amount) async {
    final upiUrl = _buildUPIUrl(
      amount: amount,
      note: 'Coffee for NutriCheck Developer - Thank you!',
    );
    await _launchPaymentUrl(context, upiUrl, 'UPI payment');
    _showThankYouMessage(context, amount);
  }

  // 🔥 ROBUST: Build proper UPI URL
  String _buildUPIUrl({String? amount, String? note}) {
    final params = <String, String>{
      'pa': upiId,
      'pn': developerName,
      'cu': 'INR',
      'mode': '02',
    };

    if (amount != null && amount.isNotEmpty) {
      params['am'] = amount;
    }

    if (note != null && note.isNotEmpty) {
      params['tn'] = Uri.encodeComponent(note);
    }

    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');

    return 'upi://pay?$query';
  }

  Future<void> _launchPaymentUrl(
    BuildContext context,
    String url,
    String paymentType,
  ) async {
    try {
      final uri = Uri.parse(url);
      print('🔍 Attempting to launch: $url');

      // Method 1: Try canLaunchUrl first
      final canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          Flushbar(
            title: 'Opening Payment App',
            message: 'Redirecting to your payment app...',
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.info,
            icon: Icon(Icons.payment, color: Colors.white),
          ).show(context);
        } else {
          await _tryAlternativePaymentMethods(context, paymentType);
        }
      } else {
        await _tryAlternativePaymentMethods(context, paymentType);
      }
    } catch (e) {
      print('Payment launch error: $e');
      await _tryAlternativePaymentMethods(context, paymentType);
    }
  }

  Future<void> _tryAlternativePaymentMethods(
    BuildContext context,
    String paymentType,
  ) async {
    final alternativeUrls = [
      'tez://upi/pay?pa=$upiId&pn=${Uri.encodeComponent(developerName)}&cu=INR', // Google Pay
      'phonepe://pay?pa=$upiId&pn=${Uri.encodeComponent(developerName)}&cu=INR', // PhonePe
      'paytmmp://pay?pa=$upiId&pn=${Uri.encodeComponent(developerName)}&cu=INR', // Paytm
    ];

    for (final url in alternativeUrls) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          Flushbar(
            title: 'Opening Payment App',
            message: 'Redirecting to your payment app...',
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.info,
            icon: Icon(Icons.payment, color: Colors.white),
          ).show(context);
          return;
        }
      } catch (e) {
        print('Failed alternative: $url - $e');
      }
    }

    _showPaymentFailureDialog(context, paymentType);
  }

  void _showPaymentFailureDialog(BuildContext context, String paymentType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment, color: AppColors.warning),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Payment App Not Found',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To make UPI payments, please install one of these apps:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            _buildAppSuggestion('Google Pay', Icons.account_balance_wallet),
            _buildAppSuggestion('PhonePe', Icons.phone_android),
            _buildAppSuggestion('Paytm', Icons.payment),
            _buildAppSuggestion('Any UPI App', Icons.apps),
            SizedBox(height: 16),
            Text(
              'Or copy the UPI ID below and use it in any payment app:',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _copyToClipboard(context, upiId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: Text('Copy UPI ID', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSuggestion(String name, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          SizedBox(width: 12),
          Text(name, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // 🔥 ENHANCED: General URL launcher with better error handling
  Future<void> _launchUrl(
    String url, {
    BuildContext? context,
    String? errorMessage,
  }) async {
    try {
      final uri = Uri.parse(url);
      print('🔍 Attempting to launch URL: $url');

      final canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched && context != null) {
          Flushbar(
            title: '❌ Error',
            message: 'Failed to open link',
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
            icon: Icon(Icons.error, color: Colors.white),
          ).show(context);
        }
      } else {
        if (context != null) {
          Flushbar(
            title: '❌ Error',
            message: errorMessage ?? 'No app available to open this link',
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
            icon: Icon(Icons.error, color: Colors.white),
          ).show(context);
        }
      }
    } catch (e) {
      print('❌ URL launch error: $e');
      if (context != null) {
        Flushbar(
          title: '❌ Error',
          message: errorMessage ?? 'Could not open link: ${e.toString()}',
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
      title: '📋 Copied!',
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
