import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../controllers/nutrition_controller.dart';

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
            AppColors.calories.withOpacity(0.1),
            AppColors.calories.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.calories.withOpacity(0.3)),
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
            border: Border.all(color: AppColors.textTertiary.withOpacity(0.2)),
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
            color: color.withOpacity(0.1),
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
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showAddToMealDialog(), // 🔥 Updated to show quantity dialog
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
              ),
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

  void _showAddToMealDialog() {
    final quantityController = TextEditingController(text: '100');
    final notesController = TextEditingController();
    String selectedMealType = 'meal';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add to Nutrition Log'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product info
                Text(
                  product.productName ?? 'Unknown Product',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (product.brands?.isNotEmpty == true) ...[
                  SizedBox(height: 4),
                  Text(
                    product.brands!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                SizedBox(height: 16),

                // Nutrition info per 100g
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.calories.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.calories.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Nutrition per 100g:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNutrientChip(
                            '${_getCalories()} kcal',
                            Icons.local_fire_department,
                            AppColors.calories,
                          ),
                          _buildNutrientChip(
                            '${_getProteins()}g P',
                            Icons.fitness_center,
                            AppColors.proteins,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNutrientChip(
                            '${_getCarbs()}g C',
                            Icons.grain,
                            AppColors.carbs,
                          ),
                          _buildNutrientChip(
                            '${_getFats()}g F',
                            Icons.opacity,
                            AppColors.fats,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Quantity input
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity (grams)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixText: 'g',
                    helperText: 'Enter the amount you consumed',
                    prefixIcon: Icon(Icons.scale, color: AppColors.primary),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12),

                // Meal type selection
                DropdownButtonFormField<String>(
                  value: selectedMealType,
                  decoration: InputDecoration(
                    labelText: 'Meal Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(
                      Icons.restaurant,
                      color: AppColors.primary,
                    ),
                  ),
                  items: ['breakfast', 'lunch', 'dinner', 'snack', 'meal']
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.capitalize!),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => selectedMealType = value ?? 'meal',
                ),
                SizedBox(height: 12),

                // Notes
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'e.g., Brand, preparation method, etc.',
                    prefixIcon: Icon(Icons.note, color: AppColors.primary),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final quantity = double.tryParse(quantityController.text) ?? 100;
              if (quantity <= 0) {
                Get.snackbar(
                  'Invalid Quantity',
                  'Please enter a valid quantity',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
                return;
              }

              _addProductToNutritionLog(
                quantity,
                selectedMealType,
                notesController.text,
              );
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Add to Log'),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientChip(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 NEW: Add product to nutrition log with Firebase integration
  Future<void> _addProductToNutritionLog(
    double quantity,
    String mealType,
    String notes,
  ) async {
    try {
      final nutritionController = Get.find<NutritionController>();

      // Calculate nutrition values for the specified quantity
      final factor = quantity / 100; // Convert from per-100g to actual quantity

      final calories = _getCalories();
      final proteins = _getProteins();
      final carbs = _getCarbs();
      final fats = _getFats();
      final fiber = _getFiber();
      final sugars = _getSugars();
      final sodium = _getSodium();

      final meal = {
        'name': product.productName ?? 'Scanned Product',
        'calories': (calories * factor).round(),
        'proteins': (proteins * factor),
        'carbs': (carbs * factor),
        'fat': (fats * factor),
        'fiber': (fiber * factor),
        'sugar': (sugars * factor),
        'sodium': (sodium * factor),
        'type': mealType,
        'time':
            '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'quantity': quantity,
        'barcode': product.barcode,
        'brands': product.brands,
        'imageUrl': product.imageFrontUrl,
        'notes': notes.trim().isEmpty
            ? 'Added from product scanner (${product.barcode})'
            : notes.trim(),
        'favorite': false,
      };

      // 🔥 Add to nutrition log - this will automatically sync to Firebase
      await nutritionController.addMeal(meal);

      // Close the product details sheet
      Navigator.pop(Get.context!);

      // Show success message
      Get.snackbar(
        '🍽️ Added to Nutrition Log!',
        '${product.productName} (${quantity}g) added successfully\n${meal['calories']} kcal added to your daily intake',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );

      print(
        '✅ Product added to nutrition log: ${meal['name']} - ${meal['calories']} kcal',
      );
    } catch (e) {
      print('❌ Error adding to nutrition log: $e');
      Get.snackbar(
        '❌ Error',
        'Failed to add product to nutrition log: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
    }
  }

  // Helper methods to get nutrition values
  int _getCalories() {
    try {
      return product.nutriments
              ?.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams)
              ?.toInt() ??
          0;
    } catch (e) {
      return 0;
    }
  }

  double _getProteins() {
    try {
      return product.nutriments?.getValue(
            Nutrient.proteins,
            PerSize.oneHundredGrams,
          ) ??
          0.0;
    } catch (e) {
      return 0.0;
    }
  }

  double _getCarbs() {
    try {
      return product.nutriments?.getValue(
            Nutrient.carbohydrates,
            PerSize.oneHundredGrams,
          ) ??
          0.0;
    } catch (e) {
      return 0.0;
    }
  }

  double _getFats() {
    try {
      return product.nutriments?.getValue(
            Nutrient.fat,
            PerSize.oneHundredGrams,
          ) ??
          0.0;
    } catch (e) {
      return 0.0;
    }
  }

  double _getFiber() {
    try {
      return product.nutriments?.getValue(
            Nutrient.fiber,
            PerSize.oneHundredGrams,
          ) ??
          0.0;
    } catch (e) {
      return 0.0;
    }
  }

  double _getSugars() {
    try {
      return product.nutriments?.getValue(
            Nutrient.sugars,
            PerSize.oneHundredGrams,
          ) ??
          0.0;
    } catch (e) {
      return 0.0;
    }
  }

  double _getSodium() {
    try {
      return product.nutriments?.getValue(
            Nutrient.sodium,
            PerSize.oneHundredGrams,
          ) ??
          0.0;
    } catch (e) {
      return 0.0;
    }
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

  // In your ProductDetailsSheet, replace the _buildProductImage method:
  Widget _buildProductImage() {
    final imageUrl =
        product.imagePackagingUrl ??
        product.imagePackagingSmallUrl ??
        product.imageFrontSmallUrl;

    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 64,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 8),
              Text(
                'No Image Available',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200,
          color: AppColors.surfaceVariant,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                const Text('Loading image...'),
              ],
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          print('❌ Product image load error: $error');
          return Container(
            height: 200,
            color: AppColors.surfaceVariant,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 64, color: AppColors.error),
                  const SizedBox(height: 8),
                  const Text('Failed to load image'),
                ],
              ),
            ),
          );
        },
      ),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
    (context) => controller.toggleFavorite(meal);
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
