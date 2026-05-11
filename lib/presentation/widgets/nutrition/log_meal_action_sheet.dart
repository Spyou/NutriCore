import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:nutri_check/presentation/controllers/main_controller.dart';
import 'package:nutri_check/presentation/controllers/search_controller.dart'
    as app_search;
import 'package:nutri_check/presentation/widgets/nutrition/add_manual_meal_sheet.dart';
import 'package:nutri_check/presentation/widgets/search/search_skeleton.dart';
import 'package:nutri_check/presentation/widgets/shared/add_to_meal_sheet.dart';

class LogMealActionSheet extends StatefulWidget {
  const LogMealActionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const LogMealActionSheet(),
    );
  }

  @override
  State<LogMealActionSheet> createState() => _LogMealActionSheetState();
}

class _LogMealActionSheetState extends State<LogMealActionSheet> {
  final TextEditingController _searchCtl = TextEditingController();
  app_search.SearchController? _searchController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<app_search.SearchController>()) {
      _searchController = Get.find<app_search.SearchController>();
    }
    _searchCtl.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    if (!mounted) return;
    _searchController?.onSearchChanged(_searchCtl.text);
    setState(() {});
  }

  @override
  void dispose() {
    _searchCtl
      ..removeListener(_onQueryChanged)
      ..dispose();
    final ctl = _searchController;
    if (ctl != null) {
      ctl.searchQuery.value = '';
      ctl.searchResults.clear();
      ctl.isLoading.value = false;
      ctl.errorMessage.value = '';
    }
    super.dispose();
  }

  void _switchToTab(int index) {
    Navigator.of(context).pop();
    if (Get.isRegistered<MainController>()) {
      Get.find<MainController>().changeIndex(index);
    }
  }

  void _openCustomEntry() {
    final ctx = context;
    Navigator.of(ctx).pop();
    AddManualMealSheet.show(ctx);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mediaQuery = MediaQuery.of(context);
    final viewInsets = mediaQuery.viewInsets;
    final maxHeight = mediaQuery.size.height * 0.75;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Log a meal',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 18),
              _searchField(scheme, textTheme),
              const SizedBox(height: 16),
              _buildBody(scheme, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField(ColorScheme scheme, TextTheme textTheme) {
    return TextField(
      controller: _searchCtl,
      textInputAction: TextInputAction.search,
      style: textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: 'Search a product…',
        prefixIcon: Icon(Icons.search_rounded, color: scheme.primary),
        suffixIcon: _searchCtl.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
                onPressed: () => _searchCtl.clear(),
              ),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme scheme, TextTheme textTheme) {
    final query = _searchCtl.text.trim();

    if (query.isEmpty) {
      return _actionRows(scheme, textTheme);
    }

    final ctl = _searchController;
    if (ctl == null) {
      return _hint(
        scheme,
        textTheme,
        Icons.error_outline_rounded,
        'Search is unavailable right now',
      );
    }

    if (query.length < 2) {
      return Column(
        children: [
          _hint(
            scheme,
            textTheme,
            Icons.keyboard_alt_outlined,
            'Keep typing to search…',
          ),
          const SizedBox(height: 12),
          _actionRows(scheme, textTheme),
        ],
      );
    }

    return Obx(() {
      // Force subscription to all reactive fields up front so any
      // change wakes this builder, regardless of which branch we take.
      final loading = ctl.isLoading.value;
      final error = ctl.errorMessage.value;
      final resultCount = ctl.searchResults.length;

      if (loading) {
        return const SearchSkeleton(itemCount: 3);
      }
      if (error.isNotEmpty && resultCount == 0) {
        return _hint(
          scheme,
          textTheme,
          Icons.cloud_off_rounded,
          error,
        );
      }
      if (resultCount == 0) {
        return _hint(
          scheme,
          textTheme,
          Icons.search_off_rounded,
          'No matches for "$query"',
        );
      }
      final visible = ctl.searchResults.take(5).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final product in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _resultRow(scheme, textTheme, product),
            ),
        ],
      );
    });
  }

  Widget _hint(
    ColorScheme scheme,
    TextTheme textTheme,
    IconData icon,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(
    ColorScheme scheme,
    TextTheme textTheme,
    dynamic product,
  ) {
    final imageUrl =
        (product.imageFrontSmallUrl as String?) ??
        (product.imageFrontUrl as String?);
    final name = (product.productName as String?)?.trim().isNotEmpty == true
        ? product.productName as String
        : 'Unknown product';
    final brand = (product.brands as String?)?.trim() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          final ctx = context;
          Navigator.of(ctx).pop();
          AddToMealSheet.show(ctx, product);
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: imageUrl == null || imageUrl.isEmpty
                      ? Container(
                          color: scheme.primary.withValues(alpha: 0.08),
                          child: Icon(
                            Icons.fastfood_rounded,
                            size: 20,
                            color: scheme.primary.withValues(alpha: 0.4),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: scheme.primary.withValues(alpha: 0.08),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: scheme.primary.withValues(alpha: 0.08),
                            child: Icon(
                              Icons.image_rounded,
                              size: 18,
                              color: scheme.primary.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (brand.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        brand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionRows(ColorScheme scheme, TextTheme textTheme) {
    return Column(
      children: [
        _actionRow(
          scheme: scheme,
          textTheme: textTheme,
          icon: Icons.search_rounded,
          label: 'Browse all products',
          subtitle: 'Search OFF database',
          onTap: () => _switchToTab(1),
        ),
        const SizedBox(height: 10),
        _actionRow(
          scheme: scheme,
          textTheme: textTheme,
          icon: Icons.qr_code_scanner_rounded,
          label: 'Scan a barcode',
          subtitle: 'Quick lookup with camera',
          onTap: () => _switchToTab(2),
        ),
        const SizedBox(height: 10),
        _actionRow(
          scheme: scheme,
          textTheme: textTheme,
          icon: Icons.edit_note_rounded,
          label: 'Custom entry',
          subtitle: 'Type in your own meal',
          onTap: _openCustomEntry,
        ),
      ],
    );
  }

  Widget _actionRow({
    required ColorScheme scheme,
    required TextTheme textTheme,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: scheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
