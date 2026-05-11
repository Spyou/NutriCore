import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

import '../../controllers/search_controller.dart' as app_search;
import '../../widgets/product_details_sheet.dart';
import '../../widgets/search/search_skeleton.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GetBuilder<app_search.SearchController>(
      init: Get.find<app_search.SearchController>(),
      builder: (controller) => Scaffold(
        backgroundColor: scheme.surface,
        body: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            // Pre-fetch 240px before the bottom so the next page is
            // already streaming in by the time the user reaches it.
            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 240 &&
                !controller.isLoadingMore.value &&
                controller.hasMore.value) {
              controller.loadMore();
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, controller),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildSearchBar(context, controller),
                    _buildCategoryFilter(controller),
                    _buildSearchContent(context, controller),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext outerContext,
    app_search.SearchController controller,
  ) {
    final outerScheme = Theme.of(outerContext).colorScheme;
    return SliverAppBar(
      expandedHeight: 110,
      toolbarHeight: 44,
      floating: true,
      pinned: true,
      snap: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final scheme = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;
          final double top = constraints.biggest.height;
          final double collapsedHeight =
              MediaQuery.of(context).padding.top + kToolbarHeight;
          final double expandedHeight =
              110 + MediaQuery.of(context).padding.top;
          final double shrinkOffset = expandedHeight - top;
          final double shrinkPercentage =
              (shrinkOffset / (expandedHeight - collapsedHeight)).clamp(
                0.0,
                1.0,
              );

          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(
                    alpha: 0.95 + (0.05 * shrinkPercentage),
                  ),
                  scheme.secondary.withValues(
                    alpha: 0.85 + (0.15 * shrinkPercentage),
                  ),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 15.0 * (1 - shrinkPercentage),
                  sigmaY: 15.0 * (1 - shrinkPercentage),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                  ),
                  child: FlexibleSpaceBar(
                    centerTitle: false,
                    titlePadding: EdgeInsets.only(
                      left: 20,
                      bottom: 0 + (8 * shrinkPercentage),
                    ),
                    title: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: shrinkPercentage > 0.5
                          ? Text(
                              'Search',
                              key: const ValueKey('collapsed_search'),
                              style: textTheme.titleLarge?.copyWith(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                    background: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 60,
                          top: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Large title
                            Transform.translate(
                              offset: Offset(0, 20 * shrinkPercentage),
                              child: Opacity(
                                opacity: (1 - shrinkPercentage * 1.5).clamp(
                                  0.0,
                                  1.0,
                                ),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.elasticOut,
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(-50 * (1 - value), 0),
                                      child: Text(
                                        'Search Products',
                                        style: textTheme.displayMedium
                                            ?.copyWith(
                                              color: scheme.onPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize:
                                                  30 - (6 * shrinkPercentage),
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Transform.translate(
                              offset: Offset(0, 15 * shrinkPercentage),
                              child: Opacity(
                                opacity: (1 - shrinkPercentage * 1.2).clamp(
                                  0.0,
                                  1.0,
                                ),
                                child: Obx(
                                  () => AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    switchInCurve: Curves.easeInOut,
                                    switchOutCurve: Curves.easeInOut,
                                    child: TweenAnimationBuilder<double>(
                                      key: ValueKey(
                                        controller.searchResults.length,
                                      ),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      curve: Curves.bounceOut,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: 0.8 + (0.2 * value),
                                          child: Row(
                                            children: [
                                              if (controller
                                                  .searchResults
                                                  .isNotEmpty) ...[
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${controller.searchResults.length}',
                                                    style: textTheme
                                                        .labelMedium
                                                        ?.copyWith(
                                                          color:
                                                              scheme.onPrimary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              Text(
                                                controller.searchResults.isEmpty
                                                    ? 'Find nutrition info for any food'
                                                    : 'results found',
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                      color: scheme.onPrimary
                                                          .withValues(
                                                            alpha: 0.9,
                                                          ),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      actions: [
        // Clear recent searches button
        Obx(
          () => AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: controller.recentSearches.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showClearRecentDialog(controller);
                        },

                        child: Icon(
                          Icons.history,
                          color: outerScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  void _showClearRecentDialog(app_search.SearchController controller) {
    final ctx = Get.context;
    if (ctx == null) return;
    final scheme = Theme.of(ctx).colorScheme;
    final textTheme = Theme.of(ctx).textTheme;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.history, color: scheme.primary),
            const SizedBox(width: 12),
            Text(
              'Clear Search History',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Text(
          'This will remove all your recent searches. Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.clearRecentSearches();
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    app_search.SearchController controller,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final secondary = scheme.onSurface.withValues(alpha: 0.7);
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller.textController,
        onChanged: controller.onSearchChanged,
        onSubmitted: controller.commitSearch,
        decoration: InputDecoration(
          hintText: 'Search for food products...',
          hintStyle: textTheme.bodyMedium?.copyWith(color: secondary),
          prefixIcon: Icon(Icons.search, color: scheme.primary),
          suffixIcon: Obx(
            () => controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    onPressed: controller.clearSearch,
                    icon: Icon(Icons.clear, color: secondary),
                  )
                : const SizedBox.shrink(),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: scheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(app_search.SearchController controller) {
    final visualCategories = [
      {'key': 'all', 'label': 'All', 'icon': Icons.apps},
      {'key': 'sweets', 'label': 'Sweets', 'icon': Icons.cake},
      {'key': 'dairy', 'label': 'Dairy', 'icon': Icons.water_drop},
      {'key': 'beverages', 'label': 'Drinks', 'icon': Icons.local_drink},
      {'key': 'snacks', 'label': 'Snacks', 'icon': Icons.fastfood},
      {'key': 'fruits', 'label': 'Fruits', 'icon': Icons.apple},
      {'key': 'vegetables', 'label': 'Veggies', 'icon': Icons.eco},
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: visualCategories.length,
        itemBuilder: (context, index) {
          final category = visualCategories[index];
          final scheme = Theme.of(context).colorScheme;
          return Obx(() {
            final selected =
                controller.selectedCategory.value == category['key'];
            final bgColor = selected
                ? scheme.primary
                : scheme.surfaceContainerHighest;
            final fgColor = selected ? scheme.onPrimary : scheme.onSurface;
            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () =>
                    controller.filterByCategory(category['key'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : scheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category['icon'] as IconData,
                        size: 18,
                        color: fgColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category['label'] as String,
                        style: TextStyle(
                          color: fgColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildSearchContent(
    BuildContext context,
    app_search.SearchController controller,
  ) {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildLoadingState(context);
      }

      if (controller.searchQuery.value.isEmpty) {
        return _buildInitialState(context, controller);
      }

      if (controller.searchResults.isEmpty &&
          controller.errorMessage.value.isNotEmpty) {
        return _buildErrorState(context, controller);
      }

      if (controller.searchResults.isEmpty) {
        return _buildEmptyState(context);
      }

      return _buildSearchResults(context, controller);
    });
  }

  Widget _buildErrorState(
    BuildContext context,
    app_search.SearchController controller,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: scheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              "Couldn't reach the food database",
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () =>
                  controller.searchProducts(controller.searchQuery.value),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    // Shimmer skeletons instead of a circular spinner: keeps the layout
    // stable as results stream in and hides any "Search Results" header
    // (skeleton already implies the section). Mirror the margin used by
    // `_buildSearchResults` so the skeleton doesn't shift sideways when
    // it swaps in for real results.
    return Container(
      margin: const EdgeInsets.all(20),
      child: const SearchSkeleton(itemCount: 6),
    );
  }

  Widget _buildInitialState(
    BuildContext context,
    app_search.SearchController controller,
  ) {
    return Column(
      children: [
        // Recent searches
        Obx(
          () => controller.recentSearches.isNotEmpty
              ? _buildRecentSearches(context, controller)
              : const SizedBox.shrink(),
        ),

        // Suggested products
        _buildSuggestedProducts(context, controller),
      ],
    );
  }

  Widget _buildRecentSearches(
    BuildContext context,
    app_search.SearchController controller,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: controller.clearRecentSearches,
                child: Text(
                  'Clear All',
                  style: TextStyle(color: scheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.recentSearches.take(8).map((search) {
              return GestureDetector(
                onTap: () {
                  controller.textController.text = search;
                  controller.searchProducts(search);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    search,
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedProducts(
    BuildContext context,
    app_search.SearchController controller,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Obx(
      () => controller.suggestedProducts.isNotEmpty
          ? Container(
              margin: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggested Products',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.suggestedProducts.length,
                      itemBuilder: (context, index) {
                        final product = controller.suggestedProducts[index];
                        return _buildSuggestedProductCard(
                          context,
                          product,
                          controller,
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSuggestedProductCard(
    BuildContext context,
    dynamic product,
    app_search.SearchController controller,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            clipBehavior: Clip.antiAlias,
            child: controller.buildCategoryIcon(product),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName ?? 'Unknown Product',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Show category instead of just calories
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    controller.getCategoryName(product),
                    style: TextStyle(
                      fontSize: 9,
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${controller.getCalories(product)} kcal/100g',
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.addProductToNutrition(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(fontSize: 12),
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

  void _openProductDetails(
    BuildContext context,
    Product product,
    app_search.SearchController controller,
  ) {
    HapticFeedback.selectionClick();
    controller.rememberQuery(controller.searchQuery.value);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => ProductDetailsSheet(product: product),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Product product,
    app_search.SearchController controller,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final knownCategory = controller.getKnownCategoryName(product);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openProductDetails(context, product, controller),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildProductCardBody(
              context,
              product,
              controller,
              scheme,
              knownCategory,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCardBody(
    BuildContext context,
    Product product,
    app_search.SearchController controller,
    ColorScheme scheme,
    String? knownCategory,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
        children: [
          _buildProductThumbnail(context, product),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName ?? 'Unknown Product',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (knownCategory != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      knownCategory,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (product.brands?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.brands!,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildNutrientChip(
                      context,
                      '${controller.getCalories(product)} kcal',
                      scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    _buildNutrientChip(
                      context,
                      '${controller.getNutrientValue(product, Nutrient.proteins).toStringAsFixed(1)}g P',
                      scheme.tertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: scheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                controller.rememberQuery(controller.searchQuery.value);
                controller.addProductToNutrition(product);
              },
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.add_rounded,
                  color: scheme.onPrimary,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildProductThumbnail(BuildContext context, Product product) {
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = product.imageFrontSmallUrl ?? product.imageFrontUrl;

    Widget fallback() => Container(
      width: 64,
      height: 64,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.fastfood_rounded,
        color: scheme.onSurface.withValues(alpha: 0.35),
        size: 24,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        height: 64,
        child: (imageUrl == null || imageUrl.isEmpty)
            ? fallback()
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: 64,
                height: 64,
                fadeInDuration: const Duration(milliseconds: 220),
                fadeOutDuration: const Duration(milliseconds: 120),
                placeholder: (context, url) =>
                    const _PulsingImagePlaceholder(),
                errorWidget: (context, url, error) => fallback(),
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tertiary = scheme.onSurface.withValues(alpha: 0.5);
    final secondary = scheme.onSurface.withValues(alpha: 0.7);
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: tertiary),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: textTheme.bodyMedium?.copyWith(color: tertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    app_search.SearchController controller,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Results',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.searchResults.length,
            itemBuilder: (context, index) {
              final product = controller.searchResults[index];
              return _buildProductCard(context, product, controller);
            },
          ),
          _buildPaginationFooter(context, controller),
        ],
      ),
    );
  }

  /// Footer row rendered under the results list. Shows a slim primary
  /// progress bar while fetching the next page, or a muted "End of
  /// results" caption once pagination has been exhausted.
  Widget _buildPaginationFooter(
    BuildContext context,
    app_search.SearchController controller,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Obx(() {
      if (controller.isLoadingMore.value) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SizedBox(
            height: 32,
            child: Center(
              child: SizedBox(
                width: 120,
                height: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                  ),
                ),
              ),
            ),
          ),
        );
      }
      if (!controller.hasMore.value && controller.searchResults.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'End of results',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildNutrientChip(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

}

class _PulsingImagePlaceholder extends StatefulWidget {
  const _PulsingImagePlaceholder();

  @override
  State<_PulsingImagePlaceholder> createState() =>
      _PulsingImagePlaceholderState();
}

class _PulsingImagePlaceholderState extends State<_PulsingImagePlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _animation,
      child: Container(
        color: scheme.primary.withValues(alpha: 0.10),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_rounded,
          color: scheme.primary.withValues(alpha: 0.45),
          size: 22,
        ),
      ),
    );
  }
}
