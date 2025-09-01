import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../controllers/search_controller.dart' as app_search;

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<app_search.SearchController>(
      init: app_search.SearchController(),
      builder: (controller) => Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(controller),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildSearchBar(controller),
                  _buildCategoryFilter(controller),
                  _buildSearchContent(controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(app_search.SearchController controller) {
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
            duration: Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(
                    0.95 + (0.05 * shrinkPercentage),
                  ),
                  AppColors.secondary.withOpacity(
                    0.85 + (0.15 * shrinkPercentage),
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
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                  child: FlexibleSpaceBar(
                    centerTitle: false,
                    titlePadding: EdgeInsets.only(
                      left: 20,
                      bottom: 0 + (8 * shrinkPercentage),
                    ),
                    title: AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      child: shrinkPercentage > 0.5
                          ? Text(
                              'Search',
                              key: ValueKey('collapsed_search'),
                              style: AppTextStyles.headingMedium(Get.context!)
                                  .copyWith(
                                    color: AppColors.textOnPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            )
                          : null,
                    ),
                    background: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.only(left: 20, right: 60, top: 8),
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
                                  duration: Duration(milliseconds: 800),
                                  curve: Curves.elasticOut,
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(-50 * (1 - value), 0),
                                      child: Text(
                                        'Search Products',
                                        style:
                                            AppTextStyles.displayMedium(
                                              Get.context!,
                                            ).copyWith(
                                              color: AppColors.textOnPrimary,
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
                            SizedBox(height: 4),
                            Transform.translate(
                              offset: Offset(0, 15 * shrinkPercentage),
                              child: Opacity(
                                opacity: (1 - shrinkPercentage * 1.2).clamp(
                                  0.0,
                                  1.0,
                                ),
                                child: Obx(
                                  () => AnimatedSwitcher(
                                    duration: Duration(milliseconds: 400),
                                    switchInCurve: Curves.easeInOut,
                                    switchOutCurve: Curves.easeInOut,
                                    child: TweenAnimationBuilder<double>(
                                      key: ValueKey(
                                        controller.searchResults.length,
                                      ),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: Duration(milliseconds: 500),
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
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${controller.searchResults.length}',
                                                    style:
                                                        AppTextStyles.labelMedium(
                                                          Get.context!,
                                                        ).copyWith(
                                                          color: AppColors
                                                              .textOnPrimary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                              ],
                                              Text(
                                                controller.searchResults.isEmpty
                                                    ? 'Find nutrition info for any food'
                                                    : 'results found',
                                                style:
                                                    AppTextStyles.bodyMedium(
                                                      Get.context!,
                                                    ).copyWith(
                                                      color: AppColors
                                                          .textOnPrimary
                                                          .withOpacity(0.9),
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
                            SizedBox(height: 8),
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
            duration: Duration(milliseconds: 300),
            child: controller.recentSearches.isNotEmpty
                ? Padding(
                    padding: EdgeInsets.only(right: 16),
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
                          color: AppColors.textOnPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  )
                : SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  void _showClearRecentDialog(app_search.SearchController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.history, color: AppColors.primary),
            SizedBox(width: 12),
            Text(
              'Clear Search History',
              style: AppTextStyles.headingMedium(Get.context!),
            ),
          ],
        ),
        content: Text('This will remove all your recent searches. Continue?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.clearRecentSearches();
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(app_search.SearchController controller) {
    return Container(
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller.textController,
        onSubmitted: controller.searchProducts,
        decoration: InputDecoration(
          hintText: 'Search for food products...',
          hintStyle: AppTextStyles.bodyMedium(
            Get.context!,
          ).copyWith(color: AppColors.textSecondary),
          prefixIcon: Icon(Icons.search, color: AppColors.primary),
          suffixIcon: Obx(
            () => controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    onPressed: controller.clearSearch,
                    icon: Icon(Icons.clear, color: AppColors.textSecondary),
                  )
                : SizedBox.shrink(),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(app_search.SearchController controller) {
    final visualCategories = [
      {
        'key': 'all',
        'label': 'All',
        'icon': Icons.apps,
        'color': AppColors.primary,
      },
      {
        'key': 'sweets',
        'label': 'Sweets',
        'icon': Icons.cake,
        'color': Colors.brown,
      },
      {
        'key': 'dairy',
        'label': 'Dairy',
        'icon': Icons.water_drop,
        'color': Colors.blue,
      },
      {
        'key': 'beverages',
        'label': 'Drinks',
        'icon': Icons.local_drink,
        'color': Colors.cyan,
      },
      {
        'key': 'snacks',
        'label': 'Snacks',
        'icon': Icons.fastfood,
        'color': Colors.deepOrange,
      },
      {
        'key': 'fruits',
        'label': 'Fruits',
        'icon': Icons.apple,
        'color': Colors.red,
      },
      {
        'key': 'vegetables',
        'label': 'Veggies',
        'icon': Icons.eco,
        'color': Colors.green,
      },
    ];

    return Container(
      height: 40,
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: visualCategories.length,
        itemBuilder: (context, index) {
          final category = visualCategories[index];
          return Obx(
            () => Container(
              margin: EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () =>
                    controller.filterByCategory(category['key'] as String),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: controller.selectedCategory.value == category['key']
                        ? (category['color'] as Color)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: category['color'] as Color,
                      width:
                          controller.selectedCategory.value == category['key']
                          ? 0
                          : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category['icon'] as IconData,
                        size: 18,
                        color:
                            controller.selectedCategory.value == category['key']
                            ? Colors.white
                            : category['color'] as Color,
                      ),
                      SizedBox(width: 6),
                      Text(
                        category['label'] as String,
                        style: TextStyle(
                          color:
                              controller.selectedCategory.value ==
                                  category['key']
                              ? Colors.white
                              : category['color'] as Color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
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
    );
  }

  Widget _buildSearchContent(app_search.SearchController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildLoadingState();
      }

      if (controller.searchQuery.value.isEmpty) {
        return _buildInitialState(controller);
      }

      if (controller.searchResults.isEmpty) {
        return _buildEmptyState();
      }

      return _buildSearchResults(controller);
    });
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Searching products...',
              style: AppTextStyles.bodyLarge(Get.context!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState(app_search.SearchController controller) {
    return Column(
      children: [
        // Recent searches
        Obx(
          () => controller.recentSearches.isNotEmpty
              ? _buildRecentSearches(controller)
              : SizedBox.shrink(),
        ),

        // Suggested products
        _buildSuggestedProducts(controller),
      ],
    );
  }

  Widget _buildRecentSearches(app_search.SearchController controller) {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
                style: AppTextStyles.headingMedium(Get.context!),
              ),
              TextButton(
                onPressed: controller.clearRecentSearches,
                child: Text(
                  'Clear All',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
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
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    search,
                    style: TextStyle(
                      color: AppColors.primary,
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

  Widget _buildSuggestedProducts(app_search.SearchController controller) {
    return Obx(
      () => controller.suggestedProducts.isNotEmpty
          ? Container(
              margin: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggested Products',
                    style: AppTextStyles.headingMedium(Get.context!),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.suggestedProducts.length,
                      itemBuilder: (context, index) {
                        final product = controller.suggestedProducts[index];
                        return _buildSuggestedProductCard(product, controller);
                      },
                    ),
                  ),
                ],
              ),
            )
          : SizedBox.shrink(),
    );
  }

  Widget _buildSuggestedProductCard(
    dynamic product,
    app_search.SearchController controller,
  ) {
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            clipBehavior: Clip.antiAlias,
            child: controller.buildCategoryIcon(product),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName ?? 'Unknown Product',
                  style: AppTextStyles.bodyMedium(
                    Get.context!,
                  ).copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                // Show category instead of just calories
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    controller.getCategoryName(product),
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${controller.getCalories(product)} kcal/100g',
                  style: AppTextStyles.labelMedium(
                    Get.context!,
                  ).copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.addProductToNutrition(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      'Add',
                      style: TextStyle(color: Colors.white, fontSize: 12),
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

  Widget _buildProductCard(
    dynamic product,
    app_search.SearchController controller,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: controller.buildCategoryIcon(product),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName ?? 'Unknown Product',
                  style: AppTextStyles.bodyLarge(
                    Get.context!,
                  ).copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                // Show category tag
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    controller.getCategoryName(product),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (product.brands?.isNotEmpty == true) ...[
                  SizedBox(height: 4),
                  Text(
                    product.brands!,
                    style: AppTextStyles.bodySmall(
                      Get.context!,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                ],
                SizedBox(height: 8),
                Row(
                  children: [
                    _buildNutrientChip(
                      '${controller.getCalories(product)} kcal',
                      AppColors.calories,
                    ),
                    SizedBox(width: 8),
                    _buildNutrientChip(
                      '${controller.getNutrientValue(product, Nutrient.proteins).toStringAsFixed(1)}g P',
                      AppColors.proteins,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => controller.addProductToNutrition(product),
            icon: Icon(Icons.add_circle, color: AppColors.primary, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textTertiary),
            SizedBox(height: 16),
            Text(
              'No products found',
              style: AppTextStyles.headingMedium(
                Get.context!,
              ).copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: AppTextStyles.bodyMedium(
                Get.context!,
              ).copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(app_search.SearchController controller) {
    return Container(
      margin: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Results',
            style: AppTextStyles.headingMedium(Get.context!),
          ),
          SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: NeverScrollableScrollPhysics(),
            itemCount: controller.searchResults.length,
            itemBuilder: (context, index) {
              final product = controller.searchResults[index];
              return _buildProductCard(product, controller);
            },
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildProductImage(String? imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl ?? '',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => Container(
        color: AppColors.surfaceVariant,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        print(' Image load error for URL: $url');
        print('Error: $error');
        return Container(
          color: AppColors.surfaceVariant,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                SizedBox(height: 4),
                Text(
                  'No Image',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNutrientChip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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

  Widget buildCategoryIcon(Product product) {
    final categoryInfo = _getCategoryFromProduct(product);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: categoryInfo['gradient'] as List<Color>,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          categoryInfo['icon'] as IconData,
          color: Colors.white,
          size: categoryInfo['size'] as double,
        ),
      ),
    );
  }

  Map<String, dynamic> _getCategoryFromProduct(Product product) {
    final productName = (product.productName ?? '').toLowerCase();
    final categories = (product.categories ?? '').toLowerCase();
    final brands = (product.brands ?? '').toLowerCase();

    final fullText = '$productName $categories $brands';

    // Chocolate & Sweets
    if (_containsAny(fullText, [
      'chocolate',
      'candy',
      'sweet',
      'cookie',
      'biscuit',
      'cake',
      'pastry',
      'dessert',
      'ice cream',
      'chocolate',
      'cadbury',
      'nestle',
      'kitkat',
      'snickers',
    ])) {
      return {
        'icon': Icons.cake,
        'gradient': [Colors.brown[400]!, Colors.brown[600]!],
        'size': 30.0,
        'category': 'Sweets & Desserts',
      };
    }

    // Dairy Products
    if (_containsAny(fullText, [
      'milk',
      'cheese',
      'yogurt',
      'yoghurt',
      'butter',
      'cream',
      'dairy',
      'lassi',
      'curd',
      'paneer',
      'amul',
      'mother dairy',
    ])) {
      return {
        'icon': Icons.water_drop,
        'gradient': [Colors.blue[300]!, Colors.blue[500]!],
        'size': 28.0,
        'category': 'Dairy Products',
      };
    }

    // Beverages
    if (_containsAny(fullText, [
      'drink',
      'juice',
      'soda',
      'cola',
      'pepsi',
      'coca',
      'water',
      'tea',
      'coffee',
      'beverage',
      'shake',
      'smoothie',
      'thumsup',
    ])) {
      return {
        'icon': Icons.local_drink,
        'gradient': [Colors.cyan[400]!, Colors.cyan[600]!],
        'size': 28.0,
        'category': 'Beverages',
      };
    }

    // Bakery & Bread
    if (_containsAny(fullText, [
      'bread',
      'bun',
      'roll',
      'toast',
      'bakery',
      'croissant',
      'muffin',
      'bagel',
      'baguette',
    ])) {
      return {
        'icon': Icons.bakery_dining,
        'gradient': [Colors.orange[400]!, Colors.orange[600]!],
        'size': 28.0,
        'category': 'Bakery',
      };
    }

    // Fruits
    if (_containsAny(fullText, [
      'fruit',
      'apple',
      'banana',
      'orange',
      'grape',
      'berry',
      'mango',
      'pineapple',
      'strawberry',
      'kiwi',
      'peach',
    ])) {
      return {
        'icon': Icons.apple,
        'gradient': [Colors.red[400]!, Colors.red[600]!],
        'size': 28.0,
        'category': 'Fruits',
      };
    }

    // Vegetables
    if (_containsAny(fullText, [
      'vegetable',
      'carrot',
      'broccoli',
      'spinach',
      'lettuce',
      'tomato',
      'cucumber',
      'pepper',
      'onion',
      'potato',
    ])) {
      return {
        'icon': Icons.eco,
        'gradient': [Colors.green[400]!, Colors.green[600]!],
        'size': 28.0,
        'category': 'Vegetables',
      };
    }

    // Meat & Protein
    if (_containsAny(fullText, [
      'meat',
      'chicken',
      'beef',
      'pork',
      'fish',
      'salmon',
      'tuna',
      'protein',
      'egg',
      'seafood',
    ])) {
      return {
        'icon': Icons.restaurant,
        'gradient': [Colors.red[700]!, Colors.red[900]!],
        'size': 28.0,
        'category': 'Meat & Protein',
      };
    }

    // Grains & Cereals
    if (_containsAny(fullText, [
      'cereal',
      'rice',
      'wheat',
      'oat',
      'grain',
      'pasta',
      'noodle',
      'quinoa',
      'barley',
      'corn',
    ])) {
      return {
        'icon': Icons.grass,
        'gradient': [Colors.amber[600]!, Colors.amber[800]!],
        'size': 28.0,
        'category': 'Grains & Cereals',
      };
    }

    // Nuts & Seeds
    if (_containsAny(fullText, [
      'nut',
      'almond',
      'peanut',
      'cashew',
      'walnut',
      'seed',
      'sunflower',
      'pumpkin',
    ])) {
      return {
        'icon': Icons.scatter_plot,
        'gradient': [Colors.brown[300]!, Colors.brown[500]!],
        'size': 26.0,
        'category': 'Nuts & Seeds',
      };
    }

    // Snacks & Fast Food
    if (_containsAny(fullText, [
      'snack',
      'chip',
      'crisp',
      'popcorn',
      'pretzel',
      'cracker',
      'fast food',
      'fries',
      'burger',
      'pizza',
    ])) {
      return {
        'icon': Icons.fastfood,
        'gradient': [Colors.deepOrange[400]!, Colors.deepOrange[600]!],
        'size': 28.0,
        'category': 'Snacks & Fast Food',
      };
    }

    // Condiments & Sauces
    if (_containsAny(fullText, [
      'sauce',
      'ketchup',
      'mayo',
      'mustard',
      'honey',
      'jam',
      'syrup',
      'vinegar',
      'oil',
      'spice',
    ])) {
      return {
        'icon': Icons.water_drop_outlined,
        'gradient': [Colors.yellow[600]!, Colors.yellow[800]!],
        'size': 26.0,
        'category': 'Condiments',
      };
    }

    // General Food
    return {
      'icon': Icons.restaurant_menu,
      'gradient': [Colors.grey[400]!, Colors.grey[600]!],
      'size': 28.0,
      'category': 'Food Product',
    };
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  // category name
  String getCategoryName(Product product) {
    final categoryInfo = _getCategoryFromProduct(product);
    return categoryInfo['category'] as String;
  }
}
