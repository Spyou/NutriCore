import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';
import 'package:url_launcher/url_launcher.dart';

class DeveloperAndDonationSection extends StatelessWidget {
  static const String _developerName = 'Krishna Vishwakarma';
  static const String _developerRole = 'App developer · UI/UX';
  static const String _developerEmail = 'krishnavishwakarma2525@gmail.com';
  static const String _githubUrl = 'https://github.com/spyou';
  static const String _linkedinUrl =
      'https://linkedin.com/in/krishna-vishwakarma-8974b332a';
  static const String _buyMeACoffeeUrl = 'https://buymeacoffee.com/krishna069';
  static const String _avatarUrl =
      'https://avatars.githubusercontent.com/u/88382789?v=4';
  static const String _appVersion = '1.0.0';

  const DeveloperAndDonationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ProfileHeader(),
        const SizedBox(height: 20),
        _ContactCard(
          onEmail: () => _launchUrl(context, 'mailto:$_developerEmail'),
          onCopyEmail: () => _copy(context, _developerEmail, 'Email'),
          onGithub: () => _launchUrl(context, _githubUrl),
          onLinkedIn: () => _launchUrl(context, _linkedinUrl),
        ),
        const SizedBox(height: 20),
        _SupportCard(
          onCoffee: () => _launchUrl(context, _buyMeACoffeeUrl),
        ),
        const SizedBox(height: 20),
        const _AppMetaCard(version: _appVersion),
      ],
    );
  }

  static Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      final ok = await canLaunchUrl(uri);
      if (!ok) {
        if (!context.mounted) return;
        CustomThemeFlushbar.show(
          title: 'Cannot open',
          message: 'No app is available to handle this link.',
        );
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!context.mounted) return;
      CustomThemeFlushbar.show(
        title: 'Cannot open',
        message: 'Failed to launch link.',
      );
    }
  }

  static void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    CustomThemeFlushbar.show(
      title: 'Copied',
      message: '$label copied to clipboard',
    );
  }
}

// ─── header ───────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: DeveloperAndDonationSection._avatarUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              errorWidget: (_, __, ___) => Icon(
                Icons.person_rounded,
                size: 40,
                color: scheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          DeveloperAndDonationSection._developerName,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          DeveloperAndDonationSection._developerRole,
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

// ─── contact card ─────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final VoidCallback onEmail;
  final VoidCallback onCopyEmail;
  final VoidCallback onGithub;
  final VoidCallback onLinkedIn;

  const _ContactCard({
    required this.onEmail,
    required this.onCopyEmail,
    required this.onGithub,
    required this.onLinkedIn,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _Row(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: DeveloperAndDonationSection._developerEmail,
            onTap: onEmail,
            trailing: IconButton(
              tooltip: 'Copy',
              onPressed: onCopyEmail,
              icon: Icon(
                Icons.content_copy_rounded,
                size: 18,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          _Row(
            icon: Icons.code_rounded,
            label: 'GitHub',
            value: 'github.com/spyou',
            onTap: onGithub,
            trailing: Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          _Row(
            icon: Icons.work_outline_rounded,
            label: 'LinkedIn',
            value: 'Krishna Vishwakarma',
            onTap: onLinkedIn,
            trailing: Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ].map((w) {
          // No-op map; preserved so the const Divider stays inline.
          return w;
        }).toList(),
      ),
    ).withSectionHeader(context, 'Contact', textTheme, scheme);
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;

  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: scheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

// ─── support card ────────────────────────────────────────────────────────

class _SupportCard extends StatelessWidget {
  final VoidCallback onCoffee;

  const _SupportCard({required this.onCoffee});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.tertiary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_outline_rounded,
                  color: scheme.tertiary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Support development',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'NutriCore is built and maintained by one person. '
            'If it helps you stay on track, a small tip keeps it free '
            'and free of ads.',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onCoffee,
              icon: const Icon(Icons.local_cafe_rounded, size: 18),
              label: const Text('Buy me a coffee'),
            ),
          ),
        ],
      ),
    ).withSectionHeader(context, 'Support', textTheme, scheme);
  }
}

// ─── app meta card ───────────────────────────────────────────────────────

class _AppMetaCard extends StatelessWidget {
  final String version;
  const _AppMetaCard({required this.version});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MetaRow(label: 'App', value: 'NutriCore'),
          const SizedBox(height: 6),
          _MetaRow(label: 'Version', value: version),
          const SizedBox(height: 6),
          const _MetaRow(label: 'Built with', value: 'Flutter'),
          const SizedBox(height: 12),
          Text(
            '© ${DateTime.now().year} Krishna Vishwakarma. All rights reserved.',
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── small extension to attach a section header above a card ──────────────

extension _WithSectionHeader on Widget {
  Widget withSectionHeader(
    BuildContext context,
    String title,
    TextTheme textTheme,
    ColorScheme scheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
          child: Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface.withValues(alpha: 0.75),
              letterSpacing: 0.4,
            ),
          ),
        ),
        this,
      ],
    );
  }
}
