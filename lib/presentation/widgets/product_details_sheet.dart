import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../controllers/nutrition_controller.dart';
import 'shared/add_to_meal_sheet.dart';

class ProductDetailsSheet extends StatelessWidget {
  final Product product;

  const ProductDetailsSheet({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductImage(),
                  const SizedBox(height: 20),
                  _buildCaloriesHighlight(),
                  const SizedBox(height: 20),
                  _buildBasicInfo(),
                  const SizedBox(height: 20),
                  _buildDetailedNutrition(),
                  const SizedBox(height: 20),
                  _buildMacronutrientsChart(),
                  const SizedBox(height: 20),
                  _buildIngredients(),
                  const SizedBox(height: 20),
                  _buildScores(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesHighlight() {
    final calories = product.nutriments?.getValue(
      Nutrient.energyKCal,
      PerSize.oneHundredGrams,
    );
    final caloriesServing = product.nutriments?.getValue(
      Nutrient.energyKCal,
      PerSize.serving,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.calories.withValues(alpha: 0.1),
            AppColors.calories.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.calories.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.calories,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${calories?.toInt() ?? 0} kcal',
                  style: AppTextStyles.displayMedium(Get.context!).copyWith(
                    color: AppColors.calories,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'per 100g',
                  style: AppTextStyles.bodyMedium(
                    Get.context!,
                  ).copyWith(color: AppColors.textSecondary),
                ),
                if (caloriesServing != null && product.servingSize != null)
                  Text(
                    '${caloriesServing.toInt()} kcal per serving (${product.servingSize})',
                    style: AppTextStyles.labelMedium(
                      Get.context!,
                    ).copyWith(color: AppColors.calories),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedNutrition() {
    if (product.nutriments == null) return const SizedBox.shrink();

    final nutriments = product.nutriments!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complete Nutrition Facts',
          style: AppTextStyles.headingMedium(Get.context!),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textTertiary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              _buildNutritionRow(
                'Energy (Calories)',
                '${nutriments.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams)?.toInt() ?? 0} kcal',
                AppColors.calories,
                isHighlight: true,
              ),
              _buildNutritionRow(
                'Energy (Kilojoules)',
                '${nutriments.getValue(Nutrient.energyKJ, PerSize.oneHundredGrams)?.toInt() ?? 0} kJ',
                AppColors.textSecondary,
              ),
              const Divider(),
              _buildNutritionRow(
                'Proteins',
                '${nutriments.getValue(Nutrient.proteins, PerSize.oneHundredGrams)?.toStringAsFixed(1) ?? '0'} g',
                AppColors.proteins,
              ),
              _buildNutritionRow(
                'Carbohydrates',
                '${nutriments.getValue(Nutrient.carbohydrates, PerSize.oneHundredGrams)?.toStringAsFixed(1) ?? '0'} g',
                AppColors.carbs,
              ),
              _buildNutritionRow(
                '  - of which Sugars',
                '${nutriments.getValue(Nutrient.sugars, PerSize.oneHundredGrams)?.toStringAsFixed(1) ?? '0'} g',
                AppColors.sugar,
                isIndented: true,
              ),
              _buildNutritionRow(
                'Fat',
                '${nutriments.getValue(Nutrient.fat, PerSize.oneHundredGrams)?.toStringAsFixed(1) ?? '0'} g',
                AppColors.fats,
              ),
              _buildNutritionRow(
                '  - of which Saturated',
                '${nutriments.getValue(Nutrient.saturatedFat, PerSize.oneHundredGrams)?.toStringAsFixed(1) ?? '0'} g',
                AppColors.fats,
                isIndented: true,
              ),
              const Divider(),
              _buildNutritionRow(
                'Dietary Fiber',
                '${nutriments.getValue(Nutrient.fiber, PerSize.oneHundredGrams)?.toStringAsFixed(1) ?? '0'} g',
                AppColors.fiber,
              ),
              _buildNutritionRow(
                'Salt',
                '${nutriments.getValue(Nutrient.salt, PerSize.oneHundredGrams)?.toStringAsFixed(2) ?? '0'} g',
                AppColors.salt,
              ),
              _buildNutritionRow(
                'Sodium',
                '${nutriments.getValue(Nutrient.sodium, PerSize.oneHundredGrams)?.toStringAsFixed(3) ?? '0'} g',
                AppColors.salt,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacronutrientsChart() {
    if (product.nutriments == null) return const SizedBox.shrink();

    final nutriments = product.nutriments!;
    final proteins =
        nutriments.getValue(Nutrient.proteins, PerSize.oneHundredGrams) ?? 0;
    final carbs =
        nutriments.getValue(Nutrient.carbohydrates, PerSize.oneHundredGrams) ??
        0;
    final fats =
        nutriments.getValue(Nutrient.fat, PerSize.oneHundredGrams) ?? 0;

    final total = proteins + carbs + fats;
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Macronutrient Breakdown',
          style: AppTextStyles.headingMedium(Get.context!),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Visual bar chart
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    if (proteins > 0)
                      Expanded(
                        flex: (proteins * 100 / total).round(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.proteins,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    if (carbs > 0)
                      Expanded(
                        flex: (carbs * 100 / total).round(),
                        child: Container(color: AppColors.carbs),
                      ),
                    if (fats > 0)
                      Expanded(
                        flex: (fats * 100 / total).round(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.fats,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroItem(
                    'Proteins',
                    proteins,
                    total,
                    AppColors.proteins,
                  ),
                  _buildMacroItem('Carbs', carbs, total, AppColors.carbs),
                  _buildMacroItem('Fats', fats, total, AppColors.fats),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacroItem(
    String label,
    double value,
    double total,
    Color color,
  ) {
    final percentage = total > 0 ? (value * 100 / total) : 0;

    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '${percentage.toInt()}%',
              style: AppTextStyles.labelLarge(
                Get.context!,
              ).copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.labelMedium(Get.context!)),
        Text(
          '${value.toStringAsFixed(1)}g',
          style: AppTextStyles.labelSmall(Get.context!).copyWith(color: color),
        ),
      ],
    );
  }

  // 🔥 Updated Action Buttons with Firebase Integration
  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Builder(builder: (context) {
                return ElevatedButton.icon(
                  onPressed: () => AddToMealSheet.show(context, product),
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Add to Meal Log'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _addToFavorites(
                  {
                    'name': product.productName ?? 'Scanned Product',
                    'barcode': product.barcode,
                    'imageUrl': product.imageFrontUrl,
                  },
                  0,
                  'list',
                  Get.find<NutritionController>(),
                ),
                icon: const Icon(Icons.favorite_border),
                label: const Text('Add to Favorites'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _shareProduct(),
            icon: const Icon(Icons.share),
            label: const Text('Share Product'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
  // Helper methods (your existing ones)
  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.textTertiary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              product.productName ?? 'Unknown Product',
              style: AppTextStyles.headingLarge(Get.context!),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(Get.context!),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    return Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final imageUrl = product.imageFrontSmallUrl ??
            product.imageFrontUrl ??
            product.imagePackagingSmallUrl ??
            product.imagePackagingUrl;

        Widget shell({required Widget child}) => AspectRatio(
              aspectRatio: 4 / 5,
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: child,
              ),
            );

        Widget empty(IconData icon, String label) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 56, color: scheme.primary.withValues(alpha: 0.4)),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            );

        if (imageUrl == null || imageUrl.isEmpty) {
          return shell(
            child: empty(Icons.image_not_supported_rounded, 'No image'),
          );
        }

        return shell(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 220),
            placeholder: (context, url) => Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: scheme.primary.withValues(alpha: 0.6),
                ),
              ),
            ),
            errorWidget: (context, url, error) {
              if (kDebugMode) {
                print('Product image load error: $error');
              }
              return empty(Icons.broken_image_rounded, 'Image unavailable');
            },
          ),
        );
      },
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Information',
          style: AppTextStyles.headingMedium(Get.context!),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Barcode', product.barcode ?? 'N/A'),
        _buildInfoRow('Brand', product.brands ?? 'Unknown'),
        _buildInfoRow('Categories', product.categories ?? 'N/A'),
        _buildInfoRow('Quantity', product.quantity ?? 'N/A'),
        _buildInfoRow('Serving Size', product.servingSize ?? 'N/A'),
      ],
    );
  }

  Widget _buildIngredients() {
    if (product.ingredientsText?.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ingredients', style: AppTextStyles.headingMedium(Get.context!)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            product.ingredientsText!,
            style: AppTextStyles.bodyMedium(Get.context!),
          ),
        ),
      ],
    );
  }

  Widget _buildScores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Scores',
          style: AppTextStyles.headingMedium(Get.context!),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (product.nutriscore != null)
              Expanded(
                child: _buildScoreCard(
                  'Nutri-Score',
                  product.nutriscore!.toUpperCase(),
                  _getNutriScoreColor(product.nutriscore!),
                ),
              ),
            if (product.nutriscore != null && product.novaGroup != null)
              const SizedBox(width: 12),
            if (product.novaGroup != null)
              Expanded(
                child: _buildScoreCard(
                  'NOVA Group',
                  product.novaGroup.toString(),
                  _getNovaGroupColor(product.novaGroup!),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTextStyles.bodyMedium(
                Get.context!,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium(Get.context!)),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(
    String label,
    String value,
    Color color, {
    bool isHighlight = false,
    bool isIndented = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isHighlight ? 12 : 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: isHighlight ? 24 : 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: isHighlight
                  ? AppTextStyles.bodyLarge(
                      Get.context!,
                    ).copyWith(fontWeight: FontWeight.w600)
                  : AppTextStyles.bodyMedium(Get.context!),
            ),
          ),
          Text(
            value,
            style:
                (isHighlight
                        ? AppTextStyles.bodyLarge(Get.context!)
                        : AppTextStyles.bodyMedium(Get.context!))
                    .copyWith(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String title, String score, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: AppTextStyles.labelMedium(Get.context!),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              score,
              style: AppTextStyles.labelLarge(
                Get.context!,
              ).copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Color _getNutriScoreColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'a':
        return AppColors.nutriA;
      case 'b':
        return AppColors.nutriB;
      case 'c':
        return AppColors.nutriC;
      case 'd':
        return AppColors.nutriD;
      case 'e':
        return AppColors.nutriE;
      default:
        return AppColors.textTertiary;
    }
  }

  Color _getNovaGroupColor(int group) {
    switch (group) {
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.warning;
      case 3:
        return Colors.orange;
      case 4:
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }

  void _addToFavorites(
    Map<String, dynamic> meal,
    int index,
    String viewMode,
    NutritionController controller,
  ) {
    controller.toggleFavorite(meal);
  }

  void _shareProduct() {
    SharePlus.instance.share(
      ShareParams(
        text:
            'Check out this product: ${product.productName ?? 'Unknown Product'}\nhttps://world.openfoodfacts.org/product/${product.barcode}',
      ),
    );
  }
}
