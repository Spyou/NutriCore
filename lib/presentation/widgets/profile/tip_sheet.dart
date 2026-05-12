import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/services/iap_service.dart';
import '../../../core/utils/components/custom_flushbar.dart';

class TipSheet extends StatefulWidget {
  const TipSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const TipSheet(),
    );
  }

  @override
  State<TipSheet> createState() => _TipSheetState();
}

class _TipSheetState extends State<TipSheet> {
  bool _loading = true;
  bool _buying = false;
  String? _buyingId;

  @override
  void initState() {
    super.initState();
    IapService.instance.onTip(_handleTipReceived);
    _bootstrap();
  }

  @override
  void dispose() {
    IapService.instance.onTip(null);
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await IapService.instance.init();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _handleTipReceived(String productId) {
    if (!mounted) return;
    setState(() {
      _buying = false;
      _buyingId = null;
    });
    Navigator.of(context).maybePop();
    CustomThemeFlushbar.show(
      title: 'Thank you',
      message: 'Your tip means a lot — it keeps NutriCore free and ad-free.',
    );
  }

  Future<void> _onBuy(ProductDetails product) async {
    if (_buying) return;
    setState(() {
      _buying = true;
      _buyingId = product.id;
    });
    final ok = await IapService.instance.buy(product);
    if (!ok && mounted) {
      setState(() {
        _buying = false;
        _buyingId = null;
      });
      CustomThemeFlushbar.show(
        title: 'Could not start purchase',
        message: 'Please try again in a moment.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.tertiary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: scheme.tertiary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send a tip',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'A small thanks via Google Play.',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _body(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!IapService.instance.isAvailable) {
      return _stateCard(
        context,
        title: 'Tips unavailable on this device',
        body: 'Google Play billing is not available. Tipping will be enabled '
            'when the app is installed from the Play Store.',
      );
    }
    final products = IapService.instance.products;
    if (products.isEmpty) {
      return _stateCard(
        context,
        title: 'Tips are coming soon',
        body: 'In-app tips are not yet activated for this build. Check back '
            'after the next release.',
      );
    }
    return Column(
      children: [
        for (final p in products) ...[
          _tipTile(context, p),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        Text(
          'Payments are handled by Google Play. No card details are shared '
          'with NutriCore.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
        ),
      ],
    );
  }

  Widget _tipTile(BuildContext context, ProductDetails p) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isBuying = _buying && _buyingId == p.id;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBuying ? null : () => _onBuy(p),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title.replaceAll(RegExp(r'\s*\(.*\)$'), ''),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (p.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        p.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isBuying)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    p.price,
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stateCard(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
