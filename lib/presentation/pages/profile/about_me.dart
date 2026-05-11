import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';
import 'package:url_launcher/url_launcher.dart';

class DeveloperAndDonationSection extends StatelessWidget {
  final String developerName = 'Krishna Vishwakarma';
  final String developerEmail = 'krishnavishwakarma2525@gmail.com';
  final String upiId = 'krishnavishwakarma9136@okhdfcbank';
  final String buyMeACoffeeUrl = 'https://buymeacoffee.com/krishna069';
  final String githubUrl = 'https://github.com/spyou';
  final String linkedinUrl =
      'https://linkedin.com/in/krishna-vishwakarma-8974b332a';

  const DeveloperAndDonationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDeveloperSection(context),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDeveloperSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary.withValues(alpha: 0.1), scheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                      scheme.primary,
                      scheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  image: const DecorationImage(
                    image: CachedNetworkImageProvider(
                      'https://avatars.githubusercontent.com/u/88382789?v=4',
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About the Developer',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
                    Text(
                      'App Developer & UI/UX Designer',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, Icons.person_outline, 'Name', developerName),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            Icons.email_outlined,
            'Email',
            developerEmail,
            isClickable: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSocialButton(
                context: context,
                icon: Icons.code,
                label: 'GitHub',
                color: scheme.onSurface,
                onTap: () {
                  launchUrl(Uri.parse(githubUrl));
                },
              ),
              const SizedBox(width: 12),
              _buildSocialButton(
                context: context,
                icon: Icons.work_outline,
                label: 'LinkedIn',
                color: scheme.secondary,
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.tertiary.withValues(alpha: 0.1), scheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: scheme.tertiary.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.tertiary,
                      scheme.tertiary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Support Development',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.tertiary,
                      ),
                    ),
                    Text(
                      'Help keep NutriCheck free and improve',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'If you love using NutriCheck and want to support its development, you can buy me a coffee! Your support helps me dedicate more time to adding new features and keeping the app free for everyone.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: scheme.secondary.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: scheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'UPI ID',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        upiId,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _copyToClipboard(context, upiId),
                      icon: Icon(Icons.copy, color: scheme.secondary),
                      tooltip: 'Copy UPI ID',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDonationButton(
                  context,
                  icon: Icons.payment,
                  label: 'Pay via UPI',
                  color: scheme.tertiary,
                  onTap: () => _launchUPI(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDonationButton(
                  context,
                  icon: Icons.coffee,
                  label: 'Buy Coffee',
                  color: scheme.error,
                  onTap: () {
                    _launchUrl(buyMeACoffeeUrl, context: context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Quick Amounts:',
            style: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildQuickAmountButton(context, '₹10', '10'),
              const SizedBox(width: 8),
              _buildQuickAmountButton(context, '₹25', '25'),
              const SizedBox(width: 8),
              _buildQuickAmountButton(context, '₹100', '100'),
              const SizedBox(width: 8),
              _buildQuickAmountButton(context, '₹500', '500'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: scheme.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Every contribution helps improve NutriCheck for everyone!',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
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
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isClickable = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: scheme.onSurface.withValues(alpha: 0.65), size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.65),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: isClickable ? () => _launchUrl('mailto:$value') : null,
            child: Text(
              value,
              style: TextStyle(
                color: isClickable ? scheme.primary : scheme.onSurface,
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
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
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
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: () => _launchUPIWithAmount(context, amount),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: scheme.tertiary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: scheme.tertiary.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.tertiary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

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
    _showThankYouMessage(amount);
  }

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
      if (kDebugMode) {
        print('Attempting to launch: $url');
      }

      final canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          CustomThemeFlushbar.show(
            title: 'Opening Payment App',
            message: 'Redirecting to your payment app...',
          );
        } else {
          if (!context.mounted) return;
          await _tryAlternativePaymentMethods(context, paymentType);
        }
      } else {
        if (!context.mounted) return;
        await _tryAlternativePaymentMethods(context, paymentType);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Payment launch error: $e');
      }
      if (!context.mounted) return;
      await _tryAlternativePaymentMethods(context, paymentType);
    }
  }

  Future<void> _tryAlternativePaymentMethods(
    BuildContext context,
    String paymentType,
  ) async {
    final alternativeUrls = [
      'tez://upi/pay?pa=$upiId&pn=${Uri.encodeComponent(developerName)}&cu=INR',
      'phonepe://pay?pa=$upiId&pn=${Uri.encodeComponent(developerName)}&cu=INR',
      'paytmmp://pay?pa=$upiId&pn=${Uri.encodeComponent(developerName)}&cu=INR',
    ];

    for (final url in alternativeUrls) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          CustomThemeFlushbar.show(
            title: 'Opening Payment App',
            message: 'Redirecting to your payment app...',
          );
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed alternative: $url - $e');
        }
      }
    }

    if (!context.mounted) return;
    _showPaymentFailureDialog(context, paymentType);
  }

  void _showPaymentFailureDialog(BuildContext context, String paymentType) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment, color: scheme.error),
            const SizedBox(width: 8),
            const Flexible(
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
            const Text(
              'To make UPI payments, please install one of these apps:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildAppSuggestion(
                context, 'Google Pay', Icons.account_balance_wallet),
            _buildAppSuggestion(context, 'PhonePe', Icons.phone_android),
            _buildAppSuggestion(context, 'Paytm', Icons.payment),
            _buildAppSuggestion(context, 'Any UPI App', Icons.apps),
            const SizedBox(height: 16),
            Text(
              'Or copy the UPI ID below and use it in any payment app:',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _copyToClipboard(context, upiId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.tertiary,
              foregroundColor: scheme.onTertiary,
            ),
            child: const Text('Copy UPI ID'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSuggestion(BuildContext context, String name, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon,
              color: scheme.onSurface.withValues(alpha: 0.65), size: 20),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _launchUrl(
    String url, {
    BuildContext? context,
    String? errorMessage,
  }) async {
    try {
      final uri = Uri.parse(url);
      if (kDebugMode) {
        print('Attempting to launch URL: $url');
      }

      final canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched && context != null) {
          CustomThemeFlushbar.show(
            title: 'Error',
            message: 'Failed to open link',
          );
        }
      } else {
        if (context != null) {
          CustomThemeFlushbar.show(
            title: 'Error',
            message: errorMessage ?? 'No app available to open this link',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('URL launch error: $e');
      }
      if (context != null) {
        CustomThemeFlushbar.show(
          title: 'Error',
          message: errorMessage ?? 'Could not open link: ${e.toString()}',
        );
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    CustomThemeFlushbar.show(
      title: 'Copied',
      message: 'UPI ID copied to clipboard',
    );
  }

  void _showThankYouMessage(String amount) {
    Future.delayed(const Duration(seconds: 1), () {
      CustomThemeFlushbar.show(
        title: 'Thank You!',
        message: 'Your ₹$amount contribution means the world to me!',
      );
    });
  }
}
