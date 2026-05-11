import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nutri_check/core/config/env_config.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../controllers/nutrition_controller.dart';

class AIMealAnalysisPage extends StatefulWidget {
  const AIMealAnalysisPage({super.key});

  @override
  State<AIMealAnalysisPage> createState() => _AIMealAnalysisPageState();
}

class _AIMealAnalysisPageState extends State<AIMealAnalysisPage>
    with TickerProviderStateMixin {
  File? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  static String get _geminiApiKey => EnvConfig.geminiApiKey;
  GenerativeModel? _model;
  bool get _apiKeyMissing => _geminiApiKey.isEmpty;

  @override
  void initState() {
    super.initState();
    if (!_apiKeyMissing) {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _geminiApiKey,
      );
    }

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_apiKeyMissing) {
      return _buildApiKeyMissingScreen(context);
    }
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.background,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        _buildImageSection(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                        const SizedBox(height: 24),
                        if (_isAnalyzing) _buildAnalyzingWidget(),
                        if (_analysisResult != null)
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: _buildAnalysisResults(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Meal Analysis',
                  style: AppTextStyles.headingMedium(
                    context,
                  ).copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  'NutriCore',
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.surface.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _selectedImage != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImage = null;
                        _analysisResult = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.1),
                        AppColors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.restaurant,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Capture Your Meal',
                  style: AppTextStyles.headingSmall(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Take a photo and let AI analyze the nutritional content instantly',
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.camera_alt,
            label: 'Camera',
            gradient: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.8),
            ],
            onPressed: () => _pickImage(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            icon: Icons.photo_library,
            label: 'Gallery',
            gradient: [
              AppColors.secondary,
              AppColors.secondary.withValues(alpha: 0.8),
            ],
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.3),
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
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'AI is analyzing your meal...',
            style: AppTextStyles.headingSmall(
              context,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Identifying ingredients and calculating nutrition',
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.05),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultsHeader(),
          const SizedBox(height: 20),
          _buildMealInfo(),
          const SizedBox(height: 20),
          _buildNutritionGrid(),
          if (_analysisResult!['ingredients'] != null) ...[
            const SizedBox(height: 20),
            _buildIngredientsSection(),
          ],
          const SizedBox(height: 24),
          _buildAddToLogButton(),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.success,
                AppColors.success.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.psychology, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analysis Complete!',
                style: AppTextStyles.headingSmall(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              Text(
                'AI detected nutritional information',
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.restaurant_menu, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _analysisResult!['meal_name'] ?? 'Detected Meal',
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                if (_analysisResult!['portion_size'] != null)
                  Text(
                    'Portion: ${_analysisResult!['portion_size']}',
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionGrid() {
    final nutritionItems = [
      {
        'icon': '🔥',
        'label': 'Calories',
        'value': '${_analysisResult!['calories'] ?? 0}',
        'unit': 'kcal',
        'color': AppColors.warning,
      },
      {
        'icon': '💪',
        'label': 'Protein',
        'value': '${_analysisResult!['protein'] ?? 0}',
        'unit': 'g',
        'color': AppColors.primary,
      },
      {
        'icon': '🌾',
        'label': 'Carbs',
        'value': '${_analysisResult!['carbs'] ?? 0}',
        'unit': 'g',
        'color': AppColors.info,
      },
      {
        'icon': '🥑',
        'label': 'Fat',
        'value': '${_analysisResult!['fat'] ?? 0}',
        'unit': 'g',
        'color': AppColors.secondary,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: nutritionItems.length,
      itemBuilder: (context, index) {
        final item = nutritionItems[index];
        return _buildNutritionCard(
          item['icon'] as String,
          item['label'] as String,
          item['value'] as String,
          item['unit'] as String,
          item['color'] as Color,
        );
      },
    );
  }

  Widget _buildNutritionCard(
    String icon,
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelMedium(
                  context,
                ).copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.headingSmall(
                  context,
                ).copyWith(fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: AppTextStyles.labelSmall(
                  context,
                ).copyWith(color: color.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'Detected Ingredients',
                style: AppTextStyles.bodyLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w600, color: AppColors.info),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _analysisResult!['ingredients'].toString(),
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textPrimary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToLogButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success, AppColors.success.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addToNutritionLog,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Add to Nutrition Log',
                  style: AppTextStyles.bodyLarge(
                    context,
                  ).copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _analysisResult = null;
        });

        // Auto-analyze after picking image
        _analyzeImage();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _addToNutritionLog() {
    if (_analysisResult == null) return;

    try {
      final nutritionController = Get.find<NutritionController>();

      final meal = {
        'name': _analysisResult!['meal_name'] ?? 'AI Analyzed Meal',
        'calories': (_analysisResult!['calories'] ?? 0).round(),
        'proteins': (_analysisResult!['protein'] ?? 0.0).toDouble(),
        'carbs': (_analysisResult!['carbs'] ?? 0.0).toDouble(),
        'fat': (_analysisResult!['fat'] ?? 0.0).toDouble(),
        'fiber': (_analysisResult!['fiber'] ?? 0.0).toDouble(),
        'sugar': (_analysisResult!['sugar'] ?? 0.0).toDouble(),
        'sodium': (_analysisResult!['sodium'] ?? 0.0).toDouble(),
        'type': 'meal',
        'time':
            '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'quantity': 100.0,
        'notes': 'AI analyzed meal: ${_analysisResult!['ingredients'] ?? ''}',
        'favorite': false,
        'source': 'ai_analysis',
      };

      nutritionController.addMeal(meal);

      Get.snackbar(
        '🍽️ Added to Log!',
        '${meal['name']} added to your nutrition log',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add meal to log: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final imageBytes = await _selectedImage!.readAsBytes();

      final prompt = '''
Analyze this meal image and provide detailed nutritional information. 
Return the response as a JSON object with the following structure:
{
  "meal_name": "Name of the dish/meal",
  "calories": 0,
  "protein": 0,
  "carbs": 0,
  "fat": 0,
  "fiber": 0,
  "sugar": 0,
  "sodium": 0,
  "ingredients": "List of main ingredients detected",
  "portion_size": "Estimated portion size",
  "health_notes": "Brief health assessment or tips"
}

Please provide realistic estimates based on typical serving sizes. 
All nutritional values should be numbers (integers for calories, decimals for others).
''';

      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      final model = _model;
      if (model == null) {
        throw Exception('AI features are not configured.');
      }
      final response = await model.generateContent(content);
      final responseText = response.text;

      if (responseText != null) {
        String jsonString = responseText.trim();

        const String jsonMarker = '```.json';
        const String codeMarker = '```';

        if (jsonString.contains(jsonMarker)) {
          final startIndex = jsonString.indexOf(jsonMarker) + jsonMarker.length;
          final endIndex = jsonString.lastIndexOf(codeMarker);
          if (startIndex < endIndex) {
            jsonString = jsonString.substring(startIndex, endIndex).trim();
          }
        } else if (jsonString.contains(codeMarker)) {
          final startIndex = jsonString.indexOf(codeMarker) + codeMarker.length;
          final endIndex = jsonString.lastIndexOf(codeMarker);
          if (startIndex < endIndex) {
            jsonString = jsonString.substring(startIndex, endIndex).trim();
          }
        }

        if (!jsonString.startsWith('{')) {
          final jsonStart = jsonString.indexOf('{');
          final jsonEnd = jsonString.lastIndexOf('}');
          if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
            jsonString = jsonString.substring(jsonStart, jsonEnd + 1);
          }
        }

        if (kDebugMode) {
          print('🔍 Extracted JSON: $jsonString');
        }

        try {
          final analysisData = jsonDecode(jsonString);
          setState(() {
            _analysisResult = analysisData;
          });
          _animationController.reset();
          _animationController.forward();

          Get.snackbar(
            '🎉 Analysis Complete!',
            'Your meal has been analyzed successfully',
            backgroundColor: AppColors.success,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );

          if (kDebugMode) {
            print(
              'Successfully parsed AI response: ${analysisData['meal_name']}',
            );
          }
        } catch (jsonError) {
          if (kDebugMode) {
            print('JSON Parse Error: $jsonError');
          }
          if (kDebugMode) {
            print('Attempted to parse: $jsonString');
          }
          _parseResponseManually(responseText);
        }
      } else {
        throw Exception('No response from AI');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analysis Error: $e');
      }
      CustomThemeFlushbar.show(
        title: 'Analysis Failed',
        message: 'Could not analyze the image. Please try again.',
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _parseResponseManually(String responseText) {
    try {
      final caloriesMatch = RegExp(
        r'"calories":\s*(\d+)',
      ).firstMatch(responseText);
      final proteinMatch = RegExp(
        r'"protein":\s*([\d.]+)',
      ).firstMatch(responseText);
      final carbsMatch = RegExp(
        r'"carbs":\s*([\d.]+)',
      ).firstMatch(responseText);
      final fatMatch = RegExp(r'"fat":\s*([\d.]+)').firstMatch(responseText);
      final fiberMatch = RegExp(
        r'"fiber":\s*([\d.]+)',
      ).firstMatch(responseText);
      final sugarMatch = RegExp(
        r'"sugar":\s*([\d.]+)',
      ).firstMatch(responseText);
      final sodiumMatch = RegExp(
        r'"sodium":\s*([\d.]+)',
      ).firstMatch(responseText);
      final mealNameMatch = RegExp(
        r'"meal_name":\s*"([^"]+)"',
      ).firstMatch(responseText);
      final ingredientsMatch = RegExp(
        r'"ingredients":\s*"([^"]+)"',
      ).firstMatch(responseText);

      final manualResult = {
        'meal_name': mealNameMatch?.group(1) ?? 'AI Analyzed Meal',
        'calories': int.tryParse(caloriesMatch?.group(1) ?? '0') ?? 0,
        'protein': double.tryParse(proteinMatch?.group(1) ?? '0') ?? 0.0,
        'carbs': double.tryParse(carbsMatch?.group(1) ?? '0') ?? 0.0,
        'fat': double.tryParse(fatMatch?.group(1) ?? '0') ?? 0.0,
        'fiber': double.tryParse(fiberMatch?.group(1) ?? '0') ?? 0.0,
        'sugar': double.tryParse(sugarMatch?.group(1) ?? '0') ?? 0.0,
        'sodium': double.tryParse(sodiumMatch?.group(1) ?? '0') ?? 0.0,
        'ingredients': ingredientsMatch?.group(1) ?? 'Various ingredients',
      };

      setState(() {
        _analysisResult = manualResult;
      });

      Get.snackbar(
        'Analysis Complete!',
        'Your meal has been analyzed successfully',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      if (kDebugMode) {
        print('Manual parsing successful: ${manualResult['meal_name']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Manual parsing also failed: $e');
      }
      CustomThemeFlushbar.show(
        title: 'Analysis Failed',
        message: 'Could not parse the AI response. Please try again.',
      );
    }
  }

  Widget _buildApiKeyMissingScreen(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  size: 34,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'AI Meal Analysis is not configured',
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'A Gemini API key is required to analyse meals from a photo. Add GEMINI_API_KEY to your build configuration to enable this feature.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Get.back(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
